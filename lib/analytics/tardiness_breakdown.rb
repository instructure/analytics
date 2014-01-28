module Analytics
  class TardinessBreakdown
    attr_accessor :missing, :late, :on_time, :floating

    def initialize(missing = 0, late = 0, on_time = 0, floating = 0)
      @missing = missing || 0
      @late = late || 0
      @on_time = on_time || 0
      @floating = floating || 0
    end

    def total
      @missing + @late + @on_time + @floating
    end

    def as_hash_scaled(denominator = nil)
      denominator ||= total
      if denominator <= 0
        { :missing => 0, :late => 0, :on_time => 0, :floating => 0, :total => 0 }
      else
        {
          :missing  => @missing / denominator.to_f,
          :late     => @late    / denominator.to_f,
          :on_time  => @on_time / denominator.to_f,
          :floating => @floating / denominator.to_f,
          :total    => denominator
        }
      end
    end

    def as_hash
      {
        :missing  => @missing,
        :late     => @late,
        :on_time  => @on_time,
        :floating => @floating,
        :total    => total
      }
    end

    def tally!(assignment_submission)
      return unless assignment_submission

      case assignment_submission.status
      when :missing
        @missing += 1
      when :late
        @late += 1
      when :on_time
        @on_time += 1
      when :floating
        @floating += 1
      end
    end
  end
end
