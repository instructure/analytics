define [
  'jquery'
  'underscore'
  'Backbone'
  '../../views/jst/course_student_summary.handlebars'
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
      # Missing submissions aren't actually submissions yet.  Neither are
      # 'floating' (which apparently means 'future' or 'not submitted yet, but
      # also not missing yet')
      json.submissions = subs.total - subs.missing - subs.floating
      json.onTime = subs.onTime
      json.late = subs.late
      json.missing = subs.missing

      # replace $el with new rendering of template
      oldEl = @$el
      @$el = $ template json
      oldEl.replaceWith @$el

      this
