require [
  'analytics/compiled/Department/DepartmentModel'
  'analytics/compiled/Department/DepartmentView'
], (DepartmentModel, DepartmentView) ->

  # package up the environment and then use it to build the view
  new DepartmentView
    model: new DepartmentModel ENV.ANALYTICS
    el: $('#analytics_body')
