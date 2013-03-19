module Analytics

  #
  #                  Tardy Logic Table
  #                 ===================
  #                                               (submission)
  #                               +---------------------+---------------+
  #                               |      submitted      | not submitted |
  #                               +----------+----------+---------------+
  #          (assignment)         | NOT LATE |   LATE   |               |
  # +-------------+--------------++==========+==========+===============+
  # |             |   PAST DUE   || :on_time |  :late   |   :missing    |
  # |  scheduled  +--------------++          +----------+---------------+
  # |             | NOT PAST DUE ||                     |               |
  # +-------------+--------------++                     |               |
  # |             |              ||      :on_time       |   :floating   |
  # | unscheduled |              ||                     |               |
  # |             |              ||                     |               |
  # +-------------+--------------++---------------------+---------------+

  class Tardy
    attr_accessor :due_at, :submitted_at

    def initialize(due_at, submitted_at, now=Time.zone.now)
      @decision = nil
      @due_at = due_at
      @submitted_at = submitted_at
      # Useful for unit tests
      @now = now
    end

    def decide
      if submitted?
        if past_due? && submitted_late?
          :late
        else
          :on_time
        end
      else # not submitted
        if past_due?
          :missing
        else
          :floating
        end
      end
    end

    def decision
      @decision ||= decide
    end

    def missing?
      self.decision == :missing
    end

    def late?
      self.decision == :late
    end

    def on_time?
      self.decision == :on_time
    end

    def floating?
      self.decision == :floating
    end

  protected
    def scheduled?
      @due_at.present?
    end

    def past_due?
      scheduled? && @due_at < @now
    end

    def submitted?
      @submitted_at.present?
    end

    def submitted_late?
      submitted? && @submitted_at > @due_at
    end
  end

end
