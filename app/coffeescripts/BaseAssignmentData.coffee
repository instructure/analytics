define [ 'analytics/compiled/BaseData' ], (BaseData) ->

  ##
  # Loads assignment data. Exposes the data as the 'assignments' property once
  # loaded.
  class BaseAssignmentData extends BaseData
    constructor: (scope, parameters={}) ->
      super "/api/v1/#{scope}/assignments", parameters

    populate: (data) ->
      @assignments = []
      for original in data
        if original.excused
          continue

        assignment =
          id: original.assignment_id
          title: original.title
          muted: original.muted
          original: original

        if original.non_digital_submission?
          assignment.non_digital_submission = original.non_digital_submission

        if original.multiple_due_dates?
          assignment.multipleDueDates = original.multiple_due_dates

        if original.due_at?
          assignment.dueAt = Date.parse(original.due_at)

        if original.points_possible?
          assignment.pointsPossible = original.points_possible

        if original.submission?
          if original.submission.submitted_at?
            assignment.submittedAt = Date.parse(original.submission.submitted_at)
            assignment.onTime = !assignment.dueAt? || assignment.submittedAt <= assignment.dueAt
          if original.submission.score?
            assignment.studentScore = original.submission.score

        if original.min_score?
          assignment.scoreDistribution =
            minScore: original.min_score
            firstQuartile: original.first_quartile
            median: original.median
            thirdQuartile: original.third_quartile
            maxScore: original.max_score

        if original.tardiness_breakdown
          assignment.tardinessBreakdown =
            onTime: original.tardiness_breakdown.on_time
            late: original.tardiness_breakdown.late
            missing: original.tardiness_breakdown.missing

        @assignments.push assignment
