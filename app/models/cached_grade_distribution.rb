class CachedGradeDistribution < ActiveRecord::Base
  attr_accessible

  def self.primary_key
    :course_id
  end

  belongs_to :course

  def recalculate!
    Enrollment.send :with_exclusive_scope do
      reset_score_counts 
      grade_distribution_rows.each do |row|
        update_score( row[1].to_i, row[0].to_i )
      end
    end
    save
  end

  private

  def reset_score_counts
    (0..100).each{ |score| update_score(score, 0) }
  end

  def update_score(score, value)
    # ignore anomalous scores, we don't have columns for it
    return unless 0 <= score && score <= 100
    send("s#{score}=", value)
  end

  def grade_distribution_rows
    grade_distribution_sql = course.all_student_enrollments.
      select("COUNT(DISTINCT user_id) AS user_count, ROUND(computed_current_score) AS score").
      where(:type => 'StudentEnrollment', :workflow_state => ['active', 'completed']).
      group("ROUND(computed_current_score)").
      to_sql
      
    self.class.connection.select_rows(grade_distribution_sql)
  end
end
