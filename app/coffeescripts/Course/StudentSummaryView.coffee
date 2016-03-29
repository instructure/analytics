define [
  'jquery'
  'underscore'
  'Backbone'
  'analytics/jst/course_student_summary'
], ($, _, Backbone, template) ->

  class StudentSummaryView extends Backbone.View
    tagName: 'tr'

    initialize: ->
      super
      @render()

    render: =>
      json = _.omit(@model.get('student').toJSON(), 'html_url')
      json.pageViews = @model.get('pageViews').count
      json.participations = @model.get('participations').count
      subs = @model.get('tardinessBreakdown')
      json.submissions = subs.total
      json.onTime = subs.onTime
      json.late = subs.late
      json.missing = subs.missing

      # replace $el with new rendering of template
      oldEl = @$el
      @$el = $ template json
      oldEl.replaceWith @$el

      this
