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

# @API Analytics
#
# API for retrieving the data exposed in Canvas Analytics
class AnalyticsApiController < ApplicationController
  include Analytics::Permissions

  # @API Get department-level participation data
  #
  # Returns page view hits summed across all courses in the department. Two
  # groupings of these counts are returned; one by day (+by_date+), the other
  # by category (+by_category+). The possible categories are announcements,
  # assignments, collaborations, conferences, discussions, files, general,
  # grades, groups, modules, other, pages, and quizzes.
  #
  # This and the other department-level endpoints have three variations which
  # all return the same style of data but for different subsets of courses. All
  # share the prefix /api/v1/accounts/<account_id>/analytics. The possible
  # suffixes are:
  #
  #  * /current: includes all available courses in the default term
  #  * /completed: includes all concluded courses in the default term
  #  * /terms/<term_id>: includes all available or concluded courses in the
  #    given term.
  #
  # Courses not yet offered or which have been deleted are never included.
  #
  # /current and /completed are intended for use when the account has only one
  # term. /terms/<term_id> is intended for use when the account has multiple
  # terms.
  #
  # The action follows the suffix.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/current/activity \
  #         -H 'Authorization: Bearer <token>'
  #
  #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/completed/activity \
  #         -H 'Authorization: Bearer <token>'
  #
  #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/terms/<term_id>/activity \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "by_date": {
  #       "2012-01-24": 1240,
  #       "2012-01-27": 912,
  #     },
  #     "by_category": {
  #       "announcements": 54,
  #       "assignments": 256,
  #       "collaborations": 18,
  #       "conferences": 26,
  #       "discussions": 354,
  #       "files": 132,
  #       "general": 59,
  #       "grades": 177,
  #       "groups": 132,
  #       "modules": 71,
  #       "other": 412,
  #       "pages": 105,
  #       "quizzes": 356
  #     },
  #   }
  def department_participation
    return unless require_analytics_for_department
    render :json => {
      :by_date => @department_analytics.participation_by_date,
      :by_category => @department_analytics.participation_by_category
    }
  end

  # @API Get department-level grade data
  #
  # Returns the distribution of grades for students in courses in the
  # department.  Each data point is one student's current grade in one course;
  # if a student is in multiple courses, he contributes one value per course,
  # but if he's enrolled multiple times in the same course (e.g. a lecture
  # section and a lab section), he only constributes on value for that course.
  #
  # Grades are binned to the nearest integer score; anomalous grades outside
  # the 0 to 100 range are ignored. The raw counts are returned, not yet
  # normalized by the total count.
  #
  # Shares the same variations on endpoint as the participation data.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/current/grades \
  #         -H 'Authorization: Bearer <token>'
  #
  #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/completed/grades \
  #         -H 'Authorization: Bearer <token>'
  #
  #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/terms/<term_id>/grades \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "0": 95,
  #     "1": 1,
  #     "2": 0,
  #     "3": 0,
  #     ...
  #     "93": 125,
  #     "94": 110,
  #     "95": 142,
  #     "96": 157,
  #     "97": 116,
  #     "98": 85,
  #     "99": 63,
  #     "100": 190
  #   }
  def department_grades
    return unless require_analytics_for_department
    render :json => @department_analytics.grade_distribution
  end

  # @API Get department-level statistics
  #
  # Returns numeric statistics about the department and term (or filter).
  #
  # Shares the same variations on endpoint as the participation data.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/current/statistics \
  #         -H 'Authorization: Bearer <token>'
  #
  #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/completed/statistics \
  #         -H 'Authorization: Bearer <token>'
  #
  #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/terms/<term_id>/statistics \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "courses": 27,
  #     "subaccounts": 3,
  #     "teachers": 36,
  #     "students": 418,
  #     "discussion_topics": 77,
  #     "media_objects": 219,
  #     "attachments": 1268,
  #     "assignments": 290,
  #   }
  def department_statistics
    return unless require_analytics_for_department
    render :json => @department_analytics.statistics
  end

  # @API Get department-level statistics, broken down by subaccount
   #
   # Returns numeric statistics about the department subaccounts and term (or filter).
   #
   # Shares the same variations on endpoint as the participation data.
   #
   # @example_request
   #
   #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/current/statistics_by_subaccount \
   #         -H 'Authorization: Bearer <token>'
   #
   #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/completed/statistics_by_subaccount \
   #         -H 'Authorization: Bearer <token>'
   #
   #     curl https://<canvas>/api/v1/accounts/<account_id>/analytics/terms/<term_id>/statistics_by_subaccount \
   #         -H 'Authorization: Bearer <token>'
   #
   # @example_response
   #   {"accounts": [
   #     {
   #       "name": "some string",
   #       "id": 188,
   #       "courses": 27,
   #       "teachers": 36,
   #       "students": 418,
   #       "discussion_topics": 77,
   #       "media_objects": 219,
   #       "attachments": 1268,
   #       "assignments": 290,
   #     }
   #   ]}
   def department_statistics_by_subaccount
     return unless require_analytics_for_department
     render :json => {accounts: @department_analytics.statistics_by_subaccount}
   end

  # @API Get course-level participation data
  #
  # Returns page view hits and participation numbers grouped by day through the
  # entire history of the course. Page views is returned as a hash, where the
  # hash keys are dates in the format "YYYY-MM-DD". The page_views result set
  # includes page views broken out by access category. Participations is
  # returned as an array of dates in the format "YYYY-MM-DD".
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/analytics/activity \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   [
  #     { 
  #       "date": "2012-01-24",
  #       "participations": 3,
  #       "views": 10
  #     }
  #   ]
  def course_participation
    return unless require_analytics_for_course
    render :json => @course_analytics.participation
  end

  # @API Get course-level assignment data
  #
  # Returns a list of assignments for the course sorted by due date. For
  # each assignment returns basic assignment information, the grade breakdown,
  # and a breakdown of on-time/late status of homework submissions.
  #
  # @argument async [Boolean]
  #   If async is true, then the course_assignments call can happen asynch-
  #   ronously and MAY return a response containing a progress_url key instead
  #   of an assignments array. If it does, then it is the caller's
  #   responsibility to poll the API again to see if the progress is complete.
  #   If the data is ready (possibly even on the first async call) then it
  #   will be passed back normally, as documented in the example response.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/analytics/assignments \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   [
  #     {
  #       "assignment_id": 1234,
  #       "title": "Assignment 1",
  #       "points_possible": 10,
  #       "due_at": "2012-01-25T22:00:00-07:00",
  #       "unlock_at": "2012-01-20T22:00:00-07:00",
  #       "muted": false,
  #       "min_score": 2,
  #       "max_score": 10,
  #       "median": 7,
  #       "first_quartile": 4,
  #       "third_quartile": 8,
  #       "tardiness_breakdown": {
  #         "on_time": 0.75,
  #         "missing": 0.1,
  #         "late": 0.15
  #       }
  #     },
  #     {
  #       "assignment_id": 1235,
  #       "title": "Assignment 2",
  #       "points_possible": 15,
  #       "due_at": "2012-01-26T22:00:00-07:00",
  #       "unlock_at": null,
  #       "muted": true,
  #       "min_score": 8,
  #       "max_score": 8,
  #       "median": 8,
  #       "first_quartile": 8,
  #       "third_quartile": 8,
  #       "tardiness_breakdown": {
  #         "on_time": 0.65,
  #         "missing": 0.12,
  #         "late": 0.23
  #         "total": 275
  #       }
  #     }
  #   ]
  def course_assignments
    return unless require_analytics_for_course
    permitted_course = Analytics::PermittedCourse.new(@current_user, @course)

    if async_request && !permitted_course.async_data_available?
      progress = permitted_course.progress_for_background_assignments
      render :json => {:progress_url => polymorphic_url([:api_v1, progress])}
      return
    end

    render :json => permitted_course.assignments
  end

  # @API Get course-level student summary data
  #
  # Returns a summary of per-user access information for all students in
  # a course. This includes total page views, total participations, and a
  # breakdown of on-time/late status for all homework submissions in the course.
  #
  # Each student's summary also includes the maximum number of page views and
  # participations by any student in the course, which may be useful for some
  # visualizations (since determining maximums client side can be tricky with
  # pagination).
  #
  # @argument sort_column [String, "name"|"name_descending,"score|"score_descending"|"participations|"participations_descending"|"page_views"|"page_views_descending"]
  #   The order results in which results are returned.  Defaults to "name".
  # @argument student_id If set, returns only the specified student.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/analytics/student_summaries \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   [
  #     {
  #       "id": 2346,
  #       "page_views": 351,
  #       "page_views_level": "1"
  #       "max_page_view": 415,
  #       "participations": 1,
  #       "participations_level": "3",
  #       "max_participations": 10,
  #       "tardiness_breakdown": {
  #         "total": 5,
  #         "on_time": 3,
  #         "late": 0,
  #         "missing": 2,
  #         "floating": 0
  #       }
  #     },
  #     {
  #       "id": 2345,
  #       "page_views": 124,
  #       "participations": 15,
  #       "tardiness_breakdown": {
  #         "total": 5,
  #         "on_time": 1,
  #         "late": 2,
  #         "missing": 3,
  #         "floating": 0
  #       }
  #     }
  #   ]
  def course_student_summaries
    return unless require_analytics_for_course
    return unless authorized_action(@course, @current_user, [:manage_grades, :view_all_grades])
    student_ids = [params[:student_id]] unless params[:student_id].blank?
    summaries = @course_analytics.student_summaries(sort_column: params[:sort_column], student_ids: student_ids)
    render :json => Api.paginate(summaries, self, api_v1_course_student_summaries_url(@course))
  end

  # @API Get user-in-a-course-level participation data
  #
  # Returns page view hits grouped by hour, and participation details through the
  # entire history of the course.
  #
  # `page_views` are returned as a hash, where the keys are iso8601 dates, bucketed by the hour.
  # `participations` are returned as an array of hashes, sorted oldest to newest.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/analytics/users/<user_id>/activity \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "page_views": {
  #       "2012-01-24T13:00:00-00:00": 19,
  #       "2012-01-24T14:00:00-00:00": 13,
  #       "2012-01-27T09:00:00-00:00": 23
  #     },
  #     "participations": [
  #       {
  #         "created_at": "2012-01-21T22:00:00-06:00",
  #         "url": "https://canvas.example.com/path/to/canvas",
  #       },
  #       {
  #         "created_at": "2012-01-27T22:00:00-06:00",
  #         "url": "https://canvas.example.com/path/to/canvas",
  #       }
  #     ]
  #   }
  def student_in_course_participation
    return unless require_analytics_for_student_in_course
    render :json => {
      :page_views => @student_analytics.page_views,
      :participations => @student_analytics.participations
    }
  end

  # @API Get user-in-a-course-level assignment data
  #
  # Returns a list of assignments for the course sorted by due date. For
  # each assignment returns basic assignment information, the grade breakdown
  # (including the student's actual grade), and the basic submission
  # information for the student's submission if it exists.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/analytics/users/<user_id>/assignments \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   [
  #     {
  #       "assignment_id": 1234,
  #       "title": "Assignment 1",
  #       "points_possible": 10,
  #       "due_at": "2012-01-25T22:00:00-07:00",
  #       "unlock_at": "2012-01-20T22:00:00-07:00",
  #       "muted": false,
  #       "min_score": 2,
  #       "max_score": 10,
  #       "median": 7,
  #       "first_quartile": 4,
  #       "third_quartile": 8,
  #       "module_ids": [
  #           1,
  #           2
  #       ],
  #       "submission": {
  #         "submitted_at": "2012-01-22T22:00:00-07:00",
  #         "score": 10
  #       }
  #     },
  #     {
  #       "assignment_id": 1235,
  #       "title": "Assignment 2",
  #       "points_possible": 15,
  #       "due_at": "2012-01-26T22:00:00-07:00",
  #       "unlock_at": null,
  #       "muted": true,
  #       "min_score": 8,
  #       "max_score": 8,
  #       "median": 8,
  #       "first_quartile": 8,
  #       "third_quartile": 8,
  #       "module_ids": [
  #           1
  #       ],
  #       "submission": {
  #         "submitted_at": "2012-01-22T22:00:00-07:00"
  #       }
  #     }
  #   ]
  def student_in_course_assignments
    return unless require_analytics_for_student_in_course
    render :json => @student_analytics.assignments
  end

  # @API Get user-in-a-course-level messaging data
  #
  # Returns messaging "hits" grouped by day through the entire history of the
  # course. Returns a hash containing the number of instructor-to-student messages,
  # and student-to-instructor messages, where the hash keys are dates
  # in the format "YYYY-MM-DD". Message hits include Conversation messages and
  # comments on homework submissions.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/analytics/users/<user_id>/communication \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "2012-01-24":{
  #       "instructorMessages":1,
  #       "studentMessages":2
  #     },
  #     "2012-01-27":{
  #       "studentMessages":1
  #     }
  #   }
  def student_in_course_messaging
    return unless require_analytics_for_student_in_course
    render :json => @student_analytics.messages
  end

  protected

  def async_request
    value_to_boolean(params[:async]) && cache_configured?
  end
end
