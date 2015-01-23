define [
  'analytics/compiled/Course/CountBar'
  'i18n!participations_bar'
], (CountBar, I18n) ->

  class ParticipationsBar extends CountBar
    tooltipContents: (data) ->
      I18n.t({one: "1 participation", other: "%{count} participations"},
        {count: data.count})
