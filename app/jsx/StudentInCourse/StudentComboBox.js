define [
  'compiled/widget/ComboBox'
  'analytics/compiled/StudentInCourse/StudentInCourseRouter'
], (ComboBox, StudentInCourseRouter) ->

  ##
  # A combobox representing the possible filters for the department view.
  class StudentComboBox extends ComboBox
    constructor: (@model) ->
      # add a router tied to the model
      @router = new StudentInCourseRouter @model

      # construct combobox
      super @model.get('course').get('students').models,
        value: (student) -> student.get 'id'
        label: (student) -> student.get 'name'
        selected: @model.get('student').get 'id'

      # connect combobox to model
      @on 'change', @push
      @model.on 'change:student', @pull

    ##
    # Push the current value of the combobox to the URL
    push: (student) =>
      @router.select student.get('id')

    ##
    # Pull the current value from the model to the combobox
    pull: =>
      @select @model.get('student').get 'id'
