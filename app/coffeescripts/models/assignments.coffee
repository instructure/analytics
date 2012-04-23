define [ 'analytics/compiled/models/base' ], (Base) ->

  ##
  # Loads the assignment data for the student and course. Exposes the data as
  # the 'assignments' property once loaded.
  class Assignments extends Base
    constructor: (@course, @student) ->
      super '/api/v1/analytics/assignments/courses/' + @course.id + '/users/' + @student.id

    populate: (data) ->
      @assignments = []
      for original in data
        assignment =
          id: original.assignment_id
          title: original.title
          muted: original.muted
          original: original

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

        @assignments.push assignment
