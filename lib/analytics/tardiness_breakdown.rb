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

module Analytics
  class TardinessBreakdown
    # Note: We *think* floating means "future", or "not submitted yet" -- Venk
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
      return if !assignment_submission || assignment_submission.non_digital_submission?

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
