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

describe AnalyticsController, :type => :controller do
  before :each do
    @account = Account.default
    @account.allowed_services = '+analytics'
    @account.save!

    @role = custom_account_role('TestAdmin', :account => @account)
    RoleOverride.manage_role_override(@account, @role, 'view_analytics', :override => true)
    @admin = account_admin_user(:account => @account, :role => @role, :active_all => true)
    user_session(@admin)
  end

  describe "department" do
    def department_analytics(opts={})
      account = opts[:account] || @account
      get 'department', params: {:account_id => account.id}
    end

    it "should set @department_analytics on success" do
      department_analytics
      expect(assigns[:department_analytics]).not_to be_nil
    end

    it "should 404 with analytics disabled" do
      @account.allowed_services = ''
      @account.save!
      department_analytics
      assert_status(404)
    end

    it "should 404 on an inactive account" do
      @account = Account.create
      @account.destroy
      department_analytics
      assert_status 404
    end

    it "should 401 without view_analytics permission" do
      RoleOverride.manage_role_override(@account, @role, 'view_analytics', :override => false)
      department_analytics
      assert_unauthorized
    end
  end

  describe "course" do
    before :each do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course(:active_all => true)
    end

    def course_analytics(opts={})
      course = opts[:course] || @course
      get 'course', params: {:course_id => course.id}
    end

    it "should set @course_analytics on success" do
      course_analytics
      expect(assigns[:course_analytics]).not_to be_nil
    end

    it "should 404 with analytics disabled" do
      @account.allowed_services = ''
      @account.save!
      course_analytics
      assert_status(404)
    end

    it "should 404 on a deleted course" do
      @course.destroy
      course_analytics
      assert_status(404)
    end

    it "should 404 on an unpublished course" do
      @course.workflow_state = 'created'
      @course.save!
      course_analytics
      assert_status(404)
    end

    it "should not 404 on a concluded course" do
      # teachers viewing analytics for a concluded course is currently broken.
      # so let the admin do it. but since he's got a unique role, we need to
      # give him permissions.
      user_session(@admin)
      RoleOverride.manage_role_override(@account, @role, 'view_all_grades', :override => true)

      @course.complete!
      course_analytics
      assert_status 200
    end

    it "should 401 without view_analytics permission" do
      RoleOverride.manage_role_override(@account, teacher_role, 'view_analytics', :override => false)
      course_analytics
      assert_unauthorized
    end

    it "should 404 without no enrollments in the course" do
      @enrollment.destroy
      course_analytics
      assert_status(404)
    end

    it "should 401 without read_as_admin permission" do
      user_session(@student)
      course_analytics
      assert_unauthorized
    end

    it "should only include student data with manage_grades or view_all_grades permissions" do
      course_analytics
      expect(assigns[:course_json][:students]).not_to be_nil

      RoleOverride.manage_role_override(@account, teacher_role, 'manage_grades', :override => false)
      RoleOverride.manage_role_override(@account, teacher_role, 'view_all_grades', :override => false)

      @account.clear_permissions_cache(@user)
      course_analytics
      expect(assigns[:course_json][:students]).to be_nil
    end
  end

  describe "student_in_course" do
    before :each do
      RoleOverride.manage_role_override(@account, student_role, 'view_analytics', :override => true)
      course_with_teacher_logged_in(:active_all => true)
      student_in_course(:active_all => true)
    end

    def student_in_course_analytics(opts={})
      course = opts[:course] || @course
      student = opts[:student] || @student
      get 'student_in_course', params: {:course_id => course.id, :student_id => student.id}
    end

    it "should set @course_analytics and @student_analytics on success" do
      student_in_course_analytics
      expect(assigns[:course_analytics]).not_to be_nil
      expect(assigns[:student_analytics]).not_to be_nil
    end

    it "should 404 with analytics disabled" do
      @account.allowed_services = ''
      @account.save!
      student_in_course_analytics
      assert_status(404)
    end

    it "should 404 on a deleted course" do
      @course.destroy
      student_in_course_analytics
      assert_status(404)
    end

    it "should 404 on an unpublished course" do
      @course.workflow_state = 'created'
      @course.save!
      student_in_course_analytics
      assert_status(404)
    end

    it "should not 404 on a concluded course" do
      # teachers viewing analytics for a concluded course is currently broken.
      # so let the admin do it. but since he's got a unique role, we need to
      # give him permissions.
      user_session(@admin)
      RoleOverride.manage_role_override(@account, @role, 'view_all_grades', :override => true)

      @course.complete!
      student_in_course_analytics
      assert_status 200
    end

    it "should 401 without view_analytics permission" do
      RoleOverride.manage_role_override(@account, teacher_role, 'view_analytics', :override => false)
      student_in_course_analytics
      assert_unauthorized
    end

    it "should not 401 without read_as_admin permissions" do
      user_session(@student)
      student_in_course_analytics
      assert_status 200
    end

    it "should 404 for a non-student" do
      student_in_course_analytics(:student => @teacher)
      assert_status(404)
    end

    it "should 404 for an invited (not accepted) student" do
      @enrollment.workflow_state = 'invited'
      @enrollment.save!
      student_in_course_analytics
      assert_status(404)
    end

    it "should 401 for without read_grades permission" do
      # log in with original student, but view analytics for a different student
      user_session(@student)
      student_in_course(:active_all => true)
      student_in_course_analytics
      assert_unauthorized
    end

    it "should include all students for a teacher" do
      students = [@student]
      3.times{ students << student_in_course(:active_all => true).user }
      student_in_course_analytics
      expect(assigns[:course_json][:students].map{ |s| s[:id] }.sort).to eq students.map(&:id).sort
    end

    it "should include only self for a student" do
      students = [@student]
      3.times{ students << student_in_course(:active_all => true).user }
      user_session(@student)
      student_in_course_analytics
      expect(assigns[:course_json][:students].map{ |s| s[:id] }.sort).to eq [@student.id]
    end
  end
end
