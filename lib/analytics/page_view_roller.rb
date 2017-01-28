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

module Analytics::PageViewRoller
  # We ignore page views not related to a course. include "summarized IS NULL"
  # to ignore page views inserted since the rollup tables were introduced, also
  # to speed up query (index includes summarized)
  PAGE_VIEWS = PageView.where("context_id IS NOT NULL AND context_type='Course' AND summarized IS NULL")

  # Generate the remaining rollups.
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

    # process each day in between as its own chunk, from most recent to least
    # recent
    day = opts[:end_day]
    while day >= opts[:start_day]
      rollup_one(day, opts)
      day -= 1.day
    end

    logger.info "Roll up completed."
  end

  # Generate the remaining rollups for a given day.
  #
  # Available options:
  #   - dry_run [boolean]: don't actually insert/update any rows
  #
  #   - verbose [boolean or string]: print additional log lines (excessive
  #     amounts if set to 'flood')
  def self.rollup_one(day, opts={})
    # scope the page views down to just that day
    page_views = PAGE_VIEWS.where(:created_at => day..(day + 1.day))

    # bin them by course id and category, and insert a rollup row for each
    # result. if a row for the bin already exists, assume all views for that
    # bin have already been rolled up. this assumption should only be false on
    # days since the PageViewsRoller was deployed, which can be addressed
    # later.
    binned(page_views) do |course_id, category, views, participations|
      unless opts[:dry_run]
        PageView.transaction do
          bin = PageViewsRollup.bin_for(course_id, day, category)
          next unless bin.new_record?
          bin.augment(views, participations)
          bin.save!
        end
      end
      logger.info "Rolled up page views for #{course_id}/#{day}/#{category}." if opts[:verbose] == 'flood'
    end
    logger.info "Rolled up page views for #{day}." if opts[:verbose]
  end

  # Determine the oldest date with page views.
  #
  # Available options:
  #   - verbose [boolean or string]: print additional log lines if set to
  #     'flood'
  def self.start_day(opts={})
    slaved do
      # Nov 2010 is just after the first page views in production cloud canvas.
      # if we go much later as the upper bound (in production canvas) the MIN
      # aggregate gets slow. if that's too early for other installs/shards
      # running this migration, advance a month at a time until we find some.
      day = Date.new(2010, 11)
      today = Date.today
      loop do
        logger.info "Looking for oldest page view before #{day}." if opts[:verbose] == 'flood'
        row = PAGE_VIEWS.where("created_at<=?", day).minimum(:created_at)
        return row.to_date if row
        logger.info "No page views before #{day}." if opts[:verbose] == 'flood'

        # break here rather than at the start of loop so we still attempt the
        # first time day >= today
        break if  day >= today
        day = [day + 1.month, today].min
      end

      # if there are any page_views in the table (on this shard), they're in the
      # future. we'll just ignore them.
      return nil
    end
  end

  # Determine the newest date that might still need rolling up.
  #
  # Available options:
  #   - start_day [date]: override automatic start day detection, and use the
  #     provided value
  #
  #   - verbose [boolean or string]: print additional log lines if set to
  #     'flood'
  def self.end_day(opts={})
    slaved do
      # find the oldest roll up on or after start_day. assume any days after that
      # have been completely rolled up. if none found, go through today (or
      # start_day if somehow after today)
      opts[:start_day] ||= start_day(opts)
      return nil unless opts[:start_day]
      logger.info "Looking for oldest roll up on or after #{opts[:start_day]}." if opts[:verbose] == 'flood'
      date = PageViewsRollup.where("date>=?", opts[:start_day]).minimum(:date)
      date || Date.today
    end
  end

  # Bins the scope by course id and category, then yields the counts to the
  # provided block. participations are those views which had participated true
  # and an asset_user_access_id. the category is the same as PageView#category
  def self.binned(scope)
    scope = scope.group(:context_id, :category).select(<<-SQL)
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
    SQL

    rows = slaved { scope.to_a }
    rows.each do |row|
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

  def self.slaved
    Shackles.activate(:slave) { yield }
  end
end
