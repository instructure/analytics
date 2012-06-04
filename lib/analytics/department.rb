module Analytics
  class Department < Analytics::Base
    def initialize(current_user, session, account, term, filter)
      super(current_user, session)
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
          scoped(:select => "date, sum(views) as views, sum(participations) as participations", :group => "date").
          map{ |rollup| rollup.as_json[:page_views_rollup] }
      end
    end

    def participation_by_category
      slaved(:cache_as => :participation_by_category) do
        page_views_rollups.
          scoped(:select => "category, sum(views) as views", :group => "category").
          map{ |rollup| rollup.as_json[:page_views_rollup] }
      end
    end

    def grade_distribution
      slaved(:cache_as => :grade_distribution) do
        result = {}
        distribution = cached_grade_distribution
        (0..100).each{ |i| result[i] = distribution.send("s#{i}".to_sym) }
        result
      end
    end

    def statistics
      slaved(:cache_as => :statistics) do
        {
          :courses => courses.scoped(:select => "COUNT(DISTINCT courses.id) AS ct").first.ct.to_i,
          :teachers => count_users_for_enrollments(teacher_enrollments),
          :students => count_users_for_enrollments(student_enrollments),
          :discussion_topics => discussion_topics.count,
          :discussion_replies => discussion_replies.count,
          :media_objects => media_objects.count,
          :attachments => attachments.count,
          :assignments => assignments.count,
          :submissions => submissions.count,
        }
      end
    end

  protected

    def cache_prefix
      [@account, @filter || @term]
    end

    def default_term
      @account.root_account.default_enrollment_term
    end

    def courses_for_term(term, workflow_state=['completed', 'available'])
      @account.course_account_associations.scoped(
        :joins => :course,
        :conditions => {
          'courses.enrollment_term_id' => term.id,
          'courses.workflow_state' => workflow_state
        })
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

    def courses_subselect
      courses.scoped(:select => 'DISTINCT courses.id').construct_finder_sql({})
    end

    def page_views_rollups
      PageViewsRollup.scoped(:joins => "
        INNER JOIN (#{courses_subselect}) AS courses
          ON courses.id=page_views_rollups.course_id")
    end

    def cached_grade_distribution
      selects = (0..100).map{ |i| "sum(s#{i}) as s#{i}" }
      CachedGradeDistribution.scoped(:select => selects.join(','), :joins => "
        INNER JOIN (#{courses_subselect}) AS courses ON
          courses.id=cached_grade_distributions.course_id").first
    end

    def enrollments
      Enrollment.scoped(:conditions => {:workflow_state => ['active', 'completed']}).scoped(:joins => "
        INNER JOIN (#{courses_subselect}) AS courses
          ON courses.id=enrollments.course_id")
    end

    def teacher_enrollments
      enrollments.scoped(:conditions => {:type => 'TeacherEnrollment'})
    end

    def student_enrollments
      enrollments.scoped(:conditions => {:type => 'StudentEnrollment'})
    end

    def count_users_for_enrollments(enrollments_scope)
      enrollments_scope.scoped(:select => "COUNT(DISTINCT enrollments.user_id) AS ct").first.ct.to_i
    end

    def discussion_topics
      DiscussionTopic.active.scoped(:joins => "
        INNER JOIN (#{courses_subselect}) AS courses
          ON courses.id=discussion_topics.context_id
          AND discussion_topics.context_type='Course'")
    end

    def discussion_replies
      DiscussionEntry.active.scoped(:joins => "
        INNER JOIN discussion_topics
          ON discussion_topics.id=discussion_entries.discussion_topic_id
          AND discussion_topics.workflow_state != 'deleted'
        INNER JOIN (#{courses_subselect}) AS courses
          ON courses.id=discussion_topics.context_id
          AND discussion_topics.context_type='Course'")
    end

    def media_objects
      MediaObject.active.scoped(:joins => "
        INNER JOIN (#{courses_subselect}) AS courses
          ON courses.id=media_objects.context_id
          AND media_objects.context_type='Course'")
    end

    def attachments
      Attachment.active.scoped(:joins => "
        INNER JOIN (#{courses_subselect}) AS courses
          ON courses.id=attachments.context_id
          AND attachments.context_type='Course'")
    end

    def assignments
      Assignment.active.scoped(:joins => "
        INNER JOIN (#{courses_subselect}) AS courses
          ON courses.id=assignments.context_id
          AND assignments.context_type='Course'")
    end

    def submissions
      Submission.scoped(:joins => "
        INNER JOIN assignments
          ON assignments.id=submissions.assignment_id
          AND assignments.workflow_state != 'deleted'
        INNER JOIN (#{courses_subselect}) AS courses
          ON courses.id=assignments.context_id
          AND assignments.context_type='Course'")
    end

    def calculate_and_clamp_dates(start_at, end_at, courses)
      # default start_at to the earliest created_at and end_at to the latest
      # conclude_at
      select = []
      select << 'MIN(courses.created_at) AS created_at' unless start_at
      select << 'MAX(courses.conclude_at) AS conclude_at' unless end_at
      unless select.empty?
        dates = slaved{ courses.scoped(:select => select.join(',')).first }
        start_at ||= parse_utc_time(dates.created_at) || Time.zone.now
        end_at ||= parse_utc_time(dates.conclude_at) || start_at
      end

      # clamp start_at to (-∞, now]
      # clamp end_at to [start_at, now]
      start_at = [start_at, Time.zone.now].sort.min
      end_at = [start_at, end_at, Time.zone.now].sort[1]

      return start_at, end_at
    end

    def parse_utc_time(time_string)
      return unless time_string
      return time_string unless String === time_string
      Time.use_zone('UTC') { Time.zone.parse(time_string) }.in_time_zone
    end
  end
end
