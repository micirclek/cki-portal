AppModel = require('models/appmodel')

class Question extends AppModel
  typeName: 'Question'

  defaults: ->
    _id: null
    name: ''
    type: 'text'
    prompt: ''
    properties:
      required: false
      fields: []
      options: []

class Section extends AppModel
  typeName: 'Section'

  defaults:
    _id: null
    name: ''
    title: ''
    subtitle: ''

class QuestionCollection extends Backbone.Collection
  model: Question

  filterBySection: (section) ->
    @where({ section })

class SectionCollection extends Backbone.Collection
  model: Section

  findByName: (name) ->
    @findWhere({ name })

class Form extends AppModel
  typeName: 'Form'
  urlRoot: '/1/forms'

  defaults: ->
    _id: null

    name: 'Report'

    for: {
      modelType: ''
      idDistrict: null
    }

    properties:
      autoStats: false
      table: ''
      serviceField: ''
      kfamField: ''
      interclubField: ''

    active: true
    published: false

  parse: (data) ->
    @questions.set(data.questions, parse: true)
    @sections.set(data.sections, parse: true)
    delete data.questions
    delete data.sections

    super

  toJSON: ->
    data = super
    data.sections = @sections.toJSON()
    data.questions = @questions.toJSON()
    return data

  constructor: ->
    @questions = new QuestionCollection()
    @sections = new SectionCollection()
    super

  editable: ->
    filler = @get('for')
    if filler.idDistrict
      return Session.me.positions.getCurrent().chain()
      .find (position) =>
        position.get('level') == 'district' && position.get('idDistrict') == filler.idDistrict
      .value()?
    else
      return Session.me.positions.getCurrent().chain()
      .find (position) =>
        position.get('level') == 'international'

  publish: ->
    @save().then =>
      Backbone.ajax
        type: 'PUT'
        url: @url() + '/published'
        data:
          value: true
      .tap =>
        Util.showAlert('Form successfully pulbished', 'alert-success')
        @set(published: true)

class FormCollection extends Backbone.Collection
  model: Form

Form.Collection = FormCollection

module.exports = Form
