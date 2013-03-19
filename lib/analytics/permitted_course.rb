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

      if level == :full
        @course_analytics.assignment_rollups
      elsif level == :sections
        @course_analytics.assignment_rollups_for(visibilities.map{|s| s[:course_section_id]})
      else
        @course_analytics.assignments
      end
    end

  end
end
