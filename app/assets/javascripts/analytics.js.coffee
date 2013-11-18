# --- BEGIN HOME PAGE ---

# Tracks which sections a user has scrolled to.
scrolledSections = []

homeAnalyticsReady = ->
  $('#loginModal').on 'hide.bs.modal', ->
    analytics.track 'Login Modal Hide'

  $('.auth form').submit (e) ->
    modalText = if $(@).parents('#loginModal').get(0) then 'Modal ' else ''
    analytics.track "Login #{modalText}Form Submit",
      email: $(@).find('input[name="user[email]"]').val()
      remember_me: $(@).find('input[name="user[remember_me]"]').val()

  $('#homeEmailForm').submit (e) ->
    analytics.track 'Submit Home Email Form',
      email: $(@).find('input[name="user[email]"]').val()

  $('#detailsContactLink').click (e) ->
    analytics.track 'Click Contact',
      from: 'Details'

  sections = $('.section')
  if sections.length > 0
    $(window).scroll ->
      scrollTop = $(window).scrollTop()

      closestSection = undefined
      closestDist = undefined
      sections.each ->
        dist = Math.abs($(@).offset().top - scrollTop)
        if !closestSection? || dist < closestDist
          closestSection = @
          closestDist = dist

      sectionId = $(closestSection).attr('id')
      if sectionId not in scrolledSections
        analytics.track 'Landing Page - Read Section',
          'Section': sectionId.charAt(0).toUpperCase() + sectionId.slice(1)
        scrolledSections.push sectionId

$(document).ready homeAnalyticsReady
$(document).on 'page:load', homeAnalyticsReady

# --- END HOME PAGE ---

# --- BEGIN PACKAGES SECTION ---

packagesAnalyticsReady = ->
  $('#userProfileReferralLink').mousedown (e) ->
    analytics.track 'Referral Link Possible Copy',
      from: 'User Profile'
  $('#packagesListReferralLink').mousedown (e) ->
    analytics.track 'Referral Link Possible Copy',
      from: 'Packages List'
  $('#packagesListReadDetails').click (e) ->
    analytics.track 'Click Read Details',
      from: 'Packages List'
  $('#packageReadDetailsLink').click (e) ->
    analytics.track 'Click Read Details',
      from: 'Package'
  $('#packageContactLink').click (e) ->
    analytics.track 'Click Contact',
      from: 'Package'
  $('#packageProhibitedLink').click (e) ->
    analytics.track 'Click Prohibited Items',
      from: 'Package'
  $('#termsProhibitedLink').click (e) ->
    analytics.track 'Click Prohibited Items',
      from: 'Terms'

$(document).ready packagesAnalyticsReady
$(document).on 'page:load', packagesAnalyticsReady

# --- BEGIN GLOBAL ANALYTICS ---

eventClickTrackedIDs =
  '#homeFacebookLogin': 'Click Home Facebook Login',
  '#homeEmailField': 'Click Home Email Field',
  '#homeReadMore': 'Click Home Read More',
  '#homeLogin': 'Click Home Login',
  '#homeGoToApp': 'Click Home Go To App',
  '#homeSignUp': 'Click Home Sign Up',
  '#homeFacebookPage': 'Click Home Facebook Page',
  '#homeTwitterPage': 'Click Home Twitter Page',
  '#packageOverview': 'Click Package Overview Tab',
  '#packageDetails': 'Click Package Details Tab',
  '#stripe-checkout': 'Click Stripe Checkout',

globalAnalyticsReady = ->
  ids = (k for k, v of eventClickTrackedIDs)
  $(ids.join(', ')).click (e) ->
    analytics.track eventClickTrackedIDs['#' + $(@).attr('id')]

$(document).ready globalAnalyticsReady
$(document).on 'page:load', globalAnalyticsReady

$(document).ready ->
  # Only fire when the site is loaded from scratch.
  analytics.track 'Site Load'

# --- END GLOBAL ANALYTICS ---
