$(document).ready ->
  adjustDimensions = ->
    $('.section.expanded').css('width', $(window).width())
    $('.section.expanded').first().css('height', $(window).height())

  $(window).resize adjustDimensions
  adjustDimensions()

  findSectionById = (id) ->
    $(".navbar a[href='##{id}']")

  $('a').click (e) ->
    target = $(e.target)
    target = target.parent() if e.target.tagName != 'A'
    return if !e.target? || target.attr('href')[0] != '#'
    if (target = $("#{target.attr('href')}")).length
      $('html, body').animate
        scrollTop: target.offset().top - 170
      , 500
    e.preventDefault()

  $(window).scroll ->
    scrollTop = $(window).scrollTop()

    if scrollTop > 0
      $('.navbar').addClass('active')
    else
      $('.navbar').removeClass('active')

    closestSection = undefined
    closestDist = undefined
    $('.section').each ->
      dist = Math.abs($(@).offset().top - scrollTop)
      if !closestSection? || dist < closestDist
        closestSection = @
        closestDist = dist

    $('.navbar a').removeClass('active')
    findSectionById($(closestSection).attr('id')).addClass('active')
