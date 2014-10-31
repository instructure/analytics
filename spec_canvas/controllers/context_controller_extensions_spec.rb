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

require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe ContextController, :type => :controller do
  before :each do
    @account = Account.default
    @account.allowed_services = '+analytics'
    @account.save!

    # give all teachers in the account canvalytics permissions for now
    RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'view_analytics', :override => true)
  end

  context "permissions" do
    before :each do
      @student1 = user(:active_all => true)
      course_with_teacher(:active_all => true)
      @default_section = @course.default_section
      @section = factory_with_protected_attributes(@course.course_sections, :sis_source_id => 'my-section-sis-id', :name => 'section2')
      @enrollment = @course.enroll_user(@student1, 'StudentEnrollment', :section => @section)
      @enrollment.accept!
      user_session(@teacher)
    end

    def expect_injection(course, student)
      expected_link = "/courses/#{course.id}/analytics/users/#{student.id}"
      get 'roster_user', :course_id => course.id, :id => student.id
      expect(assigns(:js_env).has_key?(:ANALYTICS)).to be_truthy
      expect(assigns(:js_env)[:ANALYTICS]).to eq({ 'link' => expected_link, 'student_name' => student.short_name })
    end

    def forbid_injection(course, student)
      get 'roster_user', :course_id => course.id, :id => student.id
      expect(assigns(:js_env).try(:has_key?, :ANALYTICS)).to be_falsey
    end

    context "nominal conditions" do
      before :each do
        @student2 = student_in_course(:active_all => true).user
      end

      it "should inject an analytics button on the roster_user page 1" do
        expect_injection(@course, @student1)
      end

      it "should inject an analytics button on the roster_user page 2" do
        expect_injection(@course, @student2)
      end
    end

    context "analytics disabled" do
      before :each do
        @account.allowed_services = '-analytics'
        @account.save!
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_injection(@course, @student1)
      end
    end

    context "unpublished course" do
      before :each do
        @course.workflow_state = 'created'
        @course.save!
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_injection(@course, @student1)
      end
    end

    context "concluded course" do
      before :each do
        # teachers viewing analytics for a concluded course is currently
        # broken. so let an admin try it.
        user_session(account_admin_user)
        @course.complete!
      end

      it "should still inject an analytics button on the roster_user page" do
        expect_injection(@course, @student1)
      end
    end

    context "no analytics permission" do
      before :each do
        RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'view_analytics', :override => false)
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_injection(@course, @student1)
      end
    end

    context "no manage_grades or view_all_grades permission" do
      before :each do
        RoleOverride.manage_role_override(@account, 'StudentEnrollment', 'view_analytics', :override => true)
        @student2 = student_in_course(:active_all => true).user
      end

      it "should inject an analytics button on the student's own roster_user page" do
        user_session(@student1)
        expect_injection(@course, @student1)
      end

      it "should not inject an analytics button on another student's roster_user page" do
        user_session(@student1)
        forbid_injection(@course, @student2)
      end
    end

    context "invited-only enrollments" do
      before :each do
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
      end

      it "should not inject an analytics button on the roster user page" do
        forbid_injection(@course, @student1)
      end
    end

    context "unreadable student" do
      before :each do
        # section limited ta in section other than student1
        @ta = user(:active_all => true)
        @enrollment = @course.enroll_ta(@ta)
        @enrollment.course = @course # set the reverse association
        @enrollment.workflow_state = 'active'
        @enrollment.limit_privileges_to_course_section = true
        @enrollment.course_section = @default_section
        @enrollment.save!
        user_session(@ta)

        RoleOverride.manage_role_override(@account, 'TaEnrollment', 'view_analytics', :override => true)
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_injection(@course, @student1)
      end
    end
  end
end
