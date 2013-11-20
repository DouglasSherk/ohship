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
        table = $('<table class="table" />')
        table.append('<tr><th>Shipping class</th><th>Cost</th><th>OhShip fee (20%)</th><th>Total</th></tr>')
        for ship_class, cost of data.estimates
          tr = $('<tr />')
          tr.append($("<td>#{ship_class}</td>"))
          tr.append($("<td>$#{cost.toFixed(2)} USD</td>"))
          tr.append($("<td>$#{(cost*0.2).toFixed(2)} USD</td>"))
          tr.append($("<td><strong>$#{(cost*1.2).toFixed(2)} USD</strong></td>"))
          table.append(tr)

        if table.children().length == 0
          display.html("No shipping options available. Please double-check your dimensions.")
          display.attr('class', 'alert alert-danger')
        else
          p = $('<p />')
          p.html('Your shipping options are: ')
          p.append(table)
          p.append('<p>* Estimates obtained from the official USPS shipping calculator.')
          display.html(p)
          display.attr('class', 'alert alert-info')
      else if data.url
        display.html("We can't automatically calculate shipping for this country. Visit <a href='#{data.url}'><b>the #{data.carrier} site</b></a> for details.<br />" +
                     "Note that OhShip charges a 20% fee on top of the quoted amount.<br />" +
                     "Alternatively, contact <a href='mailto:hello@ohship.me'>hello@ohship.me</a> for assistance.")
        display.attr('class', 'alert alert-info')
      else
        display.html("We can't automatically calculate shipping for this country. Contact <a href='mailto:hello@ohship.me'>hello@ohship.me</a> for details.")
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
