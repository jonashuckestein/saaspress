### REMOTE FORM HANDLING ###

# Disable button when a request is underway
$(document).on "ajax:send", (ev) ->
  $(ev.target).find("input[type=submit], button[type=submit]").button("loading")

# Re-enable button afterwards
# NOTE: ajax:complete donesn't fire, if the form is replaced in the
# javascript response (e.g. in create.js.erb or similar)
$(document).on "ajax:complete", (ev) ->
  console.log "ajax:complete", $(ev.target)
  $button = $(ev.target).find("input[type=submit], button[type=submit]").
    button("reset")

$(document).on "ajax:error", (ev, data, status, xhr) ->
  # TODO remove email address here
  alert("We're sorry, an unexpected error occurred on our side. "+
    "Please try again or contact support@hipdial.com if the problem persists")

$(document).on "ajax:success", (ev, data, status, xhr) ->
  console.log "ajax:success", $(ev.target)
  # status 278 is hardcoded to mean turbolinks redirect
  # hopefully this will soon work with vanilla 302 redirects.
  # there is a corrsponding monkeypatch in application_controller
  if xhr.status == 278
    Turbolinks.visit(xhr.getResponseHeader("Location"))

