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

require_relative '../../../../../spec/sharding_spec_helper'
require_relative '../spec_helper'
require_relative '../cassandra_spec_helper'

describe Analytics::Course do
  before :each do
    # set @course, @teacher, @teacher_enrollment
    course_shim(:active_course => true)
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
          assignment.reload
          expect(assignment.multiple_due_dates_apply_to?(@teacher)).to be_truthy
          analytics = Analytics::Course.new(@teacher, @course)
          data = analytics.basic_assignment_data(assignment)
          expect(data[:multiple_due_dates]).to be_truthy
        end
      end
      describe "when viewed by a student" do
        it "multiple_due_dates flag is false" do
          assignment.reload
          expect(assignment.multiple_due_dates_apply_to?(@student)).to be_falsey
          analytics = Analytics::Course.new(@student, @course)
          data = analytics.basic_assignment_data(assignment)
          expect(data[:multiple_due_dates]).to be_falsey
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
        expect(@teacher_analytics).to receive(:student_scope).never
        @teacher_analytics.students
      end
    end

    it "should not use the same cache for users with the same visibility but different details" do
      enable_cache do
        # while the permissions are ok, they should match
        @teacher_analytics.assignments
        assignment_scope_allowed = false
        allow(@ta_analytics).to receive(:assignment_scope).and_wrap_original do |original|
          raise "Should not be called" unless assignment_scope_allowed
          original.call
        end
        @ta_analytics.assignments

        # when permissions differ, the ta should get a different value
        allow(@course).to receive(:grants_any_right?).and_return(false)
        assignment_scope_allowed = true
        scope = @ta_analytics.assignment_scope
        expect(@ta_analytics).to receive(:assignment_scope).and_return(scope)
        @ta_analytics.assignments

        # when permissions are the same again, they should still be the same
        # original cache
        assignment_scope_allowed = false
        @ta_analytics.assignments

        # when permissions differ again, the previous different value should
        # have been cached and now reused
        allow(@course).to receive(:grants_any_right?).and_return(false)
        @ta_analytics.assignments
      end
    end

    it "should not use the same cache for users with different visibility" do
      @ta_enrollment.limit_privileges_to_course_section = true
      @ta_enrollment.save!

      enable_cache do
        expect(@ta_analytics.students.object_id).not_to eq @teacher_analytics.students.object_id
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
        expect(@teacher_analytics.participation).not_to be_empty
      end

      it "should include teacher's page views in the course" do
        page_view(:user => @teacher, :course => @course)
        expect(@teacher_analytics.participation).not_to be_empty
      end

      it "should not include student's page views from outside the course" do
        @other_course = course_shim(:active_course => true)
        page_view(:user => @student, :course => @other_course)
        expect(@teacher_analytics.participation).to be_empty
      end
    end

    describe '#page_views_by_student' do
      it 'delegates to the PageView' do
        allow(PageView).to receive_messages(:counters_by_context_for_users => { 1 => 2 } )
        expect(@teacher_analytics.page_views_by_student).to eq({ 1 => 2 })
      end

      it 'passes the course and students array to the page view' do
        expect(PageView).to receive(:counters_by_context_for_users).with(@course, @teacher_analytics.students).and_return(nil)
        @teacher_analytics.page_views_by_student
      end
    end
  end

  describe "#enrollments" do
    it "should not include non-student enrollments from the course" do
      expect(@teacher_analytics.enrollments).not_to include(@teacher_enrollment)
    end

    it "should include active student enrollments from the course" do
      active_student
      expect(@teacher_analytics.enrollments).to include(@student_enrollment)
    end

    it "should include completed student enrollments from the course" do
      completed_student
      expect(@teacher_analytics.enrollments).to include(@student_enrollment)
    end

    it "should not include invited student enrollments from the course" do
      invited_student
      expect(@teacher_analytics.enrollments).not_to include(@student_enrollment)
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
        expect(@ta_analytics.enrollments).to include(@student_enrollment)
      end

      it "should not include enrollments from other sections" do
        active_student(:section => @sectionA)
        expect(@ta_analytics.enrollments).not_to include(@student_enrollment)
      end
    end
  end

  describe "#available_for?(user, course)" do
    it "should be true with an active enrollment in the course" do
      active_student
      expect(Analytics::Course.available_for?(@teacher, @course)).to be_truthy
    end

    it "should be true with a completed enrollment in the course" do
      completed_student
      expect(Analytics::Course.available_for?(@teacher, @course)).to be_truthy
    end

    it "should be false with only invited enrollments in the course" do
      invited_student
      expect(Analytics::Course.available_for?(@teacher, @course)).to be_falsey
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
        expect(Analytics::Course.available_for?(@ta, @course)).to be_truthy
      end

      it "should be false with no enrollments in the user's section" do
        active_student(:section => @sectionA)
        expect(Analytics::Course.available_for?(@ta, @course)).to be_falsey
      end
    end
  end

  describe "#available?" do
    it "should be true with an active enrollment in the course" do
      active_student
      expect(@teacher_analytics).to be_available
    end

    it "should be true with a completed enrollment in the course" do
      completed_student
      expect(@teacher_analytics).to be_available
    end

    it "should be false with only invited enrollments in the course" do
      invited_student
      expect(@teacher_analytics).not_to be_available
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
        expect(@ta_analytics).to be_available
      end

      it "should be false with no enrollments in the user's section" do
        active_student(:section => @sectionA)
        expect(@ta_analytics).not_to be_available
      end
    end
  end

  describe "#start_date" do
    it "should be the earliest effective_start_at of any of Analytics::Course#enrollments" do
      dates = [ 1.day.ago, 5.days.ago, 3.days.ago ]
      dates.each{ |d| e = active_student; e.update_attribute(:start_at, d) }

      expect(@teacher_analytics.start_date).to eq dates.min
    end

    it "should not be nil even if none of the enrollments have an effective_start_at" do
      dates = [nil, nil, nil]
      dates.each{ active_student }

      expect(@teacher_analytics.start_date).not_to be_nil
    end
  end

  describe "#end_date" do
    it "should be the latest effective_end_at of any of Analytics::Course#enrollments" do
      dates = [ 1.day.from_now, 5.days.from_now, 3.days.from_now ]
      dates.each{ |d| e = active_student; e.update_attribute(:end_at, d) }

      expect(@teacher_analytics.end_date).to eq dates.max
    end

    it "should be 'now' if none of the enrollments have an effective_end_at" do
      dates = [ nil, nil, nil ]
      dates.each{ active_student }
      @teacher_analytics.enrollments.zip(dates).each{ |e,date| allow(e).to receive(:effective_end_at).and_return(date) }

      expect(@teacher_analytics.end_date).not_to be_nil
    end
  end

  describe "#students" do
    it "should include all students with an enrollment in Analytics::Course#enrollments" do
      student_ids = []
      3.times do
        active_student
        student_ids << @student.id
      end

      expect(@teacher_analytics.students.map{ |s| s.id }.sort).to eq student_ids.sort
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
      expect(@teacher_analytics.enrollments.size).to eq 2
      expect(@teacher_analytics.students.map{ |s| s.id }).to eq [ @student.id ]
    end

    context "sharding" do
      specs_require_sharding

      it "should work with the correct shard" do
        allow(ActiveRecord::Base.connection).to receive(:use_qualified_names?).and_return(true)
        active_student

        @shard1.activate do
          expect(@teacher_analytics.students.map{ |s| s.id }).to eq [@student.id]

          @other_student = User.create!
          @course.enroll_student(@other_student).accept!
        end
        expect(@teacher_analytics.student_scope.where(:id => [@student.id, @other_student.id]).to_a).to match_array([@student, @other_student])
      end
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
          @assignment.submissions.find_or_create_by!(user: @student).update! score: i
        end

        expect(@teacher_analytics.assignments.first[:min_score]).to eq 0
        expect(@teacher_analytics.assignments.first[:first_quartile]).to eq 0.5
        expect(@teacher_analytics.assignments.first[:median]).to eq 2
        expect(@teacher_analytics.assignments.first[:third_quartile]).to eq 3.5
        expect(@teacher_analytics.assignments.first[:max_score]).to eq 4
      end

      it "should not include non-student's submissions in the course" do
        @assignment.submissions.find_or_create_by!(user: @teacher)
        expect(@teacher_analytics.assignments.first[:min_score]).to be_nil
      end

      it "should not include student's submissions from outside the course" do
        active_student

        # enroll the student in another course and create a submission there
        @other_course = course_shim(:active_course => true)
        course_with_student(:course => @other_course, :user => @student, :active_enrollment => true)
        @other_assignment = @other_course.assignments.active.create!
        @other_assignment.submissions.find_or_create_by!(user: @student).update! score: 1

        expect(@teacher_analytics.assignments.first[:min_score]).to be_nil
      end
    end
  end

  describe "student_scope" do
    it "includes only course_score, not assignment group scores" do
      active_student

      ag = @course.assignment_groups.create! :name => '1'
      assign = @course.assignments.create! :title => '1', :assignment_group => ag, :points_possible => 100
      @submission = assign.submissions.find_or_create_by!(user: @student)
      submit_submission
      grade_submission

      ca = Analytics::Course.new(@teacher, @course)
      expect(ca.student_scope.to_a.map(&:id)).to eq([@student.id])
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
          expect(student_summary[:page_views]).to eq 1
        end

        it "should count participations for that student" do
          view = page_view(:user => @student, :course => @course, :participated => true)
          expect(student_summary[:participations]).to eq 1
        end

        context "levels" do
          before :each do
            @student1 = @student
            @student2 = active_student.user
            @student3 = active_student.user
          end

          it "returns 'level' for page_views / participation" do
            page_view(:user => @student1, :course => @course, :participated => true)
            3.times { page_view(user: @student2, course: @course, participated: true) }
            2.times { page_view(user: @student2, course: @course, participated: false) }
            summaries = @teacher_analytics.student_summaries.paginate(per_page: 100)
            levels = summaries.index_by { |x| x[:id] }

            expect(levels[@student1.id][:page_views_level]).to eq 2
            expect(levels[@student2.id][:page_views_level]).to eq 3
            expect(levels[@student3.id][:page_views_level]).to eq 0

            expect(levels[@student1.id][:participations_level]).to eq 2
            expect(levels[@student2.id][:participations_level]).to eq 3
            expect(levels[@student3.id][:participations_level]).to eq 0
          end
        end

        it "can return results for specific students", priority: "1", test_id: 2997780 do
          student1 = @student
          student2 = active_student(name: "Student2").user
          summaries = @teacher_analytics.
            student_summaries(student_ids: [student2.id]).
            paginate(per_page: 100)
          expect(summaries.size).to eq 1
          expect(summaries.first[:id]).to eq student2.id
        end

        it "should be able to sort by page view even with superfluous counts" do
          old_page_view_counts = @teacher_analytics.page_views_by_student
          allow(@teacher_analytics).to receive(:page_views_by_student).
            and_return(old_page_view_counts.merge(user_factory.id => {:page_views => 0, :participations => 0}))
          result = @teacher_analytics.student_summaries(sort_column: "page_views_ascending").paginate(:page => 1, :per_page => 2).first
          expect(result[:id]).to eq @student.id
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

  describe ":tardiness_breakdown" do
    before :each do
      active_student(:name => 'Student1')
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
    end

    it "should include the number of assignments" do
      5.times{ @course.assignments.active.create!(:submission_types => "online", :grading_type => "percent") }
      expect(student_summary[:tardiness_breakdown][:total]).to eq 5
    end

    it "should have appropriate data per student" do
      @student1 = @student
      active_student(:name => 'Student2')
      @student2 = @student

      @assignment = @course.assignments.active.create!(:due_at => 1.day.ago, :submission_types => "online", :grading_type => "percent")
      @submission1 = @assignment.submissions.find_or_create_by!(user: @student1)
      @submission2 = @assignment.submissions.find_or_create_by!(user: @student2)

      submit_submission(:submission => @submission1, :submitted_at => @assignment.due_at - 1.day)
      submit_submission(:submission => @submission2, :submitted_at => @assignment.due_at + 1.day)

      @summaries = @teacher_analytics.student_summaries.paginate(:page => 1, :per_page => 2)
      expect(@summaries.detect{|s| s[:id] == @submission1.user_id}[:tardiness_breakdown]).to eq expected_breakdown(:on_time)
      expect(@summaries.detect{|s| s[:id] == @submission2.user_id}[:tardiness_breakdown]).to eq expected_breakdown(:late)
    end

    context "an assignment that has a due date" do
      before :each do
        @assignment = @course.assignments.active.create!(:submission_types => "online", :grading_type => "percent")
        @submission = @assignment.submissions.find_or_create_by!(user: @student)

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

          expect_assignment_breakdown(:on_time)
          expect_summary_breakdown(:on_time)
        end

        it "should count as late if submitted after the due date" do
          @submission.submitted_at = @assignment.due_at + 1.day
          @submission.save!

          expect_assignment_breakdown(:late)
          expect_summary_breakdown(:late)
        end
      end

      context "when the student hasn't submitted anything but was graded" do
        before :each do
          grade_submission
        end

        context "when the assignment does not expect a submission" do
          before :each do
            @assignment.submission_types = 'none'
            @assignment.save!
          end

          it "should not be included even when graded" do
            @submission.graded_at = @assignment.due_at - 1.day
            @submission.save!

            expect_assignment_breakdown(:none)
            expect_summary_breakdown(:none)
          end

          it "should not be included, even when graded as a zero" do
            @submission.score = 0
            @submission.save!

            expect_assignment_breakdown(:none)
            expect_summary_breakdown(:none)
          end
        end

        context "when the assignment expects an online submission" do
          before :each do
            @assignment.submission_types = 'online_text_entry'
            @assignment.save!
          end

          it "should count only when submitted" do
            @submission.graded_at = @assignment.due_at + 1.day
            @submission.save!

            expect_assignment_breakdown(:missing)
            expect_summary_breakdown(:missing)
          end
        end
      end

      context "when the student hasn't submitted anything nor been graded" do
        it "should count as missing if the due date is in the past" do
          @assignment.due_at = 1.day.ago
          @assignment.save!

          expect_assignment_breakdown(:missing)
          expect_summary_breakdown(:missing)
        end

        it "should not count if the due date is in the future" do
          @assignment.due_at = 1.day.from_now
          @assignment.save!

          expect_assignment_breakdown(:floating, :total => 1)
          expect_summary_breakdown(:floating)
        end
      end
    end

    context "an assignment that has no due date" do
      before :each do
        @assignment = @course.assignments.active.create!(:submission_types => "online", :grading_type => "percent")
        @submission = @assignment.submissions.find_or_create_by!(user: @student)
      end

      context "when the assignment expects a submission" do
        it "should count as on time when the student submitted something" do
          submit_submission(:submitted_at => 1.day.ago)
          expect_assignment_breakdown(:on_time)
          expect_summary_breakdown(:on_time)
        end

        it "should count as a floating submission when the student hasn't submitted anything but has been graded" do
          grade_submission
          expect_assignment_breakdown(:floating)
          expect_summary_breakdown(:floating)
        end
      end

      context "when the assignment does not expect a submission" do
        before :each do
          @assignment.submission_types = "none"
          @assignment.save!
        end

        it "should not be included by default" do
          expect_assignment_breakdown(:none)
          expect_summary_breakdown(:none)
        end

        it "should not be included, even with a graded submission" do
          grade_submission
          expect_assignment_breakdown(:none)
          expect_summary_breakdown(:none)
        end

        it "should not be included, even with a score of zero" do
          @submission.score = 0
          @submission.save!

          expect_assignment_breakdown(:none)
          expect_summary_breakdown(:none)
        end
      end
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
    @submission.grader = @teacher
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
    expected = { :on_time => 0, :late => 0, :missing => 0, :floating => 0, :total => 0 }
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

    expect(breakdown).to eq expected
    breakdown
  end

  def expect_summary_breakdown(bin)
    expected = expected_breakdown(bin)
    expect(student_summary[:tardiness_breakdown]).to eq expected
  end

end
