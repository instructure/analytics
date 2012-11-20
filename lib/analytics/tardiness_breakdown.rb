module Analytics
  class TardinessBreakdown
    attr_reader :missing, :late, :on_time

    def initialize(missing = 0, late = 0, on_time = 0)
      @missing, @late, @on_time = missing, late, on_time
    end

    def as_hash_scaled(denominator)
      {
        :missing => @missing / denominator.to_f,
        :late    => @late    / denominator.to_f,
        :on_time => @on_time / denominator.to_f
      }
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