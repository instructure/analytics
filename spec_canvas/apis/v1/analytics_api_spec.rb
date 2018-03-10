#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# This file is part of the analytics engine

require_relative '../../../../../../spec/apis/api_spec_helper'
require_relative '../../spec_helper'
require_relative '../../cassandra_spec_helper'

describe "Analytics API", :type => :request do

  before :each do
    @account = Account.default
    @account.allowed_services = '+analytics'
    @account.save!

    # give all teachers in the account canvalytics permissions for now
    RoleOverride.manage_role_override(@account, teacher_role, 'view_analytics', :override => true)
  end

  def analytics_api_call(action, course, student, opts={})
    action, suffix =
      case action
      when :participation then ['student_in_course_participation', "/activity"]
      when :assignments then ['student_in_course_assignments', "/assignments"]
      when :messaging then ['student_in_course_messaging', "/communication"]
      end
    user = opts.delete(:user)
    args = [:get,
      "/api/v1/courses/#{course.id}/analytics/users/#{student.id}" + suffix,
      { :controller => 'analytics_api',
        :action => action,
        :format => 'json',
        :course_id => course.id.to_s,
        :student_id => student.id.to_s },
      {}, {}, opts]

    if user then
      api_call_as_user(user, *args)
    else
      api_call(*args)
    end
  end

  context "permissions" do
    before :each do
      @student1 = user_factory(active_all: true)
      course_with_teacher(:active_all => true)
      @default_section = @course.default_section
      @section = factory_with_protected_attributes(@course.course_sections, :sis_source_id => 'my-section-sis-id', :name => 'section2')
      @course.enroll_user(@student1, 'StudentEnrollment', :section => @section).accept!
    end

    # each of these is nominal aside from the condition in the description
    it "should 200 under nominal conditions" do
      analytics_api_call(:participation, @course, @student1, :expected_status => 200)
      analytics_api_call(:assignments, @course, @student1, :expected_status => 200)
      analytics_api_call(:messaging, @course, @student1, :expected_status => 200)
    end

    it "should 404 with analytics disabled" do
      @account.allowed_services = '-analytics'
      @account.save!

      analytics_api_call(:participation, @course, @student1, :expected_status => 404)
      analytics_api_call(:assignments, @course, @student1, :expected_status => 404)
      analytics_api_call(:messaging, @course, @student1, :expected_status => 404)
    end

    it "should 401 with unreadable course" do
      @course1 = @course
      course_with_teacher(:active_all => true)

      analytics_api_call(:participation, @course1, @student1, :expected_status => 401)
      analytics_api_call(:assignments, @course1, @student1, :expected_status => 401)
      analytics_api_call(:messaging, @course1, @student1, :expected_status => 401)
    end

    it "should 401 with out analytics permission" do
      RoleOverride.manage_role_override(@account, teacher_role, 'view_analytics', :override => false)

      analytics_api_call(:participation, @course, @student1, :expected_status => 401)
      analytics_api_call(:assignments, @course, @student1, :expected_status => 401)
      analytics_api_call(:messaging, @course, @student1, :expected_status => 401)
    end

    it "should 404 with unreadable student" do
      # section limited ta in section other than student1
      @ta = user_factory(active_all: true)
      @enrollment = @course.enroll_ta(@ta)
      @enrollment.course = @course # set the reverse association
      @enrollment.workflow_state = 'active'
      @enrollment.limit_privileges_to_course_section = true
      @enrollment.course_section = @default_section
      @enrollment.save!

      RoleOverride.manage_role_override(@account, ta_role, 'view_analytics', :override => true)

      analytics_api_call(:participation, @course, @student1, :expected_status => 404)
      analytics_api_call(:assignments, @course, @student1, :expected_status => 404)
      analytics_api_call(:messaging, @course, @student1, :expected_status => 404)
    end
  end

  context "course and quiz with a submitted score" do
    # shim for quiz namespacing
    def quiz_klass
      @quiz_klass ||= begin
                        "Quiz".constantize
                      rescue NameError
                        "Quizzes::Quiz".constantize
                      end
    end

    before do
      @student1 = user_factory(active_all: true)
      course_with_teacher(:active_all => true)
      @default_section = @course.default_section
      @section = factory_with_protected_attributes(@course.course_sections, :sis_source_id => 'my-section-sis-id', :name => 'section2')
      @course.enroll_user(@student1, 'StudentEnrollment', :section => @section).accept!

      quiz = quiz_klass.create!(:title => 'quiz1', :context => @course, :points_possible => 10)
      quiz.did_edit!
      quiz.offer!
      @a1 = quiz.assignment
      sub = @a1.find_or_create_submission(@student1)
      sub.submission_type = 'online_quiz'
      sub.workflow_state = 'submitted'
      sub.score = 9
      sub.save!
      @submitted_at = sub.submitted_at
    end

    it "should include student data" do
      json = analytics_api_call(:assignments, @course, @student1)
      expect(json).to eq [{
        "title" => @a1.title,
        "assignment_id" => @a1.id,
        "max_score" => 9,
        "first_quartile" => 9,
        "median" => 9,
        "third_quartile" => 9,
        "module_ids" => [],
        "unlock_at" => nil,
        "min_score" => 9,
        "due_at" => nil,
        "points_possible" => 0,
        "muted" => false,
        "status" => "on_time",
        "multiple_due_dates" => false,
        "non_digital_submission" => false,
        "excused" => false,
        "submission" => {
          "submitted_at" => @submitted_at.iso8601,
          "score" => 9
        }
      }]
    end

    it "should mark excused assignments" do
      @a1.grade_student(@student1, excuse: true, grader: @teacher)
      json = analytics_api_call(:assignments, @course, @student1)
      expect(json.first["excused"]).to be_truthy
    end
  end

  context "course with multiple assignments and multiple students with scores" do
    before do
      num_students = 5
      num_assignments = 5

      @students = []
      @assignments = []
      @outcomes = []

      num_students.times {|u| @students << user_factory(active_all: true)}

      course_with_teacher(:active_all => true)
      @default_section = @course.default_section
      @section = factory_with_protected_attributes(@course.course_sections, :sis_source_id => 'my-section-sis-id', :name => 'section2')

      @students.each {|s| @course.enroll_user(s, 'StudentEnrollment', :section => @section).accept!}

      @due_time ||= Time.now.utc

      num_assignments.times{|i| @assignments << Assignment.create!(
          :title => "assignment #{i + 1}",
          :context => @course,
          :points_possible => 10 * (i+1),
          :due_at => @due_time)}

      @module = ContextModule.create!(name: "unnamed module", context: @course)
      content_tag_params = {
          content_type: 'Assignment',
          context: @course,
          content: @assignments[0],
          tag_type: 'context_module'
      }
      @module.content_tags.create!(content_tag_params)

      for s_index in 0..(num_students - 1)
        student = @students[s_index]
        for a_index in 0..(num_assignments - 1)
          assignment = @assignments[a_index]
          @outcomes[a_index] = @course.created_learning_outcomes.create!(:short_description => 'outcome')
          @tag = @outcomes[a_index].align(assignment, @course, :mastery_type => "points")
          assignment.reload
          grade = (10 * (a_index + 1)) - s_index * (a_index+1)
          sub = assignment.grade_student(student, grade: grade, grader: @teacher).first
          sub.submission_type = 'online_text_entry'
          if a_index > 0
            sub.submitted_at = @due_time - 3.hours + s_index.hours
          end
          if a_index < 4
            sub.graded_at = @due_time + 6.days - a_index.days
          end
          sub.save!
        end
      end
    end

    def response_assignment(json, assignment)
      json_assignment = json.detect{ |a| a["assignment_id"] == assignment.id }
      expect(json_assignment).not_to be_nil
      json_assignment
    end

    it "should not have statistics available for assignments with only a few submissions" do
      # Remove one of the 5 submissions, so we can test that min, max, quartile stats
      # are not present (fewer than 5 submissions will suppress stats data, see
      # suppressed_due_to_few_submissions)
      # TODO: the submissions are not returning in a consistent order causing a false negative when the
      # destroyed submission is later referenced. Rejecting the referenced students submission will prevent
      # the false negative, but a more robust solution should eventually be developed.
      @assignments[2].submissions.reject { |s| s.user == @students[1] }[0].destroy
      # Allow user to see analytics page
      RoleOverride.manage_role_override(@account, student_role, 'view_analytics', :override => true)
      # Log in as the user for this API call
      json = analytics_api_call(:assignments, @course, @students[1], :user => @students[1])
      expect(response_assignment(json, @assignments[2])["submission"]["score"]).to eq 27
      expect(response_assignment(json, @assignments[2])["max_score"]).to be_nil
    end

    it "should not have statistics available if the teacher has blocked it in course settings" do
      # Disallow in course settings
      @course.settings = { :hide_distribution_graphs => true }
      @course.save!
      # Allow user to see analytics page
      RoleOverride.manage_role_override(@account, student_role, 'view_analytics', :override => true)
      # Log in as the user for this API call
      json = analytics_api_call(:assignments, @course, @students[1], :user => @students[1])
      expect(response_assignment(json, @assignments[2])["submission"]["score"]).to eq 27
      expect(response_assignment(json, @assignments[2])["max_score"]).to be_nil
    end

    it "should calculate max score" do
      json = analytics_api_call(:assignments, @course, @students[1])
      expect(response_assignment(json, @assignments[3])["max_score"]).to eq 40
    end

    it "should calculate min score" do
      json = analytics_api_call(:assignments, @course, @students[1])
      expect(response_assignment(json, @assignments[4])["min_score"]).to eq 30
    end

    it "should calculate first quartile of scores" do
      json = analytics_api_call(:assignments, @course, @students[1])
      expect(response_assignment(json, @assignments[0])["first_quartile"]).to eq 6.5
    end

    it "should calculate median of scores" do
      json = analytics_api_call(:assignments, @course, @students[1])
      expect(response_assignment(json, @assignments[0])["median"]).to eq 8
    end

    it "should calculate third quartile of scores" do
      json = analytics_api_call(:assignments, @course, @students[1])
      expect(response_assignment(json, @assignments[0])["third_quartile"]).to eq 9.5
    end

    it "should have the student score" do
      json = analytics_api_call(:assignments, @course, @students[1])
      expect(response_assignment(json, @assignments[2])["submission"]["score"]).to eq 27
    end

    it "should have the student submit time" do
      json = analytics_api_call(:assignments, @course, @students[1])
      expect(response_assignment(json, @assignments[4])["submission"]["submitted_at"]).to eq (@due_time - 2.hours).iso8601
    end

    it "should track due dates" do
      json = analytics_api_call(:assignments, @course, @students[1])
      expect(response_assignment(json, @assignments[3])["due_at"]).to eq @due_time.change(sec: 0).iso8601
    end

    it "should have the module ids the assignment belongs to" do
      json = analytics_api_call(:assignments, @course, @students[1])
      expect(response_assignment(json, @assignments[0])["module_ids"]).to eq [@module.id]
    end
  end

  context "course_student_summaries" do
    it "should fetch data for a student in the course" do
      # course with teacher and some students
      course_with_teacher(:active_all => true)
      3.times{ |u| student_in_course(:active_all => true) }
      @user = @teacher

      # don't let the teacher see grades
      RoleOverride.manage_role_override(Account.default, teacher_role, 'manage_grades', :override => false)
      RoleOverride.manage_role_override(Account.default, teacher_role, 'view_all_grades', :override => false)

      # should fail
      raw_api_call(:get, "/api/v1/courses/#{@course.id}/analytics/student_summaries",
        :controller => 'analytics_api', :action => 'course_student_summaries', :format => 'json',
        :course_id => @course.id.to_s)
      expect(response.status.to_i).to eq 401 # Unauthorized
    end
  end

  context "#course_assignments" do
    before do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @user = @teacher
    end

    let(:url) { "/api/v1/courses/#{@course.id}/analytics/assignments" }
    let(:course_assignments_route) do
      {
        :controller => 'analytics_api',
        :action => 'course_assignments',
        :format => 'json',
        :course_id => @course.id.to_s
      }
    end

    it "should return assignments" do
      Assignment.create!(
          :title => "assignment",
          :context => @course,
          :points_possible => 10,
          :due_at => Time.now + 2.days)

      json = api_call(:get, url, course_assignments_route)
      expect(response.status.to_i).to eq 200
      expect(json.size).to eq 1
      expect(json.first.keys).to include('assignment_id')
    end

    context "with async" do
      it "should return progress" do
        enable_cache do
          json = api_call(:get, url, course_assignments_route, :async => 1.to_s)
          expect(response.status.to_i).to eq 200
          expect(json.keys).to include('progress_url')
          expect(json['progress_url']).to match(%r{http://www.example.com/api/v1/progress/\d+})
        end
      end

      it "should return the same progress object if called consecutively" do
        enable_cache do
          json1 = api_call(:get, url, course_assignments_route, :async => 1.to_s)
          json2 = api_call(:get, url, course_assignments_route, :async => 1.to_s)
          expect(json1).to eq json2
        end
      end
    end
  end

  context "#student_in_course_participation" do
    before :each do
      course_with_teacher(active_all: true)
      course_with_student(course: @course, active_all: true)
    end
s
    it "should return submission data when graded but not submitted" do
      assignment = assignment_model course: @course
      assignment.grade_student(@student, grade: 1, grader: @teacher)

      json = analytics_api_call(:assignments, @course, @student, user: @teacher)
      expect(json.first['submission']['score']).to eq 1
    end

    context "cassandra" do
      include_examples "analytics cassandra page views"
      it "should have iso8601 page_views keys" do
        pv = page_view(:user => @student, :course => @course)

        bucket = Analytics::PageViewIndex::EventStream.bucket_for_time(pv.created_at)
        expected = Time.zone.at(bucket).iso8601
        json = analytics_api_call(:participation, @course, @student, :user => @teacher)
        expect(json['page_views'].keys).to eq [expected]
      end
    end

    context "non-cassandra" do
      it "should have date string page_views keys" do
        pv = page_view(:user => @student, :course => @course)
        pv.save!
        expected = pv.created_at.to_date.strftime('%Y-%m-%d')
        json = analytics_api_call(:participation, @course, @student, :user => @teacher)
        expect(json['page_views'].keys).to eq [expected]
      end
    end
  end
end
