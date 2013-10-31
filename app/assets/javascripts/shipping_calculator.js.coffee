ready = ->
  button = $('#shipping-estimate-button')

  button.click ->
    form = button.parents('form')
    display = $('#shipping-estimate-display')
    display.html('Loading...')
    display.attr('class', 'alert alert-info')

    data = form.serialize()

    $.ajax('/packages/shipping_estimate', {data: data}).done((data) ->
      if data.estimates
        select = $('<select id="shipping-estimate-dropdown" />')
        for ship_class, cost of data.estimates
          select.append($("<option>#{ship_class}: $#{cost.toFixed(2)} + OhShip handling fees</option>"))
        if select.children().length == 0
          display.html("No shipping options available. Please double-check your dimensions.")
          display.attr('class', 'alert alert-danger')
        else
          display.html('Your shipping options are: ')
          display.append(select)
          display.attr('class', 'alert alert-info')
      else if data.url
        display.html("We can't automatically calculate shipping for this destination. Visit <a href='#{data.url}'><b>the #{data.carrier} site</b></a> for details.")
        display.attr('class', 'alert alert-info')
      else
        display.html("We can't automatically calculate shipping for this destination. Contact <a href='mailto:hello@ohship.me'>hello@ohship.me</a> for details.")
        display.attr('class', 'alert alert-info')
    ).fail((data) ->
      display.attr('class', 'alert alert-danger')
      if data.status == 422
        display.html('Please fill out all fields in the form first.')
      else
        display.html('Could not connect to server. Please try again later.')
    )

$(document).ready ready
$(document).on 'page:load', ready
