Canvas.reloadable_plugin(File.dirname(__FILE__))

controller_path = File.dirname(__FILE__)+'/app/controllers'
ActiveSupport::Dependencies.autoload_paths.delete controller_path
ActiveSupport::Dependencies.autoload_paths.unshift controller_path

configure_method = Proc.new do
  ::ApplicationController.promote_view_path File.dirname(__FILE__)+'/app/views'

  Account.register_service :analytics,
    :name => "Analytics",
    :description => "",
    :expose_to_ui => :setting,
    :default => false

  require_dependency 'analytics/extensions'

  # This is in a separate file so the Delayed::Periodic job is only created
  # one time.
  require 'analytics/periodic_jobs'
end

if CANVAS_RAILS2
  Rails.configuration.to_prepare(&configure_method)
else
  class AnalyticsRailtie < Rails::Railtie; end
  AnalyticsRailtie.config.to_prepare(&configure_method)
end

Permissions.register :view_analytics,
  :label => lambda { I18n.t('#role_override.permissions.view_analytics', "View analytics pages") },
  :available_to => %w(AccountAdmin TaEnrollment TeacherEnrollment StudentEnrollment AccountMembership),
  :true_for => %w(AccountAdmin TaEnrollment TeacherEnrollment)
