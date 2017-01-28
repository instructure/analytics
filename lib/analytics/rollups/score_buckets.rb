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
  class ScoreBuckets
    # A bucket count of twenty six will cutoff stats buckets in twenty-fifths.
    BUCKET_COUNT = 26
    attr_reader :bucket_size

    def initialize(points_possible)
      unless points_possible
        raise ArgumentError, "Score stats are meaningless without a total point possible"
      end

      @points_possible = points_possible

      if bucket_count <= 1
        @bucket_size = 0
      else
        @bucket_size = points_possible.to_f / (bucket_count - 1)
      end

      @buckets = Array.new([bucket_count, 1].max, 0)
      @counter = ::Stats::Counter.new
    end

    def self.parse(points, bucket_list)
      buckets = self.new(points)
      bucket_list.each_with_index do |count, index|
        value = buckets.bucket_size * index
        count.times { buckets << value }
      end
      buckets
    end

    def <<(value)
      @buckets[index_for(value)] += 1
      @counter << value
      self
    end

    def to_a
      @buckets
    end

    def index_for(value)
      return 0 if @bucket_size == 0 || value <= 0
      return bucket_count - 1 if value >= @points_possible
      # Add 0.5 to "center" the bucket,
      # ie multiples of bucket size should fall on midpoints.
      ((value / @bucket_size) + 0.5).floor
    end

    def max; @counter.max; end
    def min; @counter.min; end
    def first_quartile; @counter.quartiles[0]; end
    def median; @counter.quartiles[1]; end
    def third_quartile; @counter.quartiles[2]; end

    private
    def bucket_count
      @_bucket_count ||= if @points_possible < BUCKET_COUNT
        @points_possible.floor + 1
      else
        BUCKET_COUNT
      end
    end
  end
end
