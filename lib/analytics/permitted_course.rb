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
        visible_section_ids = level == :full ?
          @course.course_sections.active.pluck(:id) :
          visibilities.map{|s| s[:course_section_id]}
        course_analytics.assignment_rollups_for(visible_section_ids)
      else
        course_analytics.assignments
      end
    end

    # We don't currently update the completion percentage on the progress model
    # while pulling this data. The analytics web UI only shows a spinner right now.
    def assignments(progress = nil)
      @assignments_cache ||=
        Rails.cache.fetch(assignments_cache_key, :expires_in => Analytics::Base.cache_expiry, :use_new_rails => false) { assignments_uncached }
    end

    def async_data_available?
      @assignments_cache ||= Rails.cache.read(assignments_cache_key, :use_new_rails => false)
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
