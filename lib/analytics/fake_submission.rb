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

# standin for a Submission object that's much cheaper to instantiate, for use
# in Analytics::Course#tardiness_breakdowns.
#
# in addition to the fields for the Submission::Tardiness contract,
# Analytics::AssignmentSubmission also needs a graded_at (Time) attribute.
#
# finally, Analytics::Course#tardiness_breakdown also requires assignment_id
# (Integer) and user_id (Integer).
module Analytics
  class FakeSubmission
    attr_accessor :assignment
    attr_reader   :assignment_id, :user_id, :score, :submission_type,
                  :workflow_state, :excused, :submitted_at, :cached_due_date,
                  :graded_at

    include Submission::Tardiness

    def initialize(data)
      @assignment_id   = data['assignment_id']   && data['assignment_id'].to_i
      @user_id         = data['user_id']         && data['user_id'].to_i
      @score           = data['score']           && data['score'].to_i
      @excused         = data['excused']
      @submission_type = data['submission_type']
      @workflow_state  = data['workflow_state']

      # Time.zone.parse would be more correct here, but that's significantly
      # more expensive (and this is used in a tight loop that may have very
      # many instances).
      #
      # the strings in these fields come from the database where they lack time
      # zone information but are guaranteed to actually mean UTC. we add the
      # zulu marker before using Time.parse to make sure they're correctly
      # interpreted regardless of the system time zone
      @submitted_at    = data['submitted_at']    && Time.parse(data['submitted_at'] + 'Z')
      @graded_at       = data['graded_at']       && Time.parse(data['graded_at'] + 'Z')
      @cached_due_date = data['cached_due_date'] && Time.parse(data['cached_due_date'] + 'Z')
    end

    def self.from_scope(scope)
      ActiveRecord::Base.connection.select_all(scope).map{ |data| self.new(data) }
    end
  end
end
