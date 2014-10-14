# NOTES:
#  - The duration of the fade-in needs to be synchronized with
#    highlight_effect.scss
#
#  - This does not work on elements that already have a specific background
#    color
#
do (jQuery) ->
  jQuery.fn.highlight = (timeout=5000) ->
    target = if @is("tr") then @find("> td") else @
    previousColor = target.css("backgroundColor")
    target.addClass("highlight-effect")
    setTimeout((-> 
      target.css(backgroundColor: "transparent")
      setTimeout((-> 
        target.removeClass("highlight-effect")
        target.css(backgroundColor: "")
      ), 1500)
    ), timeout)

