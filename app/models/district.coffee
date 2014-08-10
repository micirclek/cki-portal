Entity = require('models/entity')
Club = require('models/club')
Form = require('models/form')

class District extends Entity
  typeName: 'District'
  urlRoot: '/1/districts'

  parse: (data, options) ->
    @clubs.set(data.clubs, parse: true)
    @childForms.set(data.childForms, parse: true)
    delete data.clubs
    return super(data, options)

  toJSON: ->
    data = super
    data.clubs = @clubs.toJSON()
    data.childForms = @childForms.toJSON()

    return data

  constructor: ->
    @clubs = new Club.Collection
    @childForms = new Form.Collection
    super

module.exports = District
