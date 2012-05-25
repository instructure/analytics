require 'app/controllers/courses_controller'

class CoursesController
  def show_with_analytics
    # this is a really gross coupling with the implementation of vanilla
    # Course#show, but it seems the best way for now to detect that it
    # unequivocally is rendering the html page (vs. a json response, a
    # redirect, or an "unauthorized")
    show_without_analytics
    return unless @course_home_view

    if analytics_enabled?
      # inject a button to the analytics page for the course
      js_env :ANALYTICS => { :link => analytics_course_path(:course_id => @context.id) }
      js_bundle :inject_course_analytics, :plugin => :analytics
      jammit_css :analytics_buttons, :plugin => :analytics
    end

    # continue rendering the page
    render :action => 'show'
  end
  alias_method_chain :show, :analytics

  private
  # is the context a course with the necessary conditions to view analytics in
  # the course?
  def analytics_enabled?
    ['available', 'completed'].include?(@context.workflow_state) &&
    service_enabled?(:analytics) &&
    @context.grants_right?(@current_user, session, :view_analytics)
  end
end
