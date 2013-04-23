require File.expand_path('../../lib/analytics/tardiness_breakdown', File.dirname(__FILE__))

class AssignmentRollup < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :course_section

  serialize :score_buckets

  attr_accessible :title, :points_possible, :due_at, :muted
  attr_accessible :total_submissions, :late_submissions, :missing_submissions, :on_time_submissions
  attr_accessible :max_score, :min_score, :first_quartile_score, :median_score, :third_quartile_score, :score_buckets
  attr_accessible :assignment_id, :course_section_id

  def self.init_with_assignment_and_section(assignment, section)
    attrs = {
      :title => assignment.title,
      :points_possible => assignment.points_possible,
      :due_at => assignment.due_at,
      :muted => assignment.muted?
    }
    section_id = section ? section.id : nil
    rollup = self.find_or_initialize_by_assignment_id_and_course_section_id(assignment.id, section_id)
    rollup.attributes = attrs
    rollup
  end

  def self.init(assignment, section, submission_scope, students_count)
    rollup = init_with_assignment_and_section(assignment, section)
    rollup.calculate_scores(assignment.points_possible, submission_scope)

    breakdown = Analytics::TardinessBreakdown.init_with_scope(submission_scope, students_count)
    rollup.calculate_tardiness(breakdown, students_count)

    rollup.save!
    rollup
  end

  def calculate_tardiness(breakdown, count)
    breakdown_data = breakdown.as_hash_scaled(count)
    self.attributes = {
      :total_submissions => count,
      :late_submissions => breakdown_data[:late],
      :missing_submissions => breakdown_data[:missing],
      :on_time_submissions => breakdown_data[:on_time]
    }
  end

  def calculate_scores(points_possible, submission_scope)
    if points_possible
      buckets = Rollups::ScoreBuckets.new(points_possible)
      submission_scope.select('submissions.score').find_each do |submission|
        buckets << submission.score if submission.score
      end
      self.attributes = {
        :max_score => buckets.max,
        :min_score => buckets.min,
        :first_quartile_score => buckets.first_quartile,
        :median_score => buckets.median,
        :third_quartile_score => buckets.third_quartile,
        :score_buckets => buckets.to_a
      }
    end
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

  def to_json(options={})
    data.to_json
  end
end
