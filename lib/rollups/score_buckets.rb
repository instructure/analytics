
module Rollups
  class ScoreBuckets
    BUCKET_COUNT = 25
    attr_reader :bucket_size

    def initialize(points_possible)
      unless points_possible
        raise ArgumentError, "Score stats are meaningless without a total point possible"
      end

      @points_possible = points_possible
      if bucket_count <= 0
        @bucket_size = 0
      else
        @bucket_size = points_possible / bucket_count
      end

      @buckets = Array.new([bucket_count,1].max, 0)
      @counter = ::Stats::Counter.new
    end

    def self.parse(points, bucket_list)
      buckets = self.new(points)
      bucket_list.each_with_index do |count, idx|
        value = (buckets.bucket_size * idx) + (buckets.bucket_size / 2)
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
      (value / @bucket_size).floor
    end

    def max; @counter.max; end
    def min; @counter.min; end
    def first_quartile; @counter.quartiles[0]; end
    def median; @counter.quartiles[1]; end
    def third_quartile; @counter.quartiles[2]; end

    private
    def bucket_count
      @_bucket_count ||= if @points_possible <= BUCKET_COUNT
        @points_possible.floor
      else
        BUCKET_COUNT
      end
    end
  end
end
