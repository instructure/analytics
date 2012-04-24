require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe Analytics::Course do
  before :each do
    # set @course, @teacher, @teacher_enrollment
    course(:active_course => true)
    @teacher_enrollment = course_with_teacher(:course => @course, :name => 'Teacher', :active_all => true)
    @teacher_analytics = Analytics::Course.new(@teacher, nil, @course)
  end

  describe "#enrollments" do
    it "should not include non-student enrollments from the course" do
      @teacher_analytics.enrollments.should_not include(@teacher_enrollment)
    end

    it "should include active student enrollments from the course" do
      active_student
      @teacher_analytics.enrollments.should include(@student_enrollment)
    end

    it "should include completed student enrollments from the course" do
      completed_student
      @teacher_analytics.enrollments.should include(@student_enrollment)
    end

    it "should not include invited student enrollments from the course" do
      invited_student
      @teacher_analytics.enrollments.should_not include(@student_enrollment)
    end

    context "when the user is section limited" do
      before :each do
        # set @sectionA, @sectionB, @ta, @ta_enrollment
        add_section("Section A"); @sectionA = @course_section
        add_section("Section B"); @sectionB = @course_section
        @ta_enrollment = course_with_ta(:course => @course, :name => 'Section B TA', :active_all => true)
        @ta_enrollment.course_section = @sectionB
        @ta_enrollment.limit_privileges_to_course_section = true
        @ta_enrollment.save!
        @ta_analytics = Analytics::Course.new(@ta, nil, @course)
      end

      it "should include enrollments from the user's sections" do
        active_student(:section => @sectionB)
        @ta_analytics.enrollments.should include(@student_enrollment)
      end

      it "should not include enrollments from other sections" do
        active_student(:section => @sectionA)
        @ta_analytics.enrollments.should_not include(@student_enrollment)
      end
    end
  end

  describe ".available_for?(user, session, course)" do
    it "should be true with an active enrollment in the course" do
      active_student
      Analytics::Course.available_for?(@teacher, nil, @course).should be_true
    end

    it "should be true with a completed enrollment in the course" do
      completed_student
      Analytics::Course.available_for?(@teacher, nil, @course).should be_true
    end

    it "should be false with only invited enrollments in the course" do
      invited_student
      Analytics::Course.available_for?(@teacher, nil, @course).should be_false
    end

    context "when the user is section limited" do
      before :each do
        # set @sectionA, @sectionB, @ta, @ta_enrollment
        add_section("Section A"); @sectionA = @course_section
        add_section("Section B"); @sectionB = @course_section
        @ta_enrollment = course_with_ta(:course => @course, :name => 'Section B TA', :active_all => true)
        @ta_enrollment.course_section = @sectionB
        @ta_enrollment.limit_privileges_to_course_section = true
        @ta_enrollment.save!
        @ta_analytics = Analytics::Course.new(@ta, nil, @course)
      end

      it "should be true with an enrollment in the user's section" do
        active_student(:section => @sectionB)
        Analytics::Course.available_for?(@ta, nil, @course).should be_true
      end

      it "should be false with no enrollments in the user's section" do
        active_student(:section => @sectionA)
        Analytics::Course.available_for?(@ta, nil, @course).should be_false
      end
    end
  end

  describe "#available?" do
    it "should be true with an active enrollment in the course" do
      active_student
      @teacher_analytics.should be_available
    end

    it "should be true with a completed enrollment in the course" do
      completed_student
      @teacher_analytics.should be_available
    end

    it "should be false with only invited enrollments in the course" do
      invited_student
      @teacher_analytics.should_not be_available
    end

    context "when the user is section limited" do
      before :each do
        # set @sectionA, @sectionB, @ta, @ta_enrollment
        add_section("Section A"); @sectionA = @course_section
        add_section("Section B"); @sectionB = @course_section
        @ta_enrollment = course_with_ta(:course => @course, :name => 'Section B TA', :active_all => true)
        @ta_enrollment.course_section = @sectionB
        @ta_enrollment.limit_privileges_to_course_section = true
        @ta_enrollment.save!
        @ta_analytics = Analytics::Course.new(@ta, nil, @course)
      end

      it "should be true with an enrollment in the user's section" do
        active_student(:section => @sectionB)
        @ta_analytics.should be_available
      end

      it "should be false with no enrollments in the user's section" do
        active_student(:section => @sectionA)
        @ta_analytics.should_not be_available
      end
    end
  end

  describe "#start_date" do
    it "should be the earliest effective_start_at of any of Analytics::Course#enrollments" do
      dates = [ 1.day.ago, 5.days.ago, 3.days.ago ]
      dates.each{ active_student }
      @teacher_analytics.enrollments.zip(dates).each{ |e,date| e.stubs(:effective_start_at).returns(date) }

      @teacher_analytics.start_date.should == dates.min
    end

    it "should not be nil even if none of the enrollments have an effective_start_at" do
      dates = [nil, nil, nil]
      dates.each{ active_student }
      @teacher_analytics.enrollments.zip(dates).each{ |e,date| e.stubs(:effective_start_at).returns(date) }

      @teacher_analytics.start_date.should_not be_nil
    end
  end

  describe "#end_date" do
    it "should be the latest effective_end_at of any of Analytics::Course#enrollments" do
      dates = [ 1.day.from_now, 5.days.from_now, 3.days.from_now ]
      dates.each{ active_student }
      @teacher_analytics.enrollments.zip(dates).each{ |e,date| e.stubs(:effective_end_at).returns(date) }

      @teacher_analytics.end_date.should == dates.max
    end

    it "should be 'now' if none of the enrollments have an effective_end_at" do
      dates = [ nil, nil, nil ]
      dates.each{ active_student }
      @teacher_analytics.enrollments.zip(dates).each{ |e,date| e.stubs(:effective_end_at).returns(date) }

      @teacher_analytics.end_date.should_not be_nil
    end
  end

  describe "#students" do
    it "should include all students with an enrollment in Analytics::Course#enrollments" do
      student_ids = []
      3.times do
        active_student
        student_ids << @student.id
      end

      @teacher_analytics.students.map{ |s| s.id }.sort.should == student_ids.sort
    end

    it "should include each student only once" do
      active_student

      # add a second enrollment in another section
      add_section("Other Section")
      @second_enrollment = @course.enroll_student(@student, :section => @course_section, :allow_multiple_enrollments => true)
      @second_enrollment.course = @course
      @second_enrollment.workflow_state = 'active'
      @second_enrollment.save!
      @course.reload

      # should see both enrollments, but the student only once
      @teacher_analytics.enrollments.size.should == 2
      @teacher_analytics.students.map{ |s| s.id }.should == [ @student.id ]
    end
  end

  describe "#page_views" do
    before :each do
      active_student
    end

    it "should include student's page views in the course" do
      page_view(:user => @student, :course => @course)
      @teacher_analytics.page_views.should_not be_empty
    end

    it "should not include non-student's page views in the course" do
      page_view(:user => @teacher, :course => @course)
      @teacher_analytics.page_views.should be_empty
    end

    it "should not include student's page views from outside the course" do
      @other_course = course(:active_course => true)
      page_view(:user => @student, :course => @other_course)
      @teacher_analytics.page_views.should be_empty
    end

    it "should not include summarized page views" do
      page_view(:user => @student, :course => @course, :summarized => true)
      @teacher_analytics.page_views.should be_empty
    end
  end

  describe "#assignments" do
    before :each do
      @assignment = @course.assignments.active.create!
    end

    describe ":score_distribution" do
      it "should include students submissions in the course" do
        5.times do |i|
          active_student
          @assignment.submissions.create!(:user => @student, :score => i)
        end

        @teacher_analytics.assignments.first[:min_score].should == 0
        @teacher_analytics.assignments.first[:first_quartile].should == 0.5
        @teacher_analytics.assignments.first[:median].should == 2
        @teacher_analytics.assignments.first[:third_quartile].should == 3.5
        @teacher_analytics.assignments.first[:max_score].should == 4
      end

      it "should not include non-student's submissions in the course" do
        @assignment.submissions.create!(:user => @teacher)
        @teacher_analytics.assignments.first[:min_score].should be_nil
      end

      it "should not include student's submissions from outside the course" do
        active_student

        # enroll the student in another course and create a submission there
        @other_course = course(:active_course => true)
        course_with_student(:course => @other_course, :user => @student, :active_enrollment => true)
        @other_assignment = @other_course.assignments.active.create!
        @other_assignment.submissions.create!(:user => @student, :score => 1)

        @teacher_analytics.assignments.first[:min_score].should be_nil
      end
    end

    describe ":tardiness_breakdown" do
      before :each do
        active_student
        @submission = @assignment.submissions.create!(:user => @student)
      end

      context "when the assignment has a due date" do
        before :each do
          @assignment.due_at = 1.day.ago
          @assignment.save!
        end

        context "a student that submitted something" do
          before :each do
            submit_submission
          end

          it "should count as on time if submitted on or before the due date" do
            @submission.submitted_at = @assignment.due_at - 1.day
            @submission.save!

            expect_assignment_breakdown(:on_time)
          end

          it "should count as late if submitted after the due date" do
            @submission.submitted_at = @assignment.due_at + 1.day
            @submission.save!

            expect_assignment_breakdown(:late)
          end
        end

        context "a student that hasn't submitted anything but was graded" do
          before :each do
            grade_submission
          end

          it "should count as on time when the assignment does not expect a submission" do
            @assignment.submission_types = 'none'
            @assignment.save!

            expect_assignment_breakdown(:on_time)
          end

          context "when the assignment expects a submission" do
            before :each do
              @assignment.submission_types = 'online_text_entry'
              @assignment.save!
            end

            it "should count as on time if graded on or before due_at" do
              @submission.graded_at = @assignment.due_at - 1.day
              @submission.save!

              expect_assignment_breakdown(:on_time)
            end

            it "should count as late if graded after due_at" do
              @submission.graded_at = @assignment.due_at + 1.day
              @submission.save!

              expect_assignment_breakdown(:late)
            end
          end
        end

        context "a student that hasn't submitted anything nor been graded" do
          it "should count as missing if the due date is in the past" do
            @assignment.due_at = 1.day.ago
            @assignment.save!

            expect_assignment_breakdown(:missing)
          end

          it "should not count if the due date is in the future" do
            @assignment.due_at = 1.day.from_now
            @assignment.save!

            expect_assignment_breakdown(:none)
          end
        end
      end

      context "when the assignment has no due date" do
        before :each do
          @assignment.due_at = nil
          @assignment.save!
        end

        it "should count a student that submitted something as on time" do
          submit_submission(:submitted_at => 1.day.ago)
          expect_assignment_breakdown(:on_time)
        end

        it "should count a student that hasn't submitted anything but was graded as on time" do
          grade_submission
          expect_assignment_breakdown(:on_time)
        end

        it "should not count a student that hasn't submitted anything nor been graded" do
          expect_assignment_breakdown(:none)
        end
      end
    end
  end

  describe "#student_summaries" do
    describe "a student's summary" do
      before :each do
        active_student
      end

      it "should count page_views for that student" do
        page_view(:user => @student, :course => @course)
        @teacher_analytics.student_summaries[@student.id][:page_views].should == 1
      end

      it "should count participations for that student" do
        view = page_view(:user => @student, :course => @course, :participated => true)
        @teacher_analytics.student_summaries[@student.id][:participations].should == 1
      end

      describe ":tardiness_breakdown" do
        it "should include the number of assignments" do
          5.times{ @course.assignments.active.create! }
          @teacher_analytics.student_summaries[@student.id][:tardiness_breakdown][:total].should == 5
        end

        context "an assignment that has a due date" do
          before :each do
            @assignment = @course.assignments.active.create!
            @submission = @assignment.submissions.create!(:user => @student)

            @assignment.due_at = 1.day.ago
            @assignment.save!
          end

          context "when the student submitted something" do
            before :each do
              submit_submission
            end

            it "should count as on time if submitted on or before the due date" do
              @submission.submitted_at = @assignment.due_at - 1.day
              @submission.save!

              expect_summary_breakdown(:on_time)
            end

            it "should count as late if submitted after the due date" do
              @submission.submitted_at = @assignment.due_at + 1.day
              @submission.save!

              expect_summary_breakdown(:late)
            end
          end

          context "when the student hasn't submitted anything but was graded" do
            before :each do
              grade_submission
            end

            it "should count as on time when the assignment does not expect a submission" do
              @assignment.submission_types = 'none'
              @assignment.save!

              expect_summary_breakdown(:on_time)
            end

            context "when the assignment expects a submission" do
              before :each do
                @assignment.submission_types = 'online_text_entry'
                @assignment.save!
              end

              it "should count as on time if graded on or before due_at" do
                @submission.graded_at = @assignment.due_at - 1.day
                @submission.save!

                expect_summary_breakdown(:on_time)
              end

              it "should count as late if graded after due_at" do
                @submission.graded_at = @assignment.due_at + 1.day
                @submission.save!

                expect_summary_breakdown(:late)
              end
            end
          end

          context "when the student hasn't submitted anything nor been graded" do
            it "should count as missing if the due date is in the past" do
              @assignment.due_at = 1.day.ago
              @assignment.save!

              expect_summary_breakdown(:missing)
            end

            it "should not count if the due date is in the future" do
              @assignment.due_at = 1.day.from_now
              @assignment.save!

              expect_summary_breakdown(:none)
            end
          end
        end

        context "an assignment that has no due date" do
          before :each do
            @assignment = @course.assignments.active.create!
            @submission = @assignment.submissions.create!(:user => @student)
          end

          it "should count as on time when the student submitted something" do
            submit_submission(:submitted_at => 1.day.ago)
            expect_summary_breakdown(:on_time)
          end

          it "should count as on time when the student hasn't submitted anything but was graded" do
            grade_submission
            expect_summary_breakdown(:on_time)
          end

          it "should not count when the student that hasn't submitted anything nor been graded" do
            expect_summary_breakdown(:none)
          end
        end
      end
    end
  end
end

Spec::Runner.configure do |config|
  def student(opts={})
    course = opts[:course] || @course

    # sets @student and @student_enrollment
    @student_enrollment = course_with_student(
      :course => course,
      :name => opts[:name] || 'Student',
      :active_user => true)

    needs_save = false

    if opts[:section]
      @student_enrollment.course_section = opts[:section]
      needs_save = true
    end

    if opts[:enrollment_state]
      @student_enrollment.workflow_state = opts[:enrollment_state]
      needs_save = true
    end

    @student_enrollment.save! if needs_save
    @student_enrollment
  end

  def active_student(opts={})
    student({:name => 'Active Student', :enrollment_state => 'active'}.merge(opts))
  end

  def completed_student(opts={})
    student({:name => 'Completed Student', :enrollment_state => 'completed'}.merge(opts))
  end

  def invited_student(opts={})
    student({:name => 'Invited Student', :enrollment_state => 'invited'}.merge(opts))
  end

  def page_view(opts={})
    course = opts[:course] || @course
    user = opts[:user] || @student
    controller = opts[:assignments] || 'assignments'
    summarized = opts[:summarized] || nil

    page_view = course.page_views.build(
      :user => user,
      :controller => controller)

    page_view.summarized = summarized
    page_view.request_id = ''

    if opts[:participated]
      page_view.participated = true
      access = page_view.build_asset_user_access
      access.display_name = 'Some Asset'
    end

    page_view.save!
    page_view
  end

  def grade_submission
    @submission.grade = 'A'
    @submission.score = '1'
    @submission.grade_matches_current_submission = true
    @submission.save!
  end

  def submit_submission(opts={})
    @submission.submission_type = 'online_text_entry'
    @submission.submitted_at = opts[:submitted_at] if opts[:submitted_at]
    @submission.save!
  end

  def expected_breakdown(bin)
    expected = { :on_time => 0, :late => 0, :missing => 0 }
    expected[bin] = 1 unless bin == :none
    expected
  end

  def expect_assignment_breakdown(bin)
    @teacher_analytics.assignments.first[:tardiness_breakdown].should == expected_breakdown(bin)
  end

  def expect_summary_breakdown(bin)
    expected = expected_breakdown(bin)
    expected[:total] = 1
    @teacher_analytics.student_summaries[@student.id][:tardiness_breakdown].should == expected
  end
end
