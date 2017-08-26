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

class Analytics::AssignmentRollup
  attr_accessor :title, :points_possible, :due_at, :muted
  attr_accessor :total_submissions, :late_submissions, :missing_submissions, :on_time_submissions
  attr_accessor :max_score, :min_score, :first_quartile_score, :median_score, :third_quartile_score, :score_buckets, :non_digital_submission
  attr_accessor :assignment_id, :course_section_id
  attr_accessor :tardiness_breakdown, :buckets

  def initialize(attrs = {})
    attrs.each { |k,v| self.send("#{k}=", v) }
  end

  def self.init_rollup(assignment)
    new.tap do |rollup|
      rollup.assignment_id       = assignment.id
      rollup.title               = assignment.title
      rollup.points_possible     = assignment.points_possible
      rollup.due_at              = assignment.due_at
      rollup.muted               = assignment.muted?
      rollup.non_digital_submission  = assignment.non_digital_submission?
      rollup.total_submissions   = 0
      rollup.missing_submissions = 0
      rollup.late_submissions    = 0
      rollup.on_time_submissions = 0
      rollup.tardiness_breakdown = Analytics::TardinessBreakdown.new()
      if assignment.points_possible
        rollup.buckets = Analytics::Rollups::ScoreBuckets.new(assignment.points_possible)
      end
    end
  end

  def self.init(assignment, enrollments_scope)
    stats_by_section = Hash.new { |h,section_id| h[section_id] = init_rollup(assignment) }

    enrollments_with_submissions_scope(assignment, enrollments_scope).find_each do |submission|
      # weird object here - submission is actually an Enrollment, but with a
      # nasty manual join and a bunch of submission data (readonly of course)
      #
      # enrollments *should* always have a section, but this is a cheap guard
      # against bad data
      if submission.course_section_id
        section_rollup = stats_by_section[submission.course_section_id.to_i]
        section_rollup.update_stats(assignment, submission)
      end
    end

    stats_by_section.each do |section_id, rollup|
      rollup.calculate(assignment)
    end

    # make a new hash here to remove the default value block
    Hash[stats_by_section]
  end

  def self.build(course, assignment)
    # explicitly give the :type here, because student_enrollments scope also
    # includes StudentViewEnrollment which we want to exclude
    enrollments_scope = course.enrollments.where(workflow_state: %w[active completed], type: 'StudentEnrollment').except(:preload)
    self.init(assignment, enrollments_scope)
  end

  def self.enrollments_with_submissions_scope(assignment, enrollments_scope)
    enrollments_scope
      .joins("LEFT JOIN #{Submission.quoted_table_name} ON submissions.user_id = enrollments.user_id
              AND submissions.assignment_id = #{assignment.id} AND submissions.workflow_state <> 'deleted'")
      .select("enrollments.id,
               enrollments.user_id,
               enrollments.course_id,
               enrollments.course_section_id,
               submissions.id as submission_id,
               submissions.score,
               submissions.cached_due_date,
               submissions.submitted_at,
               submissions.submission_type,
               submissions.graded_at,
               submissions.workflow_state")
  end

  def submission_from(assignment, enrollment_and_submission)
    # convert submission columns from Enrollment into FakeSubmission so we can
    # use it for an AssignmentSubmission
    if enrollment_and_submission.submission_id
      submission = Analytics::FakeSubmission.new(enrollment_and_submission.attributes)
      submission.assignment = assignment
      submission
    else
      nil
    end
  end

  def update_stats(assignment, enrollment_and_submission)
    self.total_submissions += 1

    submission = submission_from(assignment, enrollment_and_submission)
    assignment_submission = Analytics::AssignmentSubmission.new(assignment, submission)
    self.tardiness_breakdown.tally!(assignment_submission)

    if self.buckets && score = assignment_submission.score
      self.buckets << score
    end
  end

  def calculate(assignment)
    tardiness                = self.tardiness_breakdown.as_hash_scaled(self.total_submissions)
    self.missing_submissions = tardiness[:missing]
    self.late_submissions    = tardiness[:late]
    self.on_time_submissions = tardiness[:on_time]
    if self.buckets
      self.max_score            = buckets.max
      self.min_score            = buckets.min
      self.first_quartile_score = buckets.first_quartile
      self.median_score         = buckets.median
      self.third_quartile_score = buckets.third_quartile
      self.score_buckets        = buckets.to_a
    end
    # remove this in-progress data so it doesn't take up cache space
    self.tardiness_breakdown = self.buckets = nil
  end

  def data
    {
      :assignment_id => assignment_id,
      :title => title,
      :due_at => due_at,
      :muted => muted,
      :first_quartile => first_quartile_score,
      :max_score => max_score,
      :median => median_score,
      :min_score => min_score,
      :points_possible => points_possible,
      :third_quartile => third_quartile_score,
      :non_digital_submission  => non_digital_submission,
      :tardiness_breakdown => {
        :late => late_submissions,
        :missing => missing_submissions,
        :on_time => on_time_submissions,
        :total => total_submissions
      }
    }
  end

  [:late, :missing, :on_time].each do |submission_type|
    base_method_name = "#{submission_type}_submissions".to_sym
    define_method "unscaled_#{base_method_name}".to_sym do
      send(base_method_name) * total_submissions
    end
  end

  def as_json(options={})
    data
  end
end
