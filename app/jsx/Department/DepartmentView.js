define [
  'jquery'
  'Backbone'
  '../../views/jst/department.handlebars'
  'analytics/compiled/Department/DepartmentFilterBox'
  'analytics/compiled/Department/DepartmentGraphView'
  'analytics/compiled/Department/StatisticsView'
  'i18n!department_view'
], ($, Backbone, template, DepartmentFilterBox, DepartmentGraphView, StatisticsView, I18n) ->

  ##
  # Aggregate view for the Department Analytics page.
  class DepartmentView extends Backbone.View
    initialize: ->
      super

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

      document.title = I18n.t("Analytics: %{account_name} -- %{filter_name}",
        {account_name: account.get('name'), filter_name: filter.get('label')})
      @$crumb_span.text filter.get 'label'
      @$crumb_link.attr href: filter.get 'url'
