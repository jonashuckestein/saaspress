_.extend window.SaasPress.Util, 

  track_pageview: (props={}) ->
    SaasPress.Util.track_event("Pageview", _.extend({
      title: document.title,
      url: location.href,
      path: location.pathname,
      referrer: document.referrer
    }, props));

  track_event: (event_name, properties={}) ->
    $.ajax(
      data: {
        event_name: event_name
        properties: properties
      }
      dataType: "json"
      success: ->
        if SaasPress.config.analyticsEnabled
          console.log("Tracked event: '#{event_name}'", properties)
        else
          console.log("Would have tracked event: '#{event_name}'", properties)
      error: (jqXHR, textStatus, errorThrown) ->
        throw new Error("Tracking failed for event #{event_name}")
      type: "POST"
      url: SaasPress.config.paths.track_event
    )
  

