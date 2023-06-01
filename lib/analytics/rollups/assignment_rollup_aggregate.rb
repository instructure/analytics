# frozen_string_literal: true

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

    STABLE_ATTRS = %i[assignment_id title due_at muted points_possible non_digital_submission].freeze

    def data
      return nil if @rollups.blank?

      hash = @rollups.first.data.slice(*STABLE_ATTRS)
      hash.merge!(score_summary)
      hash.merge({ tardiness_breakdown: tardiness_summary })
    end

    def score_summary
      if @rollups.first.points_possible
        buckets = ScoreBuckets.parse(@rollups.first.points_possible, composite_bucket_list)
        {
          max_score: @rollups.filter_map(&:max_score).max,
          min_score: @rollups.filter_map(&:min_score).min,
          first_quartile: buckets.first_quartile,
          median: buckets.median,
          third_quartile: buckets.third_quartile,
        }
      else
        Hash.new(0)
      end
    end

    def composite_bucket_list
      @rollups.filter_map(&:score_buckets).transpose.map(&:sum)
    end

    def tardiness_summary
      total = @rollups.sum(&:total_submissions)
      missing = @rollups.sum(&:unscaled_missing_submissions)
      late = @rollups.sum(&:unscaled_late_submissions)
      on_time = @rollups.sum(&:unscaled_on_time_submissions)
      if total > 0
        Analytics::TardinessBreakdown.new(missing, late, on_time).as_hash_scaled(total).merge(total:)
      else
        { missing: 0, late: 0, on_time: 0, total: 0 }
      end
    end
  end
end
