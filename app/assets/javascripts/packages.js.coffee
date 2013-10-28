# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->
  button = $('#stripe-checkout')
  button.click ->
    StripeCheckout.open(
      key: 'pk_test_xhOGDSqkhDTfzW7RqeQ3TFlv',
      amount: button.data('amount'),
      currency: 'usd',
      name: 'ohship.me',
      description: button.data('description'),
      token: (res) ->
        $input = $('<input type="hidden" name="stripeToken" />').val(res.id)
        form = button.parents('form')
        form.append($input).submit()
    )

  # XXX: Should be using change event, but it doesn't work.
  $('#packageIsAnEnvelope').click (e) ->
    $('#packageHeight').css 'display', if this.checked then 'none' else 'block'

  $('#new_package').submit (e) ->
    btnSubmit = $('#new_package button[type="submit"]')
    btnSubmit.html '<i class="fa fa-spinner fa-spin"></i> ' + btnSubmit.html()
