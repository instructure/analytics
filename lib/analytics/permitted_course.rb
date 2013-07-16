module Analytics
  class PermittedCourse
    def initialize(user, course, analytics)
      @user = user
      @course = course
      @course_analytics = analytics
    end

    def assignments
      visibilities = @course.section_visibilities_for(@user)
      level = @course.enrollment_visibility_level_for(@user, visibilities)

      if level == :full || level == :sections
        visible_section_ids = level == :full ?
          @course.course_sections.active.pluck(:id) :
          visibilities.map{|s| s[:course_section_id]}
        @course_analytics.assignment_rollups_for(visible_section_ids)
      else
        @course_analytics.assignments
      end
    end

  end
end
