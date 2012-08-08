require 'app/controllers/context_controller'

class ContextController
  def roster_with_analytics
    return unless roster_without_analytics
    if analytics_enabled_course?
      js_bundle :inject_roster_analytics, :plugin => :analytics
      jammit_css :analytics_buttons, :plugin => :analytics
    end
    render :action => 'roster'
  end
  alias_method_chain :roster, :analytics

  def roster_user_with_analytics
    return unless roster_user_without_analytics

    if analytics_enabled_course? && analytics_enabled_student?(@user)
      # inject a button to the analytics page for the student in the course
      js_env :ANALYTICS => {
        :link => analytics_student_in_course_path(:course_id => @context.id, :student_id => @user.id),
        :student_name => @user.short_name || @user.name
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
    @context.grants_right?(@current_user, session, :view_analytics) &&
    Analytics::Course.available_for?(@current_user, session, @context)
  end

  # can the user view analytics for this student in the course?
  def analytics_enabled_student?(student)
    analytics = Analytics::StudentInCourse.new(@current_user, session, @context, student)
    analytics.available? &&
    analytics.enrollment.grants_right?(@current_user, session, :read_grades)
  end
end
