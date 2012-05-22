# @API Analytics
#
# API for retrieving the data exposed in Canvas Analytics
class AnalyticsApiController < ApplicationController
  unloadable

  include AnalyticsPermissions

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
  #     curl https://<canvas>/api/v1/analytics/participation/courses/<course_id> \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "page_views": {
  #       "2012-01-24": {
  #         "general": 200,
  #         "grades": 25,
  #         "files": 5,
  #         "other": 10
  #       },
  #       "2012-01-27": {
  #         "general": 251,
  #         "assignments": 55,
  #         "pages": 6
  #       }
  #     },
  #     "participations": [
  #       "2012-01-21",
  #       "2012-01-27"
  #     ]
  #   }
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
  # @example_request
  #
  #     curl https://<canvas>/api/v1/analytics/assignments/courses/<course_id> \ 
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
  #       }
  #     }
  #   ]
  def course_assignments
    return unless require_analytics_for_course
    render :json => @course_analytics.assignments
  end

  # @API Get course-level student summary data
  #
  # Returns a summary of per-user access information for all students in
  # a course. This includes total page views, total participations, and a
  # breakdown of on-time/late status for all homework submissions in the course.
  # The data is returned as a hash where the keys are student ids.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/analytics/student_summaries/courses/<course_id> \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "2345": {
  #       "page_views": 351,
  #       "participations": 1,
  #       "tardiness_breakdown": {
  #         "total": 5,
  #         "on_time": 3,
  #         "late": 0,
  #         "missing": 2
  #       }
  #     },
  #     "2346": {
  #       "page_views": 124,
  #       "participations": 15,
  #       "tardiness_breakdown": {
  #         "total": 5,
  #         "on_time": 1,
  #         "late": 2,
  #         "missing": 3
  #       }
  #     }
  #   }
  def course_student_summaries
    return unless require_analytics_for_course
    render :json => @course_analytics.student_summaries
  end

  # @API Get user-in-a-course-level participation data
  #
  # Returns page view hits and participation numbers grouped by day through the
  # entire history of the course. Two hashes are returned, one for page views
  # and one for participations, where the hash keys are dates in the format
  # "YYYY-MM-DD".
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/analytics/participation/courses/<course_id>/users/<user_id> \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "page_views": {
  #       "2012-01-24": {
  #         "general": 5,
  #         "grades": 2,
  #         "files": 5,
  #         "other": 7
  #       },
  #       "2012-01-27": {
  #         "general": 15,
  #         "assignments": 11,
  #         "pages": 6
  #       }
  #     },
  #     "participations": [
  #       "2012-01-21",
  #       "2012-01-27"
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
  #     curl https://<canvas>/api/v1/analytics/participation/courses/<course_id>/users/<user_id> \ 
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
  #     curl https://<canvas>/api/v1/analytics/participation/courses/<course_id>/users/<user_id> \ 
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
end
