# this will need to change once a td for the profile pic already exists (at
# that point we'll want to add the <a><img/></a> to that td below the
# profile pic, rather than making a new td. we'll also need to condition on
# profile pic column being present (the service may be disabled for that
# account))
require [
  'jquery'
  'compiled/views/courses/roster/RosterView'
  'compiled/fn/punch'
  'analytics/jst/student_analytics_grid_button'
], ($, RosterView, punch, template) ->

  addAnalyticsButton = ($userFragment, user) ->
    if user.get('analytics_url')
      $userFragment.prepend $ template url: user.get('analytics_url')

  punch RosterView.prototype, 'renderUser', (old, user) ->
    $userFragment = $ old user
    addAnalyticsButton $userFragment, user
    $userFragment.clone().wrap('<div/>').parent().html()
