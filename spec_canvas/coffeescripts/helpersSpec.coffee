# baseUrl in this context is public/javascripts
require.config
  paths:
    analytics: "../plugins/analytics/javascripts"

define ['analytics/compiled/helpers'], (helpers) ->
  module 'helpers'

  test 'midnight: should find preceding midnight', ->
    # coerce to integer (which is milliseconds since epoch) for comparison
    # since Date objects don't like equality.
    original = new Date 2000, 0, 1, 0, 0, 1
    expected = new Date 2000, 0, 1, 0, 0, 0
    equal +helpers.midnight(original), +expected

    original = new Date 2000, 0, 1, 23, 59, 59
    expected = new Date 2000, 0, 1, 0, 0, 0
    equal +helpers.midnight(original), +expected

  test "midnight: should't change original", ->
    original = new Date 2000, 0, 1, 10, 25, 45
    expected = new Date 2000, 0, 1, 10, 25, 45
    helpers.midnight(original)
    equal +original, +expected
