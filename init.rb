Rails.configuration.to_prepare do
  view_path = File.dirname(__FILE__)+'/app/views'
  ::ApplicationController.view_paths.delete view_path
  ::ApplicationController.view_paths.unshift view_path

  require_dependency 'analytics_permissions'
  require_dependency 'context_controller_with_extensions'
  require_dependency 'courses_controller_with_extensions'
end
