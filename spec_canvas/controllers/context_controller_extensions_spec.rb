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

require_relative '../../../../../spec/spec_helper'

describe ContextController, :type => :controller do
  before :once do
    @account = Account.default
    @account.allowed_services = '+analytics'
    @account.save!

    # give all teachers in the account canvalytics permissions for now
    RoleOverride.manage_role_override(@account, teacher_role, 'view_analytics', :override => true)
  end

  context "permissions" do
    before :once do
      @student1 = user_factory(active_all: true)
      course_with_teacher(:active_all => true)
      @default_section = @course.default_section
      @section = factory_with_protected_attributes(@course.course_sections, :sis_source_id => 'my-section-sis-id', :name => 'section2')
      @enrollment = @course.enroll_user(@student1, 'StudentEnrollment', :section => @section)
      @enrollment.accept!
    end

    before :each do
      user_session(@teacher)
    end

    def expect_injection(course, student)
      expected_link = "/courses/#{course.id}/analytics/users/#{student.id}"
      get 'roster_user', params: {:course_id => course.id, :id => student.id}
      expect(controller.roster_user_custom_links(student).map { |link| link[:url] }).to include expected_link
    end

    def forbid_injection(course, student)
      analytics_link = "/courses/#{course.id}/analytics/users/#{student.id}"
      get 'roster_user', params: {:course_id => course.id, :id => student.id}
      expect(controller.roster_user_custom_links(student).map { |link| link[:url] }).not_to include analytics_link
    end

    context "nominal conditions" do
      before :once do
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
      before :once do
        @account.allowed_services = '-analytics'
        @account.save!
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_injection(@course, @student1)
      end
    end

    context "unpublished course" do
      before :once do
        @course.workflow_state = 'created'
        @course.save!
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_injection(@course, @student1)
      end
    end

    context "concluded course" do
      before :once do
        @course.complete!
      end

      before :each do
        # teachers viewing analytics for a concluded course is currently
        # broken. so let an admin try it.
        user_session(account_admin_user)
      end

      it "should still inject an analytics button on the roster_user page" do
        expect_injection(@course, @student1)
      end
    end

    context "no analytics permission" do
      before :once do
        RoleOverride.manage_role_override(@account, teacher_role, 'view_analytics', :override => false)
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_injection(@course, @student1)
      end
    end

    context "no manage_grades or view_all_grades permission" do
      before :once do
        RoleOverride.manage_role_override(@account, student_role, 'view_analytics', :override => true)
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
      before :once do
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
      end

      it "should not inject an analytics button on the roster user page" do
        forbid_injection(@course, @student1)
      end
    end

    context "unreadable student" do
      before :once do
        # section limited ta in section other than student1
        @ta = user_factory(active_all: true)
        @enrollment = @course.enroll_ta(@ta)
        @enrollment.course = @course # set the reverse association
        @enrollment.workflow_state = 'active'
        @enrollment.limit_privileges_to_course_section = true
        @enrollment.course_section = @default_section
        @enrollment.save!

        RoleOverride.manage_role_override(@account, ta_role, 'view_analytics', :override => true)
      end

      before :each do
        user_session(@ta)
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_injection(@course, @student1)
      end
    end
  end
end
