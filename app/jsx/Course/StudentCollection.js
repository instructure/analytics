import Backbone from '@canvas/backbone'
import StudentModel from '../Course/StudentModel'

export default class StudentCollection extends Backbone.Collection {}

StudentCollection.prototype.model = StudentModel
