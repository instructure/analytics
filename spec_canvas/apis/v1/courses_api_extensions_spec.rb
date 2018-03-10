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

describe "Courses API Extensions", :type => :request do
  before :each do
    @account = Account.default
    @account.allowed_services = '+analytics'
    @account.save!

    # give all teachers in the account canvalytics permissions for now
    RoleOverride.manage_role_override(@account, teacher_role, 'view_analytics', :override => true)
  end

  context "permissions" do
    before :each do
      @student1 = user_factory(active_all: true)
      course_with_teacher(:active_all => true)
      @default_section = @course.default_section
      @section = factory_with_protected_attributes(@course.course_sections, :sis_source_id => 'my-section-sis-id', :name => 'section2')
      @enrollment = @course.enroll_user(@student1, 'StudentEnrollment', :section => @section)
      @enrollment.accept!
      @user = @teacher
    end

    def expect_injection(course, students)
      json = api_call(:get, "/api/v1/courses/#{course.id}/users?include[]=enrollments",
                      :controller => "courses",
                      :action => "users",
                      :course_id => course.id.to_s,
                      :include => ['enrollments'],
                      :format => "json")

      # each student's json should have the expected analytics url or lack thereof
      seen_students = []
      json.each do |student_json|
        student = students.detect{ |s| s.id == student_json['id'] }
        if student
          expect(student_json['analytics_url']).to eq "/courses/#{course.id}/analytics/users/#{student.id}"
          seen_students << student
        else
          expect(student_json.has_key?('analytics_url')).to be_falsey
        end
      end

      # all the given students should have been seen
      expect(seen_students.map(&:id).sort).to eq students.map(&:id).sort
    end

    def forbid_injection(course, students)
      json = api_call(:get, "/api/v1/courses/#{course.id}/users?include[]=enrollments",
                      :controller => "courses",
                      :action => "users",
                      :course_id => course.id.to_param,
                      :include => ['enrollments'],
                      :format => "json")

      # for the students we're interested in, make sure they don't have an url
      json.each do |student_json|
        student = students.detect{ |s| s.id == student_json['id'] }
        if student
          expect(student_json['analytics_url']).to be_falsey
        end
      end
    end

    context "nominal conditions" do
      before :each do
        @student2 = student_in_course(:active_all => true).user
        @user = @teacher
      end

      it "should inject analytics buttons on the roster page" do
        expect_injection(@course, [@student1, @student2])
      end
    end

    context "analytics disabled" do
      before :each do
        @account.allowed_services = '-analytics'
        @account.save!
      end

      it "should not inject analytics buttons on the roster page" do
        forbid_injection(@course, [@student1])
      end
    end

    context "unpublished course" do
      before :each do
        @course.workflow_state = 'created'
        @course.save!
      end

      it "should not inject analytics buttons on the roster page" do
        forbid_injection(@course, [@student1])
      end
    end

    context "no analytics permission" do
      before :each do
        RoleOverride.manage_role_override(@account, teacher_role, 'view_analytics', :override => false)
      end

      it "should not inject analytics buttons on the roster page" do
        forbid_injection(@course, [@student1])
      end
    end

    context "no manage_grades or view_all_grades permission" do
      before :each do
        RoleOverride.manage_role_override(@account, student_role, 'view_analytics', :override => true)
        @student2 = student_in_course(:active_all => true).user
      end

      it "should only inject one analytics button on the roster page" do
        @user = @student1
        expect_injection(@course, [@student1])

        @user = @student2
        expect_injection(@course, [@student2])
      end
    end

    context "invited-only enrollments" do
      before :each do
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
      end

      it "should not inject an analytics button on the roster page" do
        forbid_injection(@course, [@student1])
      end
    end

    context "unreadable student" do
      before :each do
        # section limited ta in section other than student1
        @ta = user_factory(active_all: true)
        @enrollment = @course.enroll_ta(@ta)
        @enrollment.course = @course # set the reverse association
        @enrollment.workflow_state = 'active'
        @enrollment.limit_privileges_to_course_section = true
        @enrollment.course_section = @default_section
        @enrollment.save!
        @user = @ta

        RoleOverride.manage_role_override(@account, ta_role, 'view_analytics', :override => true)
      end

      it "should not inject analytics buttons on the roster page" do
        forbid_injection(@course, [@student1])
      end
    end
  end

  context "includes" do
    before :each do
      course_with_teacher(:active_all => true)
      @student = student_in_course(:active_all => true)
      @user = @teacher
    end

    it "doesn't duplicate the include param" do
      raw_api_call(:get, "/api/v1/courses/#{@course.id}/users?include[]=enrollments&include[]=analytics_url",
                   :controller => "courses",
                   :action => "users",
                   :course_id => @course.id.to_s,
                   :include => ['enrollments', 'analytics_url'],
                   :format => "json")

      # one each for first/last/next
      expect(response.headers["Link"].scan("analytics_url").count).to eq 3
    end
  end
end
