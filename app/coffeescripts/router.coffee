define ['Backbone'], (Backbone) ->

  router = new Backbone.Router
    routes:
      'courses/:course': 'course'
      'courses/:course/users/:student': 'studentInCourse'

  Backbone.history.start
    root: "/analytics/"
    pushState: true

  router
