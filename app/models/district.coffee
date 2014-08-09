Entity = require('models/entity')
Club = require('models/club')

class District extends Entity
  typeName: 'District'
  urlRoot: '/1/districts'

  parse: (data, options) ->
    @clubs.set(data.clubs, parse: true)
    delete data.clubs
    return super(data, options)

  toJSON: ->
    data = super
    data.clubs = @clubs.toJSON()

    return data

  constructor: ->
    @clubs = new Club.Collection
    super

module.exports = District
