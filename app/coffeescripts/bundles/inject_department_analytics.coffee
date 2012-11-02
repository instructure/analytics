require [
  'analytics/compiled/Department/DepartmentButton'
  'analytics/jst/department_analytics_button'
], (button, template) ->
  $sidebar = $('#right-side')
  button.inject template(ENV.ANALYTICS), $sidebar 
