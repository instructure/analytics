import Backbone from '@canvas/backbone'
import ParticipationData from '../StudentInCourse/ParticipationData'
import MessagingData from '../StudentInCourse/MessagingData'
import AssignmentData from '../StudentInCourse/AssignmentData'

export default class StudentModel extends Backbone.Model {
  // #
  // Make sure all the data is either loading or loaded.
  ensureData() {
    let {participation, messaging, assignments} = this.attributes
    if (participation == null) participation = new ParticipationData(this)
    if (messaging == null) messaging = new MessagingData(this)
    if (assignments == null) assignments = new AssignmentData(this)
    return this.set({participation, messaging, assignments})
  }
}
