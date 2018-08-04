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
  class Department < Analytics::Base
    def initialize(current_user, account, term, filter)
      super(current_user)
      @account = account
      @term = term
      @filter = filter
    end

    def dates
      slaved(:cache_as => :dates) { @filter ? dates_for_filter(@filter) : dates_for_term(@term) }
    end

    def start_date
      @start_date, @end_date = dates unless @start_date
      @start_date
    end

    def end_date
      @start_date, @end_date = dates unless @start_date
      @end_date
    end

    def dates_for_term(term)
      # try and use the term start/end dates if provided, calculate them if not
      start_at = term.start_at
      end_at = term.end_at
      calculate_and_clamp_dates(start_at, end_at, courses_for_term(term))
    end

    def dates_for_filter(filter)
      # always calculate start_at. calculate end_at for 'completed', but use
      # the present for 'current'
      end_at = Time.zone.now unless filter == 'complete'
      calculate_and_clamp_dates(nil, end_at, courses_for_filter(filter))
    end

    def participation_by_date
      slaved(:cache_as => :participation_by_date) do
        page_views_rollups.
          select("date, SUM(views) AS views, SUM(participations) AS participations").
          group(:date).
          map{ |rollup| rollup.as_json[:page_views_rollup] }
      end
    end

    def participation_by_category
      slaved(:cache_as => :participation_by_category) do
        page_views_rollups.
          select("category, SUM(views) AS views").
          group(:category).
          order(:category).
          map{ |rollup| rollup.as_json[:page_views_rollup] }
      end
    end

    def grade_distribution
      slaved(:cache_as => :grade_distribution) do
        result = {}
        distribution = cached_grade_distribution
        (0..100).each{ |i| result[i] = distribution["s#{i}"] }
        result
      end
    end

    # Note: we had to remove statistics for discussion_replies and submissions
    # because the queries were too slow.  If we bring them back, we need to
    # find a way to make them performant.
    def statistics
      slaved(:cache_as => :statistics) do
        {
          :courses => courses.distinct.count("courses.id"),
          :subaccounts => subaccounts.count,
          :teachers => count_users_for_enrollments(teacher_enrollments),
          :students => count_users_for_enrollments(student_enrollments),
          :discussion_topics => discussion_topics.count,
          :media_objects => media_objects.count,
          :attachments => attachments.count,
          :assignments => assignments.count,
        }
      end
    end

    def statistics_by_subaccount
      # TODO: Determine proper counts if sections are crosslisted to a
      # different subaccounts
      slaved(:cache_as => :statistics_by_subaccount) do
        # TODO: y u no paginate?
        ([@account] + subaccounts).map do |a|
          {
            :name => a.name,
            :id => a.id,
            :courses => courses_for_subaccount(a).distinct.count("courses.id"),
            :teachers => count_users_for_enrollments(teacher_enrollments_for_subaccount(a)),
            :students => count_users_for_enrollments(student_enrollments_for_subaccount(a)),
            :discussion_topics => 0,
            :media_objects => 0,
            :attachments => 0,
            :assignments => 0
          }
        end
      end
    end

  protected

    def cache_prefix
      [@account, @filter || @term]
    end

    def default_term
      @account.root_account.default_enrollment_term
    end

    def subaccounts
      @account.sub_accounts
    end

    def courses_for_term(term, workflow_state=['completed', 'available'])
      # AFAICT, rows in course_account_associations that *don't* have a section
      # number associated are "really" associated with that account (i.e.
      # not via crosslisting)
      @account.course_account_associations.
        joins(:course).
        where(:courses => { :enrollment_term_id => term, :workflow_state => workflow_state }).
        where(:course_section_id => nil)
    end

    def courses_for_filter(filter)
      workflow_state =
        case filter
        when 'completed' then 'completed'
        when 'current' then 'available'
        end
      courses_for_term(default_term, workflow_state)
    end

    def courses
      @filter ?
        courses_for_filter(@filter) :
        courses_for_term(@term)
    end

    def courses_for_subaccount(subaccount)
      courses.where(:courses => { account_id: subaccount})
    end

    def courses_subselect
      courses.select("courses.id").distinct
    end

    def page_views_rollups
      PageViewsRollup.where(course_id: courses_subselect)
    end

    def cached_grade_distribution
      # need to select a value for course_id here, or we get complaints about primary key missing_attribute
      selects = ["NULL AS course_id"] + (0..100).map{ |i| "SUM(s#{i}) AS s#{i}" }
      CachedGradeDistribution.connection.select_all(
        CachedGradeDistribution.select(selects).where(course_id: courses_subselect)).to_a.first
    end

    def enrollments
      Enrollment.where(workflow_state: ['active', 'completed'], course_id: courses_subselect)
    end

    def enrollments_for_subaccount(acct)
      enrollments.joins(:course).where(:courses  => { account_id: acct } )
    end

    def teacher_enrollments
      enrollments.where(:type => 'TeacherEnrollment')
    end

    def teacher_enrollments_for_subaccount(acct)
      enrollments_for_subaccount(acct).where(:type => 'TeacherEnrollment')
    end

    def student_enrollments
      enrollments.where(:type => 'StudentEnrollment')
    end

    def student_enrollments_for_subaccount(acct)
      enrollments_for_subaccount(acct).where(:type => 'StudentEnrollment')
    end

    def count_users_for_enrollments(enrollments_scope)
      enrollments_scope.distinct.count('user_id')
    end

    def discussion_topics
      DiscussionTopic.active.where(context_id: courses_subselect,
                                   context_type: 'Course')
    end

    def media_objects
      MediaObject.active.where(context_id: courses_subselect,
                               context_type: 'Course')
    end

    def attachments
      Attachment.active.where(context_id: courses_subselect,
                              context_type: 'Course')
    end

    def assignments
      Assignment.active.where(context_id: courses_subselect,
                              context_type: 'Course')
    end

    def calculate_and_clamp_dates(start_at, end_at, courses)
      # default start_at to the earliest created_at and end_at to the latest
      # conclude_at
      select = []
      select << 'MIN(courses.created_at) AS created_at' unless start_at
      select << 'MAX(courses.conclude_at) AS conclude_at' unless end_at
      unless select.empty?
        if dates = slaved{ ActiveRecord::Base.connection.select_all(courses.select(select)).to_a.first }
          start_at ||= parse_utc_time(dates['created_at'])
          end_at ||= parse_utc_time(dates['conclude_at'])
        end
      end

      # unless otherwise specified, end at current date. never go past current
      # date
      now = Time.zone.now
      end_at ||= now
      end_at = [now, end_at].min

      # unless otherwise specified, start 1 year before target end date. never
      # start after current date
      start_at ||= end_at - 1.year
      start_at = [now, start_at].min

      # if start_at and end_at both specified but out of order, end on start
      # date
      end_at = [start_at, end_at].max

      return start_at, end_at
    end

    def parse_utc_time(time_string)
      return unless time_string
      return time_string unless String === time_string
      Time.use_zone('UTC') { Time.zone.parse(time_string) }.in_time_zone
    end
  end
end
