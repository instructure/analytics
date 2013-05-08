module Analytics
  class PermittedCourse
    def initialize(user, course, analytics)
      @user = user
      @course = course
      @course_analytics = analytics
    end

    def assignments
      @course_analytics.assignments
    end

  end
end
