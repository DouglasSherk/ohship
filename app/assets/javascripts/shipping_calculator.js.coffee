$(document).ready ->
  button = $('#shipping-estimate-button')

  button.click ->
    form = button.parents('form')
    display = $('#shipping-estimate-display')
    display.html('Loading...')

    data = {}
    for elem in form.find('input, select')
      data[$(elem).attr('name')] = $(elem).val()

    $.ajax('/packages/shipping_estimate', {data: data}).done((data) ->
      select = $('<select id="shipping-estimate-dropdown" />')
      for ship_class, cost of data
        select.append($("<option>#{ship_class}: #{cost}</option>"))
      if select.children().length == 0
        display.html("No shipping options available. Please double-check your dimensions.")
      else
        display.html(select)
    ).fail((data) ->
      if data.status == 422
        display.html('Please fill out all fields in the form first.')
      else
        display.html('Could not connect to server. Please try again later.')
    )
