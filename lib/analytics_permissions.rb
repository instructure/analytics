Permissions.register :view_analytics,
  :label => lambda { I18n.t('#role_override.permissions.view_analytics', "View analytics pages") },
  :available_to => %w(TaEnrollment TeacherEnrollment AccountAdmin AccountMembership),
  :true_for => %w(AccountAdmin)

# intended for inclusion in analytics' various controllers for shared
# functionality around permissions
module AnalyticsPermissions
  module ClassMethods
  end

  module InstanceMethods
    def require_analytics_enabled
      # does the account even have analytics enabled?
      raise ActiveRecord::RecordNotFound unless service_enabled?(:analytics)
      return true
    end

    def require_analytics_for_course
      # do you have permission to use them?
      scope = Course.scoped(:conditions => {:workflow_state => ['available', 'completed']})
      @course = api_request? ? api_find(scope, params[:course_id]) : scope.find(params[:course_id])
      authorized_action(@course, @current_user, :view_analytics) &&
      authorized_action(@course, @current_user, :read)
    end

    def require_analytics_for_user_in_course
      return false unless require_analytics_for_course

      # you can use analytics and see this course, but do you have access to this
      # user's enrollment in the course?
      @user = api_request? ? api_find(User, params[:user_id]) : User.find(params[:user_id])
      @analytics = Analytics::UserInCourse.new(@current_user, session, @course, @user)
      raise ActiveRecord::RecordNotFound unless @analytics.available?

      return true
    end
  end

  def self.included(klass)
    klass.send :include, InstanceMethods
    klass.extend ClassMethods

    klass.before_filter :require_user # comes from ApplicationController
    klass.before_filter :require_analytics_enabled
  end
end
