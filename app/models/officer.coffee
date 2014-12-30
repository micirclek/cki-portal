AppModel = require('models/appmodel')

class Officer extends AppModel
  typeName: 'Officer'

  defaults:
    name: ''
    email: ''
    confirmed: false

class OfficerCollection extends Backbone.Collection
  model: Officer
  url: ->
    @entity.url() + '/officers'

  initialize: (models, { @entity }) ->
    super

  create: (model) ->
    if @findWhere({ email: model.email })
      throw Error('An officer with that email already exists')

    return super

Officer.Collection = OfficerCollection

module.exports = Officer
