define [
  'compiled/widget/ComboBox'
  'analytics/compiled/Department/DepartmentRouter'
], (ComboBox, DepartmentRouter) ->

  ##
  # A combobox representing the possible filters for the department view.
  class DepartmentFilterBox extends ComboBox
    constructor: (@model) ->
      # add a router tied to the model
      @router = new DepartmentRouter @model

      # construct combobox
      super @model.get('filters').models,
        value: (filter) -> filter.get 'id'
        label: (filter) -> filter.get 'label'
        selected: @model.get('filter').get 'id'

      # connect combobox to model
      @on 'change', @push
      @model.on 'change:filter', @pull

    ##
    # Push the current value of the combobox to the URL
    push: (filter) =>
      @router.select filter.get('fragment')

    ##
    # Pull the current value from the model to the combobox
    pull: =>
      @select @model.get('filter').get 'id'
