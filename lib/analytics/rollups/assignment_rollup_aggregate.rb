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

module Analytics::Rollups
  class AssignmentRollupAggregate
    def initialize(rollups)
      @rollups = rollups
    end

    STABLE_ATTRS = [:assignment_id, :title, :due_at, :muted, :points_possible, :non_digital_submission]

    def data
      return nil if @rollups.blank?
      hash = @rollups.first.data.slice(*STABLE_ATTRS)
      hash.merge!(score_summary)
      hash.merge({:tardiness_breakdown => tardiness_summary})
    end

    def score_summary
      if @rollups.first.points_possible
        buckets = ScoreBuckets.parse(@rollups.first.points_possible, composite_bucket_list)
        {
          :max_score => @rollups.map(&:max_score).compact.max,
          :min_score => @rollups.map(&:min_score).compact.min,
          :first_quartile => buckets.first_quartile,
          :median => buckets.median,
          :third_quartile => buckets.third_quartile,
        }
      else
        Hash.new(0)
      end
    end

    def composite_bucket_list
      @rollups.map{|r| r.score_buckets }.compact.transpose.map(&:sum)
    end

    def tardiness_summary
      total = @rollups.map(&:total_submissions).sum
      missing = @rollups.map(&:unscaled_missing_submissions).sum
      late = @rollups.map(&:unscaled_late_submissions).sum
      on_time = @rollups.map(&:unscaled_on_time_submissions).sum
      if total > 0
        Analytics::TardinessBreakdown.new(missing, late, on_time).as_hash_scaled(total).merge(:total => total)
      else
        {:missing => 0, :late => 0, :on_time => 0, :total => 0}
      end
    end
  end
end
