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
  class StudentInCourse < Analytics::Base
    def self.available_for?(current_user, course, student)
      new(current_user, course, student).available?
    end

    def initialize(current_user, course, student)
      super(current_user)
      @course = course
      @student = student
    end

    def available?
      enrollment.present?
    end

    def enrollment
      # not slaved or cached because it's pretty lightweight, we don't want
      # it to depend on the slave being present, and the result depends on
      # @current_user
      enrollment_scope.first
    end

    # just parrots back @student, but sets the computed_current_score from the
    # enrollment on the student, for parity with Analytics::Course.students
    def student
      unless @student.computed_current_score
        @student.computed_current_score = enrollment.computed_current_score
      end
      @student
    end

    def start_date
      # TODO the javascript will break if this comes back nil, so we need a
      # sensible default. using "now" for the time being, but there's gotta be
      # something better
      slaved(:cache_as => :start_date) do
        enrollment.effective_start_at || Time.zone.now
      end
    end

    def end_date
      # TODO ditto. "now" makes more sense this time, but it could also make
      # sense to go past "now" if the course has assignments due in the future,
      # for instance.
      slaved(:cache_as => :end_date) do
        enrollment.effective_end_at || Time.zone.now
      end
    end

    include Analytics::Assignments

    def page_views
      slaved(:cache_as => :page_views) do
        # convert non-string keys from time objects to iso8601 strings since we
        # don't want to use Time#to_s on the keys in Hash#to_json
        buckets = {}
        PageView.counters_by_context_and_hour(@course, @student).each do |bucket,count|
          bucket = bucket.is_a?(String) ? bucket : bucket.in_time_zone.iso8601
          buckets[bucket] = count
        end
        buckets
      end
    end

    def participations
      slaved(:cache_as => :participations) do
        PageView.participations_for_context(@course, @student)
      end
    end

    def messages
      # count up the messages from those conversations authored by the student
      # or by an instructor, binned by day and whether it was the student or an
      # instructor that sent it
      slaved(:cache_as => :messages) do
        messages = {}
        unless shared_conversation_ids.empty?
          # TODO sharding
          ConversationMessage.
            where(:conversation_id => shared_conversation_ids).
            where(:author_id => [@student, *instructors]).
            select("DATE(created_at) AS day, author_id=#{@student.id} AS student, COUNT(*) AS ct").
            group("DATE(created_at), author_id").each do |row|

            day = row.day
            type = Canvas::Plugin.value_to_boolean(row.student) ?
              :studentMessages :
              :instructorMessages
            count = row.ct.to_i

            messages[day] ||= {}
            messages[day][type] = count
          end
        end
        messages
      end
    end

    def my_submission(submissions)
      submissions.detect{ |s| s.user_id == @student.id }
    end

    # Overriding this from Assignments to account for Variable Due Dates
    def basic_assignment_data(assignment, submissions=nil)
      s = my_submission(submissions) if submissions
      assignment_submission = AssignmentSubmission.new(assignment, s)
      super.merge(
        :due_at => assignment_submission.due_at,
        :status => assignment_submission.status
      )
    end

    def extended_assignment_data(assignment, submissions)
      if s = my_submission(submissions)
        assignment_submission = AssignmentSubmission.new(assignment, s)
        if s.excused?
          return {:excused => true}
        else
          return {
            :excused => false,
            :submission => {
              :score => muted(assignment) ? nil : s.score,
              :submitted_at => assignment_submission.recorded_at
            }
          }
        end
      else
        return {}
      end
    end

    def allow_student_details?
      @course.grants_any_right?(@current_user, :manage_grades, :view_all_grades)
    end

  private

    def cache_prefix
      [@course, @student]
    end

    def enrollment_scope
      @enrollment_scope ||= @course.apply_enrollment_visibility(@course.all_student_enrollments, @current_user).
        where(:workflow_state => ['active', 'completed'], :user_id => @student)
    end

    def submissions(assignments)
      @course.shard.activate do
        Submission.
          select(Analytics::Assignments::SUBMISSION_COLUMNS_SELECT).
          where(:assignment_id => assignments).to_a
      end
    end

    def instructors
      @instructors ||= @course.instructors.restrict_to_sections([enrollment.course_section_id]).except(:select).select("users.id").to_a
    end

    def student_conversation_ids
      # conversations related to this course in which the student has a hook
      # TODO: sharding
      @student_conversation_ids ||= ConversationParticipant.
        joins(:conversation).
        where(Conversation.wildcard('conversations.tags', "course_#{@course.id}", :delimiter => ',')).
        where(:user_id => @student).
        select(:conversation_id).
        distinct.
        map(&:conversation_id)
    end

    def shared_conversation_ids
      # subset of student conversations in which a course instructor also has a
      # hook
      return {} if student_conversation_ids.empty?
      # TODO: sharding
      @shared_conversation_ids ||= ConversationParticipant.
        where(:user_id => instructors).
        where(:conversation_id => student_conversation_ids).
        select(:conversation_id).
        distinct.
        map(&:conversation_id)
    end
  end
end
