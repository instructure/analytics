import helpers from '../../app/jsx/helpers'

QUnit.module('helpers')

test('midnight: should find preceding midnight', () => {
  let original = new Date(2000, 0, 1, 0, 0, 1)
  let expected = new Date(2000, 0, 1, 0, 0, 0)
  ok(helpers.midnight(original, 'floor').equals(expected))

  original = new Date(2000, 0, 1, 23, 59, 59)
  expected = new Date(2000, 0, 1, 0, 0, 0)
  ok(helpers.midnight(original, 'floor').equals(expected))
})

test('midnight: should find following midnight', () => {
  let original = new Date(2000, 0, 1, 0, 0, 1)
  let expected = new Date(2000, 0, 2, 0, 0, 0)
  ok(helpers.midnight(original, 'ceil').equals(expected))

  original = new Date(2000, 0, 1, 23, 59, 59)
  expected = new Date(2000, 0, 2, 0, 0, 0)
  ok(helpers.midnight(original, 'ceil').equals(expected))
})

test('midnight: should return original if on midnight already', () => {
  const original = new Date(2000, 0, 1, 0, 0, 0)
  ok(helpers.midnight(original, 'floor').equals(original))
  ok(helpers.midnight(original, 'ceil').equals(original))
})

test("midnight: should't modify original", () => {
  const original = new Date(2000, 0, 1, 10, 25, 45)
  const expected = new Date(2000, 0, 1, 10, 25, 45)
  helpers.midnight(original, 'floor')
  ok(original.equals(expected))
})

test('daysBetween: basics', () => {
  const start = new Date(2000, 0, 1, 0, 0, 0)
  const end = new Date(2000, 0, 5, 0, 0, 0)
  equal(helpers.daysBetween(start, start), 0)
  equal(helpers.daysBetween(start, end), 4)
})

test('daysBetween: rounds when crossing DST', () => {
  let start = new Date(2000, 0, 1, 0, 0, 0)
  const middle = new Date(2000, 6, 1, 0, 0, 0)
  let end = new Date(2001, 0, 1, 0, 0, 0)
  equal(helpers.daysBetween(start, middle), 182)
  equal(helpers.daysBetween(middle, end), 184)
  equal(helpers.daysBetween(start, end), 366)

  // enough years to accumulate enough DST hours to make a difference if we
  // were doing it wrong (they shouldn't actually accumulate)
  start = new Date(2000, 0, 1, 0, 0, 0)
  end = new Date(2012, 0, 1, 0, 0, 0)
  equal(helpers.daysBetween(start, end), 365 * 12 + 3)
})
