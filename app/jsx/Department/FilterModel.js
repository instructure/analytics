import Backbone from '@canvas/backbone'
import helpers from '../helpers'
import ParticipationData from '../Department/ParticipationData'
import GradeDistributionData from '../Department/GradeDistributionData'
import StatisticsData from '../Department/StatisticsData'

export default class FilterModel extends Backbone.Model {
  // #
  // Parse start/end date on initial load.
  initialize() {
    let {startDate, endDate} = this.toJSON()
    startDate = helpers.midnight(Date.parse(startDate), 'floor')
    endDate = helpers.midnight(Date.parse(endDate), 'ceil')
    return this.set({startDate, endDate})
  }

  // #
  // Make sure all the data is either loading or loaded.
  ensureData() {
    let {participation, gradeDistribution, statistics} = this.attributes
    if (participation == null) {
      participation = new ParticipationData(this)
    }
    if (gradeDistribution == null) {
      gradeDistribution = new GradeDistributionData(this)
    }
    if (statistics == null) {
      statistics = new StatisticsData(this)
    }
    return this.set({participation, gradeDistribution, statistics})
  }
}
