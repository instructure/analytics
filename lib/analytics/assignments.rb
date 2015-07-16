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

require 'rollups/assignment_rollup_aggregate'

module Analytics
  module Assignments
    # required of host: submissions(assignments)

    SUBMISSION_COLUMNS_SELECT = [:id, :assignment_id, :score, :user_id, :submission_type,
            :submitted_at, :grade, :graded_at, :updated_at, :workflow_state, :cached_due_date]

    def assignments
      cache_array = [:assignments, allow_student_details?]
      cache_array << @current_user if differentiated_assignments_applies?
      slaved(:cache_as => cache_array) do
        assignments = assignment_scope.all
        submissions = submissions(assignments).group_by{ |s| s.assignment_id }
        assignments.map do |assignment|
          assignment_data(assignment, submissions[assignment.id])
        end
      end
    end

    def assignment_rollups_for(section_ids)
      assignments = assignment_scope.all

      @course.shard.activate do
        assignments.map do |assignment|
          # cache at this level, so that we cache for all sections and then
          # pick out the relevant sections from the cache below
          rollups = slaved(:cache_as => [:assignment_rollups, assignment]) do
            AssignmentRollup.build(@course, assignment)
          end
          rollups = rollups.values_at(*section_ids).compact.reject { |r| r.total_submissions.zero? }
          Rollups::AssignmentRollupAggregate.new(rollups).data
        end.compact
      end
    end

    def fake_student_ids
      @fake_student_ids ||= @course.enrollments.where("enrollments.type = 'StudentViewEnrollment'").pluck(:user_id)
    end

    def assignment_scope
      user = @student || @current_user
      @assignment_scope ||= ::Analytics::Assignments.assignment_scope_for(@course, user)
    end

    def self.assignment_scope_for(this_course, user)
      this_course.shard.activate do
        scope = this_course.assignments.published

        if differentiated_assignments_applies?(this_course, user)
          scope = scope.visible_to_students_in_course_with_da(user.id, this_course.id)
        end

        scope.preload(:versions). # Optimizes AssignmentOverrideApplicator
              reorder("assignments.due_at, assignments.id")
      end
    end

    def self.differentiated_assignments_applies?(course, user)
      course.feature_enabled?(:differentiated_assignments) && !course.grants_any_right?(user, :read_as_admin, :manage_grades, :manage_assignments)
    end

    def assignment_data(assignment, submissions)
      submissions ||= []
      real_submissions = submissions.reject{|s| fake_student_ids.include?(s.user_id)}

      hash = basic_assignment_data(assignment, submissions).
        merge(:muted => muted(assignment))

      unless muted(assignment) || suppressed_due_to_few_submissions(real_submissions) || suppressed_due_to_course_setting
        scores = Stats::Counter.new
        (real_submissions || []).each do |submission|
          scores << submission.score if submission.score
        end
        quartiles = scores.quartiles

        hash.merge!(
          :max_score => scores.max,
          :min_score => scores.min,
          :first_quartile => quartiles[0],
          :median => quartiles[1],
          :third_quartile => quartiles[2]
        )
      end

      if self.respond_to?(:extended_assignment_data)
        hash.merge!(extended_assignment_data(assignment, submissions))
      end

      hash
    end

    def basic_assignment_data(assignment, submissions=nil)
      {
        :assignment_id => assignment.id,
        :title => assignment.title,
        :unlock_at => assignment.unlock_at,
        :points_possible => assignment.points_possible,
        :non_digital_submission => assignment.non_digital_submission?,
        :multiple_due_dates => false # can be overridden in submodules
      }
    end

    def differentiated_assignments_applies?
      ::Analytics::Assignments.differentiated_assignments_applies?(@course, @current_user)
    end

    # Mostly for test stubs
    def overridden_assignment(assignment, user)
      assignment.overridden_for(user)
    end

    def muted(assignment)
      !allow_student_details? && assignment.muted?
    end

    def suppressed_due_to_few_submissions(submissions)
      # Need to make sure the submissions are actually submitted.
      !allow_student_details? && submissions.count { |submission|
        submission.has_submission? || submission.graded?
      } < 5
    end

    def suppressed_due_to_course_setting
      !allow_student_details? && @course.settings[:hide_distribution_graphs]
    end
  end
end
