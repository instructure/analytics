#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of the analytics engine

require File.expand_path(File.dirname(__FILE__) + '/../../../../../../spec/apis/api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

describe "Analytics API", :type => :integration do

  before :each do
    @account = Account.default
    @account.allowed_services = '+analytics'
    @account.save!

    # give all teachers in the account canvalytics permissions for now
    RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'view_analytics', :override => true)
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
      @student1 = user(:active_all => true)
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
      RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'view_analytics', :override => false)

      analytics_api_call(:participation, @course, @student1, :expected_status => 401)
      analytics_api_call(:assignments, @course, @student1, :expected_status => 401)
      analytics_api_call(:messaging, @course, @student1, :expected_status => 401)
    end

    it "should 404 with unreadable student" do
      # section limited ta in section other than student1
      @ta = user(:active_all => true)
      @enrollment = @course.enroll_ta(@ta)
      @enrollment.course = @course # set the reverse association
      @enrollment.workflow_state = 'active'
      @enrollment.limit_privileges_to_course_section = true
      @enrollment.course_section = @default_section
      @enrollment.save!

      RoleOverride.manage_role_override(@account, 'TaEnrollment', 'view_analytics', :override => true)

      analytics_api_call(:participation, @course, @student1, :expected_status => 404)
      analytics_api_call(:assignments, @course, @student1, :expected_status => 404)
      analytics_api_call(:messaging, @course, @student1, :expected_status => 404)
    end
  end

  context "course and quiz with a submitted score" do
    before do
      @student1 = user(:active_all => true)
      course_with_teacher(:active_all => true)
      @default_section = @course.default_section
      @section = factory_with_protected_attributes(@course.course_sections, :sis_source_id => 'my-section-sis-id', :name => 'section2')
      @course.enroll_user(@student1, 'StudentEnrollment', :section => @section).accept!

      quiz = Quiz.create!(:title => 'quiz1', :context => @course, :points_possible => 10)
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
      json.should == [{
        "title" => @a1.title,
        "assignment_id" => @a1.id,
        "max_score" => 9,
        "first_quartile" => 9,
        "median" => 9,
        "third_quartile" => 9,
        "unlock_at" => nil,
        "min_score" => 9,
        "due_at" => nil,
        "points_possible" => 0,
        "muted" => false,
        "multiple_due_dates" => false,
        "submission" => {
          "submitted_at" => @submitted_at.iso8601,
          "score" => 9
        }
      }]
    end
  end

  context "course with multiple assignments and multiple students with scores" do
    before do
      num_students = 5
      num_assignments = 5

      @students = []
      @assignments = []
      @outcomes = []
      
      num_students.times {|u| @students << user(:active_all => true)}

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

      for s_index in 0..(num_students - 1)
        student = @students[s_index]
        for a_index in 0..(num_assignments - 1)
          assignment = @assignments[a_index]
          @outcomes[a_index] = @course.created_learning_outcomes.create!(:short_description => 'outcome')
          @tag = @outcomes[a_index].align(assignment, @course, :mastery_type => "points")
          assignment.reload
          grade = (10 * (a_index + 1)) - s_index * (a_index+1)
          sub = assignment.grade_student(student, :grade => grade).first
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
      json_assignment.should_not be_nil
      json_assignment
    end

    it "should not have statistics available for assignments with only a few submissions" do
      # Remove one of the 5 submissions, so we can test that min, max, quartile stats
      # are not present (fewer than 5 submissions will suppress stats data, see
      # suppressed_due_to_few_submissions)
      @assignments[2].submissions[0].destroy
      # Allow user to see analytics page
      RoleOverride.manage_role_override(@account, 'StudentEnrollment', 'view_analytics', :override => true)
      # Log in as the user for this API call
      json = analytics_api_call(:assignments, @course, @students[1], :user => @students[1])
      response_assignment(json, @assignments[2])["submission"]["score"].should == 27
      response_assignment(json, @assignments[2])["max_score"].should be_nil
    end

    it "should not have statistics available if the teacher has blocked it in course settings" do
      # Disallow in course settings
      @course.settings = { :hide_distribution_graphs => true }
      @course.save!
      # Allow user to see analytics page
      RoleOverride.manage_role_override(@account, 'StudentEnrollment', 'view_analytics', :override => true)
      # Log in as the user for this API call
      json = analytics_api_call(:assignments, @course, @students[1], :user => @students[1])
      response_assignment(json, @assignments[2])["submission"]["score"].should == 27
      response_assignment(json, @assignments[2])["max_score"].should be_nil
    end

    it "should fetch data for a student in the course" do
      json = analytics_api_call(:assignments, @course, @students[1])
    end

    it "should calculate max score" do
      json = analytics_api_call(:assignments, @course, @students[1])
      response_assignment(json, @assignments[3])["max_score"].should == 40
    end

    it "should calculate min score" do
      json = analytics_api_call(:assignments, @course, @students[1])
      response_assignment(json, @assignments[4])["min_score"].should == 30
    end

    it "should calculate first quartile of scores" do
      json = analytics_api_call(:assignments, @course, @students[1])
      response_assignment(json, @assignments[0])["first_quartile"].should == 6.5
    end

    it "should calculate median of scores" do
      json = analytics_api_call(:assignments, @course, @students[1])
      response_assignment(json, @assignments[0])["median"].should == 8
    end

    it "should calculate third quartile of scores" do
      json = analytics_api_call(:assignments, @course, @students[1])
      response_assignment(json, @assignments[0])["third_quartile"].should == 9.5
    end

    it "should have the student score" do
      json = analytics_api_call(:assignments, @course, @students[1])
      response_assignment(json, @assignments[2])["submission"]["score"].should == 27
    end

    it "should have the student submit time" do
      json = analytics_api_call(:assignments, @course, @students[1])
      response_assignment(json, @assignments[4])["submission"]["submitted_at"].should == (@due_time - 2.hours).iso8601
    end

    it "should track due dates" do
      json = analytics_api_call(:assignments, @course, @students[1])
      response_assignment(json, @assignments[3])["due_at"].should == @due_time.iso8601
    end
  end

  context "course_student_summaries" do
    it "should fetch data for a student in the course" do
      # course with teacher and some students
      course_with_teacher(:active_all => true)
      3.times{ |u| student_in_course(:active_all => true) }
      @user = @teacher

      # don't let the teacher see grades
      RoleOverride.manage_role_override(Account.default, 'TeacherEnrollment', 'manage_grades', :override => false)
      RoleOverride.manage_role_override(Account.default, 'TeacherEnrollment', 'view_all_grades', :override => false)

      # should fail
      raw_api_call(:get, "/api/v1/courses/#{@course.id}/analytics/student_summaries",
        :controller => 'analytics_api', :action => 'course_student_summaries', :format => 'json',
        :course_id => @course.id.to_s)
      response.status.to_i.should == 401 # Unauthorized
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
      response.status.to_i.should == 200
      json.size.should == 1
      json.first.keys.should include('assignment_id')
    end

    context "with async" do
      it "should return progress" do
        enable_cache do
          json = api_call(:get, url, course_assignments_route, :async => 1.to_s)
          response.status.to_i.should == 200
          json.keys.should include('progress_url')
          json['progress_url'].should match(%r{http://www.example.com/api/v1/progress/\d+})
        end
      end

      it "should return the same progress object if called consecutively" do
        enable_cache do
          json1 = api_call(:get, url, course_assignments_route, :async => 1.to_s)
          json2 = api_call(:get, url, course_assignments_route, :async => 1.to_s)
          json1.should == json2
        end
      end
    end
  end

  context "#student_in_course_participation" do
    before :each do
      course_with_student(:active_all => true)
    end

    it "should return submission data when graded but not submitted" do
      assignment = assignment_model course: @course
      assignment.grade_student(@student, grade: 1)

      json = analytics_api_call(:assignments, @course, @student, user: @teacher)
      json.first['submission']['score'].should == 1
    end

    context "cassandra" do
      it_should_behave_like "analytics cassandra page views"
      it "should have iso8601 page_views keys" do
        pv = page_view(:user => @student, :course => @course)

        bucket = Analytics::PageViewIndex::EventStream.bucket_for_time(pv.created_at)
        expected = Time.zone.at(bucket).iso8601
        json = analytics_api_call(:participation, @course, @student, :user => @teacher)
        json['page_views'].keys.should == [expected]
      end
    end

    context "non-cassandra" do
      it "should have date string page_views keys" do
        pv = page_view(:user => @student, :course => @course)
        pv.save!
        expected = pv.created_at.to_date.strftime('%Y-%m-%d')
        json = analytics_api_call(:participation, @course, @student, :user => @teacher)
        json['page_views'].keys.should == [expected]
      end
    end
  end
end
