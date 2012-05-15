class CachedGradeDistribution < ActiveRecord::Base
  attr_accessible

  def self.primary_key
    :course_id
  end

  belongs_to :course

  def recalculate!
    Enrollment.send :with_exclusive_scope do
      # only look at active or completed enrollments for real students
      valid_student_enrollments = course.all_student_enrollments.
        scoped(:conditions => { :type => 'StudentEnrollment', :workflow_state => ['active', 'completed'] })

      # count up how many students got each integer score from 0 to 100
      (0..100).each{ |score| update_score(score, 0) }
      valid_student_enrollments.find(:all,
        :select => 'COUNT(DISTINCT user_id) AS ct, ROUND(computed_current_score) AS score',
        :group => 'ROUND(computed_current_score)').each do |row|
        update_score(row.score.to_i, row.ct.to_i)
      end
    end

    save
  end

  private
  def update_score(score, value)
    # ignore anomalous scores, we don't have columns for it
    return unless 0 <= score && score <= 100
    send("s#{score}=", value)
  end
end
