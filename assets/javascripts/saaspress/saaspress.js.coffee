_.extend window.SaasPress,
  Views: {}
  Util: {}

Turbolinks.enableTransitionCache()

$(document).on("page:change", ->
  FastClick.attach(document.body)
)

NProgress.configure({ speed: 130 })
  
$(document).on("ajax:send page:fetch", ->
  NProgress.start()
)

# back/forward button in browser
$(document).on("page:restore", -> 
  NProgress.remove()
)

# NOTE: ajax:complete doesn't fire if the element that initiated the
# request gets replaced in a JS response (as is often the case with js.erb)
# For that reason, application.js.erb contains NProgress.done(), as well
$(document).on("ajax:complete ajax:success ajax:error page:change", ->
  NProgress.done()
)

