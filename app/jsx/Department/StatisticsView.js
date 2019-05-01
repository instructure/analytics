define [
  'Backbone',
  '../../views/jst/department_statistics.handlebars'
  'jquery.disableWhileLoading'
], (Backbone, template) ->

  class StatisticsView extends Backbone.View
    initialize: ->
      super
      @model.on 'change', @render
      @render()

    render: =>
      statistics = @model.get('filter').get('statistics')
      if statistics?
        $table = $ template statistics
        @$el.html $table
        if statistics.loading?
          $table.disableWhileLoading(statistics.loading)
          statistics.loading.done @render
          statistics.loading.fail -> # TODO: add error icon
