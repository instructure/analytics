module Analytics
  class TardinessBreakdown
    attr_accessor :missing, :late, :on_time

    def initialize(missing = 0, late = 0, on_time = 0)
      @missing = missing || 0
      @late = late || 0
      @on_time = on_time || 0
    end

    def self.init_with_scope(submission_scope, total)
      counts = submission_scope.group(:cached_tardy_status).count
      late = counts['late']
      on_time = counts['on_time']
      missing = total - counts.values.sum
      self.new(missing, late, on_time)
    end

    def as_hash_scaled(denominator)
      if denominator <= 0
        { :missing => 0, :late => 0, :on_time => 0 }
      else
        {
          :missing => @missing / denominator.to_f,
          :late    => @late    / denominator.to_f,
          :on_time => @on_time / denominator.to_f
        }
      end
    end

    def as_hash
      {
        :missing => @missing,
        :late    => @late,
        :on_time => @on_time
      }
    end
  end
end
