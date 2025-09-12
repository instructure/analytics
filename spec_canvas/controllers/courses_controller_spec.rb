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

describe CoursesController, type: :controller do
  before do
    @account = Account.default
    @account.allowed_services = "+analytics"
    @account.save!

    # give all teachers in the account canvalytics permissions for now
    RoleOverride.manage_role_override(@account, teacher_role, "view_analytics", override: true)
  end

  context "permissions" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    before do
      user_session(@teacher)
    end

    def forbid_injection(opts = {})
      course = opts[:course] || @course
      get "show", params: { id: course.id }
      expect(controller.course_custom_links.pluck(:url)).not_to include "/courses/#{course.id}/analytics"
    end

    it "injects an analytics button under nominal conditions" do
      forbid_injection
    end

    it "does not inject an analytics button if analytics 2.0 is enabled" do
      @course.enable_feature!(:analytics_2)
      forbid_injection
    end

    it "does not inject an analytics button with analytics disabled" do
      @account.allowed_services = "-analytics"
      @account.save!
      forbid_injection
    end

    it "does not inject an analytics button on an unpublished course" do
      @course.workflow_state = "created"
      @course.save!
      forbid_injection
    end

    it "does not inject an analytics button on an unreadable course" do
      @course1 = @course
      course_with_teacher(active_all: true)
      user_session(@teacher)
      forbid_injection(course: @course1)
    end

    it "still injects an analytics button on a concluded course" do
      # teachers viewing analytics for a concluded course is currently
      # broken. so let an admin try it.
      user_session(account_admin_user)
      @course.complete!
      forbid_injection
    end

    it "does not inject an analytics button without the analytics permission" do
      RoleOverride.manage_role_override(@account, teacher_role, "view_analytics", override: false)
      forbid_injection
    end

    it "does not inject an analytics button without the read_as_admin permission" do
      RoleOverride.manage_role_override(@account, student_role, "view_analytics", override: true)
      user_session(@student)
      forbid_injection
    end

    it "does not inject an analytics button without active/completed enrollments in the course" do
      @enrollment.workflow_state = "invited"
      @enrollment.save!
      forbid_injection
    end
  end
end
