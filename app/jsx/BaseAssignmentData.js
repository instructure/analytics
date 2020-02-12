import BaseData from './BaseData'

// #
// Loads assignment data. Exposes the data as the 'assignments' property once
// loaded.
export default class BaseAssignmentData extends BaseData {
  constructor(scope, parameters = {}) {
    super(`/api/v1/${scope}/assignments`, parameters)
  }

  populate(data) {
    this.assignments = []
    for (const original of Array.from(data)) {
      if (original.excused) {
        continue
      }

      const assignment = {
        id: original.assignment_id,
        title: original.title,
        original
      }

      if (original.non_digital_submission != null) {
        assignment.non_digital_submission = original.non_digital_submission
      }

      if (original.multiple_due_dates != null) {
        assignment.multipleDueDates = original.multiple_due_dates
      }

      if (original.due_at != null) {
        assignment.dueAt = Date.parse(original.due_at)
      }

      if (original.points_possible != null) {
        assignment.pointsPossible = original.points_possible
      }

      if (original.submission != null) {
        if (original.submission.submitted_at != null) {
          assignment.submittedAt = Date.parse(original.submission.submitted_at)
          assignment.onTime = assignment.dueAt == null || assignment.submittedAt <= assignment.dueAt
        }
        if (original.submission.score != null) {
          assignment.studentScore = original.submission.score
        }
        assignment.muted = assignment.studentScore != null && original.submission.posted_at == null
      } else {
        assignment.muted = original.muted
      }

      if (original.min_score != null) {
        assignment.scoreDistribution = {
          minScore: original.min_score,
          firstQuartile: original.first_quartile,
          median: original.median,
          thirdQuartile: original.third_quartile,
          maxScore: original.max_score
        }
      }

      if (original.tardiness_breakdown) {
        assignment.tardinessBreakdown = {
          onTime: original.tardiness_breakdown.on_time,
          late: original.tardiness_breakdown.late,
          missing: original.tardiness_breakdown.missing
        }
      }

      this.assignments.push(assignment)
    }
  }
}
