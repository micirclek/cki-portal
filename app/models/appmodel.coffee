class AppModel extends Backbone.Model
  idAttribute: '_id'

  initialize: ->
    @synced = false
    @changed = false

    @on 'change', (args...) ->
      @changed = true
      @trigger 'change:changed', args...
    , @

    @on 'sync', (args...) ->
      @changed = false
      @synced = true
      @trigger 'change:changed change:synced', args...
    , @

    super

module.exports = AppModel
