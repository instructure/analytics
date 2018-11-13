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

class CachedGradeDistribution < ActiveRecord::Base
  def self.primary_key
    :course_id
  end

  belongs_to :course

  def recalculate!
    Enrollment.unscoped do
      reset_score_counts
      grade_distribution_rows.each do |row|
        update_score( row[1].to_i, row[0].to_i )
      end
    end
    save if changed?
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
    self.shard.activate do
      Shackles.activate(:slave) do
        grade_distribution_sql = course.all_real_student_enrollments.
          joins("LEFT JOIN #{Score.quoted_table_name} scores on
              scores.enrollment_id = enrollments.id AND
              scores.grading_period_id IS NULL AND
              scores.workflow_state <> 'deleted'").
          select("COUNT(DISTINCT user_id) AS user_count, ROUND(scores.current_score) AS score").
          where(workflow_state: [:active, :completed]).
          group('score').
          to_sql

        self.class.connection.select_rows(grade_distribution_sql)
      end
    end
  end
end
