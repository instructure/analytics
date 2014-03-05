require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../cassandra_spec_helper')

describe Analytics::Course do
  before :each do
    # set @course, @teacher, @teacher_enrollment
    course(:active_course => true)
    @teacher_enrollment = course_with_teacher(:course => @course, :name => 'Teacher', :active_all => true)
    @teacher_analytics = Analytics::Course.new(@teacher, @course)
    Setting.set('enable_page_views', 'db')
  end

  describe "extended_assignment_data" do
    let(:aug1) { Time.local(2012, 8, 1) }
    let(:sep1) { Time.local(2012, 9, 1) }
    let(:oct1) { Time.local(2012, 10, 1) }

    describe "with assignment having multiple due dates" do
      let(:assignment) do
        enrollment = active_student # sets @student
        add_section("Section") # sets @course_section
        enrollment.course_section = @course_section
        enrollment.save!
        @course.assignments.active.create! do |assignment|
          assignment.due_at = sep1

          override = AssignmentOverride.new
          override.assignment = assignment
          override.set = @course_section
          override.due_at = oct1
          override.due_at_overridden = true
          override.save!
        end
      end
      describe "when viewed by a teacher" do
        it "multiple_due_dates flag is true" do
          assignment.multiple_due_dates_apply_to?(@teacher).should be_true
          analytics = Analytics::Course.new(@teacher, @course)
          data = analytics.basic_assignment_data(assignment)
          data[:multiple_due_dates].should be_true
        end
      end
      describe "when viewed by a student" do
        it "multiple_due_dates flag is false" do
          assignment.multiple_due_dates_apply_to?(@student).should be_false
          analytics = Analytics::Course.new(@student, @course)
          data = analytics.basic_assignment_data(assignment)
          data[:multiple_due_dates].should be_false
        end
      end
    end
  end

  describe "caching" do
    before :each do
      active_student

      add_section("Section")
      @ta_enrollment = course_with_ta(:course => @course, :name => 'TA', :active_all => true)
      @ta_enrollment.course_section = @course_section
      @ta_enrollment.save!

      @ta_analytics = Analytics::Course.new(@ta, @course)
    end

    it "should use the same cache for users with the same visibility" do
      enable_cache do
        @ta_analytics.students
        @teacher_analytics.expects(:student_scope).never
        @teacher_analytics.students
      end
    end

    it "should not use the same cache for users with the same visibility but different details" do
      enable_cache do
        # while the permissions are ok, they should match
        @teacher_analytics.assignments
        @ta_analytics.expects(:assignment_scope).never
        @ta_analytics.assignments

        # when permissions differ, the ta should get a different value
        @course.stubs(:grants_rights?).returns({})
        @ta_analytics.unstub(:assignment_scope)
        scope = @ta_analytics.assignment_scope
        @ta_analytics.expects(:assignment_scope).returns(scope)
        @ta_analytics.assignments

        # when permissions are the same again, they should still be the same
        # original cache
        @course.unstub(:grants_rights?)
        @ta_analytics.expects(:assignment_scope).never
        @ta_analytics.assignments

        # when permissions differ again, the previous different value should
        # have been cached and now reused
        @course.stubs(:grants_rights?).returns({})
        @ta_analytics.expects(:assignment_scope).never
        @ta_analytics.assignments
      end
    end

    it "should not use the same cache for users with different visibility" do
      @ta_enrollment.limit_privileges_to_course_section = true
      @ta_enrollment.save!

      enable_cache do
        @ta_analytics.students.object_id.should_not == @teacher_analytics.students.object_id
      end
    end
  end

  describe "page views" do
    describe "#page_views" do
      before :each do
        active_student
      end

      it "should include student's page views in the course" do
        page_view(:user => @student, :course => @course)
        @teacher_analytics.participation.should_not be_empty
      end

      it "should include teacher's page views in the course" do
        page_view(:user => @teacher, :course => @course)
        @teacher_analytics.participation.should_not be_empty
      end

      it "should not include student's page views from outside the course" do
        @other_course = course(:active_course => true)
        page_view(:user => @student, :course => @other_course)
        @teacher_analytics.participation.should be_empty
      end
    end

    describe '#page_views_by_student' do
      it 'delegates to the PageView' do
        PageView.stubs(:counters_by_context_for_users => { 1 => 2 } )
        @teacher_analytics.page_views_by_student.should == { 1 => 2 }
      end

      it 'passes the course and students array to the page view' do
        PageView.expects(:counters_by_context_for_users).with(@course, @teacher_analytics.students).returns {}
        @teacher_analytics.page_views_by_student
      end
    end
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
        @ta_analytics = Analytics::Course.new(@ta, @course)
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

  describe "#available_for?(user, course)" do
    it "should be true with an active enrollment in the course" do
      active_student
      Analytics::Course.available_for?(@teacher, @course).should be_true
    end

    it "should be true with a completed enrollment in the course" do
      completed_student
      Analytics::Course.available_for?(@teacher, @course).should be_true
    end

    it "should be false with only invited enrollments in the course" do
      invited_student
      Analytics::Course.available_for?(@teacher, @course).should be_false
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
        @ta_analytics = Analytics::Course.new(@ta, @course)
      end

      it "should be true with an enrollment in the user's section" do
        active_student(:section => @sectionB)
        Analytics::Course.available_for?(@ta, @course).should be_true
      end

      it "should be false with no enrollments in the user's section" do
        active_student(:section => @sectionA)
        Analytics::Course.available_for?(@ta, @course).should be_false
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
        @ta_analytics = Analytics::Course.new(@ta, @course)
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

            expect_assignment_breakdown(:none, :total => 1)
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
          expect_assignment_breakdown(:none, :total => 1)
        end
      end
    end
  end

  describe "student summaries" do
    shared_examples_for "#student_summaries" do
      describe "a student's summary" do
        before :each do
          active_student(:name => 'Student1')
        end

        it "should count page_views for that student" do
          page_view(:user => @student, :course => @course)
          student_summary[:page_views].should == 1
        end

        it "should count participations for that student" do
          view = page_view(:user => @student, :course => @course, :participated => true)
          student_summary[:participations].should == 1
        end

        describe ":tardiness_breakdown" do
          it "should include the number of assignments" do
            5.times{ @course.assignments.active.create! }
            student_summary[:tardiness_breakdown][:total].should == 5
          end

          it "should have appropriate data per student" do
            @student1 = @student
            active_student(:name => 'Student2')
            @student2 = @student

            @assignment = @course.assignments.active.create!(:due_at => 1.day.ago)
            @submission1 = @assignment.submissions.create!(:user => @student1)
            @submission2 = @assignment.submissions.create!(:user => @student2)

            submit_submission(:submission => @submission1, :submitted_at => @assignment.due_at - 1.day)
            submit_submission(:submission => @submission2, :submitted_at => @assignment.due_at + 1.day)

            @summaries = @teacher_analytics.student_summaries.paginate(:page => 1, :per_page => 2)
            @summaries.detect{|s| s[:id] == @submission1.user_id}[:tardiness_breakdown].should == expected_breakdown(:on_time).merge(:total => 1)
            @summaries.detect{|s| s[:id] == @submission2.user_id}[:tardiness_breakdown].should == expected_breakdown(:late).merge(:total => 1)
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
    describe "#student_summaries db" do
      include_examples "#student_summaries"
    end

    describe "#student_summaries cassandra" do
      include_examples "analytics cassandra page views"
      include_examples "#student_summaries"
    end
  end

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

  def grade_submission
    @submission.grade = 'A'
    @submission.score = '1'
    @submission.grade_matches_current_submission = true
    @submission.save!
  end

  def submit_submission(opts={})
    submission = opts[:submission] || @submission
    submission.submission_type = 'online_text_entry'
    submission.submitted_at = opts[:submitted_at] if opts[:submitted_at]
    submission.save!
  end

  def student_summary(analytics=@teacher_analytics)
    analytics.student_summaries.paginate(:page => 1, :per_page => 1).first
  end

  def expected_breakdown(bin)
    expected = { :on_time => 0, :late => 0, :missing => 0, :total => 0 }
    if bin != :none
      expected[bin] = 1
      expected[:total] = 1
    end
    expected
  end

  def expect_assignment_breakdown(bin, opts={})
    breakdown = @teacher_analytics.assignments.first[:tardiness_breakdown]
    expected = expected_breakdown(bin)

    if opts.has_key? :total
      expected[:total] = opts[:total]
    end

    breakdown.should == expected
    breakdown
  end

  def expect_summary_breakdown(bin)
    expected = expected_breakdown(bin)
    expected[:total] = 1
    student_summary[:tardiness_breakdown].should == expected
  end

end
