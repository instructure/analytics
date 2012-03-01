#
# Copyright (C) 2011 Instructure, Inc.
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
      @course.enroll_user(@student1, 'StudentEnrollment', :section => @section).accept!
      user_session(@teacher)
    end

    def expect_roster_injection(course, students)
      expected_links = {}
      students.each do |student|
        expected_links[student.id] = "/analytics/courses/#{course.id}/users/#{student.id}"
      end
      ContextController.any_instance.expects(:js_env).once.
        with(:ANALYTICS => { :student_links => expected_links})
      get 'roster', :course_id => course.id
    end

    def forbid_roster_injection(course)
      ContextController.any_instance.expects(:js_env).never
      get 'roster', :course_id => course.id
    end

    def expect_roster_user_injection(course, student)
      expected_link = "/analytics/courses/#{course.id}/users/#{student.id}"
      ContextController.any_instance.expects(:js_env).once.
        with(:ANALYTICS => { :link => expected_link, :user_name => student.short_name })
      get 'roster_user', :course_id => course.id, :id => student.id
    end

    def forbid_roster_user_injection(course, student)
      ContextController.any_instance.expects(:js_env).never
      get 'roster_user', :course_id => course.id, :id => student.id
    end

    context "nominal conditions" do
      it "should inject analytics buttons on the roster page" do
        expect_roster_injection(@course, [@student1])
      end

      it "should inject an analytics button on the roster_user page" do
        expect_roster_user_injection(@course, @student1)
      end
    end

    context "analytics disabled" do
      before :each do
        @account.allowed_services = '-analytics'
        @account.save!
      end

      it "should not inject analytics buttons on the roster page" do
        forbid_roster_injection(@course)
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_roster_user_injection(@course, @student1)
      end
    end

    context "unreadable course" do
      before :each do
        @course1 = @course
        course_with_teacher(:active_all => true)
        user_session(@teacher)
      end

      it "should not inject analytics buttons on the roster page" do
        forbid_roster_injection(@course1)
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_roster_user_injection(@course1, @student1)
      end
    end

    context "no analytics permission" do
      before :each do
        RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'view_analytics', :override => false)
      end

      it "should not inject analytics buttons on the roster page" do
        forbid_roster_injection(@course)
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_roster_user_injection(@course, @student1)
      end
    end

    context "unreadable user" do
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

      it "should not inject analytics buttons on the roster page" do
        forbid_roster_injection(@course)
      end

      it "should not inject an analytics button on the roster_user page" do
        forbid_roster_user_injection(@course, @student1)
      end
    end
  end
end
