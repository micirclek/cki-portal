AppView = require('views/appview')

class PopoverView extends AppView
  initialize: ({ @parent }) ->
    super

  delegateEvents: ->
    super
    $(window).bind('click.popover', (e) => @anyClick(e))

  undelegateEvents: ->
    super
    $(window).unbind('click.popover')

  anyClick: (e) ->
    if !$(e.target).closest('.popover').length
      @close()

  close: ->
    throw Error('Close not implemented')

module.exports = PopoverView
