define ['jquery', 'analytics/compiled/Department/DepartmentButton'], ($, button) ->
  module 'department analytics button'
  

  test 'inject: adds the container element when absent from the context', ->
    $context = $("<div id='root'></div>")
    button.inject("<p id='sub'></p>", $context)
    equal(1, $context.children('.rs-margin-all').length)

  test 'inject: puts the provided html inside the container', ->
    $context = $("<div id='root'></div>")
    button.inject("<p id='sub'></p>", $context)
    $injected_html =  $context.find('.rs-margin-all').find('p')
    equal($injected_html.attr('id'), "sub")
    
