ContextController.class_eval do
  def roster_with_analytics
    return unless roster_without_analytics

    if analytics_enabled_course?
      # capture link to analytics pages for students in this course
      @student_analytics_links = {}
      @students.each do |student|
        if analytics_enabled_student?(student)
          @student_analytics_links[student.id] =
            analytics_user_in_course_path :course_id => @context.id, :user_id => student.id
        end
      end

      # if there were any links, inject them into the page
      unless @student_analytics_links.empty?
        js_env :ANALYTICS => { :student_links => @student_analytics_links }
        js_bundle :inject_roster_analytics, :plugin => :analytics
        jammit_css :analytics_buttons, :plugin => :analytics
      end
    end

    # continue rendering the page
    render :action => 'roster'
  end
  alias_method_chain :roster, :analytics

  def roster_user_with_analytics
    return unless roster_user_without_analytics

    if analytics_enabled_course? && analytics_enabled_student?(@user)
      # inject a button to the analytics page for the student in the course
      js_env :ANALYTICS => {
        :link => analytics_user_in_course_path(:course_id => @context.id, :user_id => @user.id),
        :user_name => @user.short_name || @user.name
      }
      js_bundle :inject_roster_user_analytics, :plugin => :analytics
      jammit_css :analytics_buttons, :plugin => :analytics
    end

    # continue rendering the page
    render :action => 'roster_user'
  end
  alias_method_chain :roster_user, :analytics

  private
  # is the context a course with the necessary conditions to view analytics in
  # the course?
  def analytics_enabled_course?
    @context.is_a?(Course) &&
    ['available', 'completed'].include?(@context.workflow_state) &&
    service_enabled?(:analytics) &&
    @context.grants_right?(@current_user, session, :view_analytics)
  end

  # can the user view analytics for this student in the course?
  def analytics_enabled_student?(student)
    Analytics::UserInCourse.available_for?(@current_user, session, @context, student)
  end
end
