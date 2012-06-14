define [
  'jquery'
  'Backbone'
  'analytics/jst/course_student_summary'
  'analytics/compiled/Course/CountBar'
  'analytics/compiled/Course/TardinessBar'
], ($, Backbone, template, CountBar, TardinessBar) ->

  class StudentSummaryView extends Backbone.View
    tagName: 'tr'

    initialize: ->
      @render()

    render: =>
      # replace $el with new rendering of template
      oldEl = @$el
      @$el = $ template @model.get('student').toJSON()
      oldEl.replaceWith @$el

      # update activity and assignments graphs from student summary
      @pageViews = new CountBar @$('.page_views'), 'page views'
      @participations = new CountBar @$('.participations'), 'participations'
      @tardiness = new TardinessBar @$('.assignments')

      @pageViews.show @model.get 'pageViews'
      @participations.show @model.get 'participations'
      @tardiness.show @model.get 'tardinessBreakdown'

      this
