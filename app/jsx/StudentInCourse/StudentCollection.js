import Backbone from 'Backbone'
import StudentModel from '../StudentInCourse/StudentModel'

export default class StudentCollection extends Backbone.Collection {}
StudentCollection.prototype.model = StudentModel
