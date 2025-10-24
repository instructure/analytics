# frozen_string_literal: true

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

require "apis/api_spec_helper"

describe "Analytics API", type: :request do
  before do
    @account = Account.default
    @account.allowed_services = "+analytics"
    @account.save!

    # give all teachers in the account canvalytics permissions for now
    RoleOverride.manage_role_override(@account, teacher_role, "view_analytics", override: true)
  end

  def analytics_api_call(action, course, student, opts = {})
    action, suffix = {
      participation: ["student_in_course_participation", "/activity"],
      assignments: ["student_in_course_assignments", "/assignments"],
      messaging: ["student_in_course_messaging", "/communication"]
    }[action]
    user = opts.delete(:user)
    args = [:get,
            "/api/v1/courses/#{course.id}/analytics/users/#{student.id}" + suffix,
            { controller: "analytics_api",
              action:,
              format: "json",
              course_id: course.id.to_s,
              student_id: student.id.to_s },
            {},
            {},
            opts]

    if user
      api_call_as_user(user, *args)
    else
      api_call(*args)
    end
  end

  context "permissions" do
    before do
      @student1 = user_factory(active_all: true)
      course_with_teacher(active_all: true)
      @default_section = @course.default_section
      @section = @course.course_sections.create!(sis_source_id: "my-section-sis-id",
                                                 name: "section2")
      @course.enroll_user(@student1, "StudentEnrollment", section: @section).accept!
    end

    # each of these is nominal aside from the condition in the description
    it "200s under nominal conditions" do
      analytics_api_call(:participation, @course, @student1, expected_status: 200)
      analytics_api_call(:assignments, @course, @student1, expected_status: 200)
      analytics_api_call(:messaging, @course, @student1, expected_status: 200)
    end

    it "404s with analytics disabled" do
      @account.allowed_services = "-analytics"
      @account.save!

      analytics_api_call(:participation, @course, @student1, expected_status: 404)
      analytics_api_call(:assignments, @course, @student1, expected_status: 404)
      analytics_api_call(:messaging, @course, @student1, expected_status: 404)
    end

    it "403s with unreadable course" do
      @course1 = @course
      course_with_teacher(active_all: true)

      analytics_api_call(:participation, @course1, @student1, expected_status: 403)
      analytics_api_call(:assignments, @course1, @student1, expected_status: 403)
      analytics_api_call(:messaging, @course1, @student1, expected_status: 403)
    end

    it "403s with out analytics permission" do
      RoleOverride.manage_role_override(@account, teacher_role, "view_analytics", override: false)

      analytics_api_call(:participation, @course, @student1, expected_status: 403)
      analytics_api_call(:assignments, @course, @student1, expected_status: 403)
      analytics_api_call(:messaging, @course, @student1, expected_status: 403)
    end

    it "404s with unreadable student" do
      # section limited ta in section other than student1
      @ta = user_factory(active_all: true)
      @enrollment = @course.enroll_ta(@ta)
      @enrollment.course = @course # set the reverse association
      @enrollment.workflow_state = "active"
      @enrollment.limit_privileges_to_course_section = true
      @enrollment.course_section = @default_section
      @enrollment.save!

      RoleOverride.manage_role_override(@account, ta_role, "view_analytics", override: true)

      analytics_api_call(:participation, @course, @student1, expected_status: 404)
      analytics_api_call(:assignments, @course, @student1, expected_status: 404)
      analytics_api_call(:messaging, @course, @student1, expected_status: 404)
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
      course_with_teacher(active_all: true)
      @default_section = @course.default_section
      @section = @course.course_sections.create!(sis_source_id: "my-section-sis-id",
                                                 name: "section2")
      @course.enroll_user(@student1, "StudentEnrollment", section: @section).accept!

      quiz = quiz_klass.create!(title: "quiz1", context: @course, points_possible: 10)
      quiz.did_edit!
      quiz.offer!
      @a1 = quiz.assignment
      sub = @a1.find_or_create_submission(@student1)
      sub.submission_type = "online_quiz"
      sub.workflow_state = "submitted"
      sub.score = 9
      sub.save!
      @submitted_at = sub.submitted_at
    end

    it "includes student data" do
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
          "posted_at" => nil,
          "submitted_at" => @submitted_at.iso8601,
          "score" => 9
        }
      }]
    end

    it "marks excused assignments" do
      @a1.grade_student(@student1, excuse: true, grader: @teacher)
      json = analytics_api_call(:assignments, @course, @student1)
      expect(json.first["excused"]).to be_truthy
    end
  end

  context "course_student_summaries" do
    it "fetches data for a student in the course" do
      # course with teacher and some students
      course_with_teacher(active_all: true)
      3.times { student_in_course(active_all: true) }
      @user = @teacher

      # don't let the teacher see grades
      RoleOverride.manage_role_override(Account.default, teacher_role, "manage_grades", override: false)
      RoleOverride.manage_role_override(Account.default, teacher_role, "view_all_grades", override: false)

      # should fail
      raw_api_call(:get,
                   "/api/v1/courses/#{@course.id}/analytics/student_summaries",
                   controller: "analytics_api",
                   action: "course_student_summaries",
                   format: "json",
                   course_id: @course.id.to_s)
      expect(response.status.to_i).to eq 403 # Forbidden
    end
  end

  describe "#course_assignments" do
    before do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @user = @teacher
    end

    let(:url) { "/api/v1/courses/#{@course.id}/analytics/assignments" }
    let(:course_assignments_route) do
      {
        controller: "analytics_api",
        action: "course_assignments",
        format: "json",
        course_id: @course.id.to_s
      }
    end

    it "returns assignments" do
      Assignment.create!(
        title: "assignment",
        context: @course,
        points_possible: 10,
        due_at: 2.days.from_now
      )

      json = api_call(:get, url, course_assignments_route)
      expect(response.status.to_i).to eq 200
      expect(json.size).to eq 1
      expect(json.first.keys).to include("assignment_id")
    end

    context "with async" do
      it "returns progress" do
        enable_cache do
          json = api_call(:get, url, course_assignments_route, async: 1.to_s)
          expect(response.status.to_i).to eq 200
          expect(json.keys).to include("progress_url")
          expect(json["progress_url"]).to match(%r{http://www.example.com/api/v1/progress/\d+})
        end
      end

      it "returns the same progress object if called consecutively" do
        enable_cache do
          json1 = api_call(:get, url, course_assignments_route, async: 1.to_s)
          json2 = api_call(:get, url, course_assignments_route, async: 1.to_s)
          expect(json1).to eq json2
        end
      end
    end
  end

  describe "#student_in_course_participation" do
    before do
      course_with_teacher(active_all: true)
      course_with_student(course: @course, active_all: true)
    end

    s
    it "returns submission data when graded but not submitted" do
      assignment = assignment_model course: @course
      assignment.grade_student(@student, grade: 1, grader: @teacher)

      json = analytics_api_call(:assignments, @course, @student, user: @teacher)
      expect(json.first["submission"]["score"]).to eq 1
    end

    it "has date string page_views keys" do
      pv = page_view(user: @student, course: @course)
      pv.save!
      expected = pv.created_at.to_date.strftime("%Y-%m-%d") # rubocop:disable Specs/NoStrftime
      json = analytics_api_call(:participation, @course, @student, user: @teacher)
      expect(json["page_views"].keys).to eq [expected]
    end
  end
end
