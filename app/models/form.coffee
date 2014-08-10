AppModel = require('models/appmodel')

class Question extends AppModel
  typeName: 'Question'

  defaults: ->
    _id: null
    name: ''
    type: ''
    prompt: ''
    properties: {}

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

    for: {
      modelType: ''
      idDistrict: null
    }

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

class FormCollection extends Backbone.Collection
  model: Form

Form.Collection = FormCollection

module.exports = Form
