AppModel = require('models/appmodel')
Form = require('models/form')
Officer = require('models/officer')
Report = require('models/report')

class Entity extends AppModel
  parse: (data, options) ->
    @forms.set(data.forms, parse: true)
    @officers.set(data.officers, parse: true)
    @reports.set(data.reports, parse: true)
    delete data.forms
    delete data.officers
    delete data.reports

    return super(data, options)

  toJSON: ->
    data = super
    data.forms = @forms.toJSON()
    data.officers = @officers.toJSON()
    data.reports = @reports.toJSON()

    return data

  constructor: ->
    @forms = new Form.Collection
    @officers = new Officer.Collection([], entity: @)
    @reports = new Report.Collection
    super

  defaults:
    _id: null
    name: ''
    kiwanisId: ''

class EntityCollection extends Backbone.Collection
  model: Entity

Entity.Collection = EntityCollection

module.exports = Entity
