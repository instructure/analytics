module Analytics
  class PermittedCourse
    def initialize(user, course)
      @user = user
      @course = course
    end

    def assignments_uncached
      visibilities = @course.section_visibilities_for(@user)
      level = @course.enrollment_visibility_level_for(@user, visibilities)
      course_analytics = Analytics::Course.new(@user, @course)

      if level == :full || level == :sections
        course_analytics.assignment_rollups_for(visibilities.map{|s| s[:course_section_id]})
      else
        course_analytics.assignments
      end
    end

    # We don't currently update the completion percentage on the progress model
    # while pulling this data. The analytics web UI only shows a spinner right now.
    def assignments(progress = nil)
      @assignments_cache ||=
        Rails.cache.fetch(assignments_cache_key, :expires_in => Analytics::Base.cache_expiry) { assignments_uncached }
    end

    def async_data_available?
      @assignments_cache ||= Rails.cache.read(assignments_cache_key)
      !!@assignments_cache
    end

    def tag
      "permitted_course_assignments"
    end

    def assignments_cache_key
      [ @course, @user, tag ].cache_key
    end

    def current_progress
      Progress.where(
        :context_id => @course, :context_type => @course.class.to_s,
        :cache_key_context => assignments_cache_key).order('created_at').first
    end

    def progress_for_background_assignments
      progress = current_progress
      if progress && !progress.pending? && !async_data_available?
        progress.destroy
        progress = nil
      end

      unless progress
        progress = Progress.create!(
          :context => @course,
          :tag => tag) { |p| p.cache_key_context = assignments_cache_key }
        progress.process_job(self, :assignments)
      end
      return progress
    end
  end
end
