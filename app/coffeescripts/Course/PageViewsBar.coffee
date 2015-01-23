define [
  'analytics/compiled/Course/CountBar'
  'i18n!page_views_bar'
], (CountBar, I18n) ->

  class PageViewsBar extends CountBar
    tooltipContents: (data) ->
      I18n.t({one: "1 page view", other: "%{count} page views"},
        {count: data.count})
