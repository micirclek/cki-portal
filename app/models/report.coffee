AppModel = require('models/appmodel')

class Answer extends AppModel
  typeName: 'Answer'

  defaults:
    _id: null
    question: ''
    value: null

class AnswerCollection extends Backbone.Collection
  model: Answer

  findByQuestion: (question) ->
    @findWhere({ question })

Answer.Collection = AnswerCollection

class Report extends AppModel
  typeName: 'Report'
  urlRoot: '/1/reports'

  defaults: ->
    _id: null
    idForm: null

    for: {
      modelType: ''
      idClub: null
      idDistrict: null
    }

    submitted: false
    dateSubmitted: null

    dateFor: new Date(new Date().getFullYear(), new Date().getMonth() - 1)

    serviceHours: 0
    interclubs: 0
    kfamEvents: 0

  editable: ->
    entityFor = @get('for')
    if @get('submitted')
      # TODO verify which district
      return Session.me.positions.getCurrent().chain()
      .find (position) =>
        position.get('level') in ['district', 'international']
      .value()?
    else
      return Session.me.positions.getCurrent().chain()
      .find (position) =>
        position.get('level') == entityFor.modelType.toLowerCase()
        idString = 'id' + entityFor.modelType
        position.get(idString) == entityFor[idString]
      .value()?

  parse: (data) ->
    @answers.set(data.answers, parse: true)
    delete data.answers

    if data.dateFor?
      data.dateFor = new Date(data.dateFor)
    if data.dateSubmitted?
      data.dateSubmitted = new Date(data.dateSubmitted)

    super

  toJSON: ->
    data = super
    data.answers = @answers.toJSON()
    return data

  constructor: ->
    @answers = new AnswerCollection()
    super

  getAnswer: (question, value) ->
    @answers.findByQuestion(question)?.get('value')

  setAnswer: (question, value) ->
    answer = @answers.findByQuestion(question)

    if answer?
      old = answer.get('value')
      answer.set({ value }, { silent: true })
      answer.trigger('change:value', answer, old, {})
    else
      @answers.add({ question, value })

  submit: ->
    @save().then =>
      # TODO validate client-side
      Backbone.ajax
        type: 'PUT'
        url: @url() + '/submitted'
        data:
          value: true
      .then =>
        Util.showAlert('Report Successfully submitted', 'alert-success')
        Controller.navigate('', trigger: true)

  reopen: ->
    Backbone.ajax
      type: 'PUT'
      url: @url() + '/submitted'
      data:
        value: false
    .then =>
      @set(submitted: false)
      Util.showAlert('Report reopened', 'alert-success')

class ReportCollection extends Backbone.Collection
  model: Report

Report.Collection = ReportCollection

module.exports = Report
