define [
  'jquery'
  'Backbone'
  'analytics/jst/department'
  'analytics/compiled/Department/DepartmentRouter'
  'analytics/compiled/Department/DepartmentFilterBox'
  'analytics/compiled/Department/DepartmentGraphView'
  'analytics/compiled/Department/StatisticsView'
], ($, Backbone, template, DepartmentRouter, DepartmentFilterBox, DepartmentGraphView, StatisticsView) ->

  ##
  # Aggregate view for the Department Analytics page.
  class DepartmentView extends Backbone.View
    initialize: ->
      # add a router tied to the model
      @router = new DepartmentRouter @model
      @router.run()

      # render template into anchor $el
      @$el.html template account: @model.get('account').toJSON()

      # filter combobox
      @filterBox = new DepartmentFilterBox @model
      @$('#filter_box').append @filterBox.$el

      # add graph subview
      new DepartmentGraphView
        model: @model
        el: @$('.department_graphs')

      # add statistics subview
      new StatisticsView
        model: @model
        el: @$('.department_statistics')

      # cache page elements for updates
      @$title = $('title')
      @$crumb_span = $('#filter_crumb span')
      @$crumb_link = $('#filter_crumb a')

      # update title and crumb on filter change
      @model.on 'change:filter', @updatePage

    ##
    # Update the page title and filter-related crumb text/link to match the
    # current filter.
    updatePage: =>
      account = @model.get 'account'
      filter = @model.get 'filter'

      @$title.text "Analytics: #{account.get 'name'} -- #{filter.get 'label'}"
      @$crumb_span.text filter.get 'label'
      @$crumb_link.attr href: filter.get 'url'
