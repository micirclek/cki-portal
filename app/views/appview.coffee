class AppView extends Backbone.View
  editable: ->
    @model?.editable?() ? false

  template: (name, context, options) ->
    ctx =
      __editable: @editable()
    if Session.loggedIn()
      ctx.me = Session.me.toJSON()
    _.extend(ctx, context)

    require('templates/' + name)(ctx, options)

module.exports = AppView
