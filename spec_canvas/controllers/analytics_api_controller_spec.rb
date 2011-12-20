#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of the analytics engine

require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/apis/api_spec_helper')

describe AnalyticsApiController, :type => :integration do

  def submit_homework(assignment, student, opts = {:body => "test!"})
    @submit_homework_time ||= Time.now.utc
    @submit_homework_time += 1.hour
    sub = assignment.find_or_create_submission(student)
    if sub.versions.size == 1
      Version.update_all({:created_at => @submit_homework_time}, {:id => sub.versions.first.id})
    end
    sub.workflow_state = 'submitted'
    yield(sub) if block_given?
    sub.with_versioning(:explicit => true) do
      update_with_protected_attributes!(sub, { :submitted_at => @submit_homework_time, :created_at => @submit_homework_time }.merge(opts))
    end
    sub.versions(true).each { |v| Version.update_all({ :created_at => v.model.created_at }, { :id => v.id }) }
    sub
  end

  it "should 404 if the course does not exist" do
    user_session(site_admin_user)
    raw_api_call(:get,
          "/api/v1/analytics/assignments/courses/blah",
          { :controller => 'analytics_api', :action => 'course_assignments',
            :format => 'json', :course_id => "blah"},
          {})
    response.status.to_i.should == 404
  end

  context "course and quiz without scores" do
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
      sub.save!
      @submitted_at = sub.submitted_at
    end

    it "should return data if the student is not specified" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}",
            { :controller => 'analytics_api', :action => 'course_assignments',
              :format => 'json', :course_id => @course.id.to_s},
            {})
      json.should == {"turn_around_times" => {},
                      "assignments" => { "#{@a1.id}" => {"late_count"=>0,
                                                "max_score"=>nil,
                                                "std_dev_score"=>nil,
                                                "submission_count"=>1,
                                                "unlock_at"=>nil,
                                                "average_score"=>nil,
                                                "min_score"=>nil,
                                                "on_time_count"=>1,
                                                "due_at"=>nil } } }
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

    it "should include student data if the student is specified" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@student1.id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => @course.id.to_s, :user_id => @student1.id.to_s },
            {})
      json.should == {"turn_around_times" => {},
                      "assignments" => { "#{@a1.id}" => {"late_count"=>0,
                                                "max_score"=>9,
                                                "std_dev_score"=>0,
                                                "unlock_at"=>nil,
                                                "average_score"=>9,
                                                "min_score"=>9,
                                                "on_time_count"=>1,
                                                "submission_count"=>1,
                                                "due_at"=>nil,
                                                "submission"=>{
                                                  "submitted_at"=>@submitted_at.as_json,
                                                  "score"=>9} } } }
    end
  end

  context "course multiple assignements with a multiple users and scores" do
    before do
      num_users = 5
      num_assignments = 5

      @students = []
      @assignments = []

      num_users.times {|u| @students << user(:active_all => true)}

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

      for s_index in 0..(num_users - 1)
        student = @students[s_index]
        for a_index in 0..(num_assignments - 1)
          assignment = @assignments[a_index]
          sub = assignment.find_or_create_submission(student)
          sub.score = (10 * (a_index + 1)) - s_index * (a_index+1)
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

    it "should fetch data for a student in the course" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
    end

    it "should have turn around times" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
      json["turn_around_times"] == {"n/a"=>5, "2"=>1, "3"=>5, "4"=>5, "5"=>4}
    end

    it "should count late assignments" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
      json["assignments"][@assignments[1].id.to_s]["late_count"] == 1
    end

    it "should count on time assignments" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
      json["assignments"][@assignments[2].id.to_s]["on_time_count"] == 4
    end

    it "should calculate max score" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
      json["assignments"][@assignments[3].id.to_s]["max_score"] == 40
    end

    it "should calculate min score" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
      json["assignments"][@assignments[4].id.to_s]["min_score"] == 30
    end

    it "should calculate standard deviation of scores" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
      json["assignments"][@assignments[0].id.to_s]["std_dev_score"] == 1.4142135623731
    end

    it "should calculate average of scores" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
      json["assignments"][@assignments[1].id.to_s]["average_score"] == 16
    end

    it "should have the user score" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
      json["assignments"][@assignments[2].id.to_s]["submission"]["score"] == 27
    end

    it "should have the user submit time" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
      json["assignments"][@assignments[4].id.to_s]["submission"]["submitted_at"] == (@due_time - 1.hours).strftime("%Y-%m-%d %H:%M:%S")
    end

    it "should track due dates" do
      json = api_call(:get,
            "/api/v1/analytics/assignments/courses/#{@course.id}/users/#{@students[1].id}",
            { :controller => 'analytics_api', :action => 'course_user_assignments',
              :format => 'json', :course_id => String(@course.id), :user_id => String(@students[1].id)},
            { })
      json["assignments"][@assignments[3].id.to_s]["due_at"] == @due_time.strftime("%Y-%m-%d %H:%M:%S")
    end
  end

end
