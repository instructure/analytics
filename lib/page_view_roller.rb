module PageViewRoller
  # We ignore page views not related to a course or that we've already
  # summarized
  PAGE_VIEWS = PageView.scoped(:conditions => "context_id IS NOT NULL AND context_type='Course' AND summarized IS NULL")

  # Rollup all the remaining unsummarized page views.
  #
  # Available options:
  #   - start_day [date]: override automatic start day detection, and use the
  #     provided value
  #
  #   - end_day [date]: override automatic end day detection, and use the
  #     provided value
  #
  #   - dry_run [boolean]: don't actually insert/update any rows
  #
  #   - verbose [boolean or string]: print additional log lines (excessive
  #     amounts if set to 'flood')
  def self.rollup_all(opts={})
    opts[:start_day] ||= self.start_day(opts)
    unless opts[:start_day]
      logger.info "Did not detect any page views to roll up."
      return
    end
    opts[:end_day] ||= self.end_day(opts)
    logger.info "Rolling up page views between #{opts[:start_day]} and #{opts[:end_day]}, inclusive."

    # process each day in between as its own transaction, from most recent to
    # least recent
    day = opts[:end_day]
    while day >= opts[:start_day]
      rollup_one(day, opts)
      day -= 1.day
    end

    logger.info "Roll up completed."
  end

  # Rollup the remaining unsummarized page views for a given day.
  #
  # Available options:
  #   - dry_run [boolean]: don't actually insert/update any rows
  #
  #   - verbose [boolean or string]: print additional log lines (excessive
  #     amounts if set to 'flood')
  def self.rollup_one(day, opts={})
    PageView.transaction do
      # scope the page views down to just that day
      page_views = PAGE_VIEWS.scoped(:conditions => ["created_at >= ? AND created_at < ?", day, day + 1.day])

      # bin them by course id and category, and update the appropriate rollup row
      # for each result
      binned(page_views) do |course_id, category, views, participations|
        PageViewsRollup.augment!(course_id, day, category, views, participations) unless opts[:dry_run]
        logger.info "Rolled up page views for #{course_id}/#{day}/#{category}." if opts[:verbose] == 'flood'
      end

      # mark all the processed page views as summarized
      page_views.update_all(:summarized => true) unless opts[:dry_run]
      logger.info "Rolled up page views for #{day}." if opts[:verbose]
    end
  end

  # Determine the oldest date with unsummarized page views.
  #
  # Available options:
  #   - verbose [boolean or string]: print additional log lines if set to
  #     'flood'
  def self.start_day(opts={})
    # Nov 2010 is just after the first page views in production cloud canvas.
    # if we go much later as the upper bound (in production canvas) the MIN
    # aggregate gets slow. if that's too early for other installs/shards
    # running this migration, advance a month at a time until we find some.
    day = Date.new(2010, 11)
    today = Date.today
    loop do
      logger.info "Looking for oldest unsummarized page view before #{day}." if opts[:verbose] == 'flood'
      row = PAGE_VIEWS.scoped(:select => 'MIN(created_at) AS result', :conditions => ["created_at <= ?", day]).first
      return row.result.to_date if row.result
      logger.info "No unsummarized page views before #{day}." if opts[:verbose] == 'flood'

      # break here rather than at the start of loop so we still attempt the
      # first time day >= today
      break if  day >= today
      day = [day + 1.month, today].min
    end

    # if there are any page_views in the table (on this shard), they're in the
    # future. we'll just ignore them.
    return nil
  end

  # Determine the newest date with unsummarized page views.
  #
  # Available options:
  #   - start_day [date]: override automatic start day detection, and use the
  #     provided value
  #
  #   - verbose [boolean or string]: print additional log lines if set to
  #     'flood'
  def self.end_day(opts={})
    # similar to start_day, but starting at today and going back, taking the
    # latest page view's created_at. stop if we reach the start_day (not that
    # we should -- if there's a start day, there's a )
    opts[:start_day] ||= start_day(opts)
    return nil unless opts[:start_day]
    day = [Date.today, opts[:start_day]].max
    loop do
      logger.info "Looking for newest unsummarized page view after #{day}." if opts[:verbose] == 'flood'
      row = PAGE_VIEWS.scoped(:select => 'MAX(created_at) AS result', :conditions => ["created_at >= ?", day]).first
      return row.result.to_date if row.result
      logger.info "No unsummarized page views after #{day}." if opts[:verbose] == 'flood'

      # break here rather than at the start of loop so we still attempt the
      # first time day <= start_day
      break if day <= opts[:start_day]
      day = [day - 1.month, opts[:start_day]].max
    end

    # if there are any page_views in the table (on this shard), they're before
    # start_day (which is only possible if start_day was provided). we'll just
    # ignore them and return (the supplied) start_day.
    return opts[:start_day]
  end

  # Bins the scope by course id and category, then yields the counts to the
  # provided block. participations are those views which had participated true
  # and an asset_user_access_id. the category is the same as PageView#category
  def self.binned(scope)
    scope = scope.scoped(:select => <<-SELECT, :group => 'context_id, category')
      context_id,
      CASE controller
        WHEN 'assignments'         THEN 'assignments'
        WHEN 'courses'             THEN 'general'
        WHEN 'quizzes'             THEN 'quizzes'
        WHEN 'wiki_pages'          THEN 'pages'
        WHEN 'gradebooks'          THEN 'grades'
        WHEN 'submissions'         THEN 'assignments'
        WHEN 'discussion_topics'   THEN 'discussions'
        WHEN 'files'               THEN 'files'
        WHEN 'context_modules'     THEN 'modules'
        WHEN 'announcements'       THEN 'announcements'
        WHEN 'collaborations'      THEN 'collaborations'
        WHEN 'conferences'         THEN 'conferences'
        WHEN 'groups'              THEN 'groups'
        WHEN 'question_banks'      THEN 'quizzes'
        WHEN 'gradebook2'          THEN 'grades'
        WHEN 'wiki_page_revisions' THEN 'pages'
        WHEN 'folders'             THEN 'files'
        WHEN 'grading_standards'   THEN 'grades'
        WHEN 'discussion_entries'  THEN 'discussions'
        WHEN 'assignment_groups'   THEN 'assignments'
        WHEN 'quiz_questions'      THEN 'quizzes'
        WHEN 'gradebook_uploads'   THEN 'grades'
        ELSE 'other'
      END AS category,
      COUNT(*) AS views,
      SUM(CAST(participated AND asset_user_access_id IS NOT NULL AS INTEGER)) AS participations
    SELECT

    scope.each do |row|
      # unpack the selected values
      course_id = row.context_id
      category = row.category
      views = row.views.to_i
      participations = row.participations.to_i

      # yield them to the provided block
      yield course_id, category, views, participations
    end
  end

  def self.logger
    ActiveRecord::Base.logger
  end
end
