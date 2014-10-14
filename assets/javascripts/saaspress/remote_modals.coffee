# WARNINGS regarding modals
#
#  - modals will be cleared when they are closed, but whatever 
#    javascript code is running within won't be (i.e. click handlers)
#  - when using .modal views, all included views must explicitly
#    be included as .html if that's what you want

$(document).on "loaded.bs.modal", (event, res, status, req) ->
  # TODO implement error handling for global bs modal

# We don't want remote modals to persist across close/open
# cycles. As long as there's always only one open modal,
# this means we don't have to clean up after ourselves when modals
# have "served their purpose"
$(document).on "hidden.bs.modal", (event) ->
  console.log "modal hidden, clearing"
  $(event.target).replaceWith('<div class="modal fade" id="remote-modal"><div class="modal-dialog"><div class="modal-content"><div class="loading-remote"></div></div></div></div>')


