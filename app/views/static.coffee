AppView = require('views/appview')

class StaticView extends AppView
  initialize: ({ @name }) ->
    super

  render: ->
    @$el.html(@template(@name))
    return @

module.exports = StaticView
