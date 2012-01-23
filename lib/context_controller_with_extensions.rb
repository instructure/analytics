ContextController.class_eval do
  def roster_with_analytics
    return unless roster_without_analytics
    if @context.is_a?(Course) && service_enabled?(:analytics) # && ...
      @student_analytics_links = {}
      @students.each do |student|
        @student_analytics_links[student.id] = analytics_user_in_course_path :course_id => @context.id, :user_id => student.id
      end

      js_env :ANALYTICS => { :student_links => @student_analytics_links }
      js_bundle :inject_roster_analytics, :plugin => :analytics
    end
    render :action => 'roster'
  end
  alias_method_chain :roster, :analytics

  def roster_user_with_analytics
    return unless roster_user_without_analytics
    if @context.is_a?(Course) && @membership.is_a?(StudentEnrollment) && service_enabled?(:analytics) # && ...
      js_env :ANALYTICS => {
        :link => analytics_user_in_course_path(:course_id => @context.id, :user_id => @user.id),
        :user_name => @user.short_name || @user.name
      }
      js_bundle :inject_roster_user_analytics, :plugin => :analytics
    end
    render :action => 'roster_user'
  end
  alias_method_chain :roster_user, :analytics
end
