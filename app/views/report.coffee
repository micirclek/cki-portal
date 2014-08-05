AppView = require('views/appview')

class Table extends Backbone.Model
  initialize: ({ @question, @report }) ->
    super

  getAnswer: (question) ->
    tableAnswer = @report.getAnswer(@question.get('name'))
    return tableAnswer?[question.row]?[question.field]

  setAnswer: (question, val) ->
    tableAnswer = @report.getAnswer(@question.get('name'))
    tableAnswer ?= []
    while !tableAnswer[question.row]?
      tableAnswer.push({})
    tableAnswer[question.row][question.field] = val

    @report.setAnswer(@question.get('name'), tableAnswer)

  getNumRows: ->
    @report.getAnswer(@question.get('name'))?.length ? 0

  editable: ->
    @report.editable()

  toJSON: ->
    return @report.getAnswer(@question.get('name'))

  getQuestion: (row, field) ->
    return new TableQuestion({ @question, row, field })

class TableQuestion extends Backbone.Model
  initialize: ({ @question, @row, @field }) ->
    super

  toJSON: ->
    return {
      name: [@question.get('name'), @row, @field.name].join('-')
      type: @field.type
      properties: @field.properties
    }

  get: (attr) ->
    if attr == 'name'
      return { @row, field: @field.name }
    else if attr == 'type'
      return @field.type

class TableView extends AppView
  events:
    'click .js-add-row': 'addRow'

  initialize: ({ @question }) ->
    super

  render: ->
    properties = @question.get('properties')

    data =
      cols: []

    for field in properties.fields ? []
      data.cols.push(field.prompt)

    data.numCols = data.cols.length
    data.disabled = !@model.editable() || @model.get('submitted')

    @$el.html(@template('report_table', data))
    @rows = 0

    numRows = @model.getNumRows()
    if !data.disabled
      numRows += 1

    _.times numRows, => @addRow()

    return @

  addRow: ->
    properties = @question.get('properties')

    row = $('<tr>')
    for field in properties.fields ? []
      question = new TableQuestion({ @model, @question, row: @rows, field })
      questionView = new QuestionView({ @model, question })
      row.append($('<td>').html(questionView.render().el))

    @$('tbody').append(row)

    @rows += 1

    return

class QuestionView extends AppView
  initialize: ({ @question }) ->
    switch @question.get('type')
      when 'date'
        @$el.on('changeDate', '.date', _.bind(@setDate, @))
      when 'select'
        @$el.on('change', 'select', _.bind(@setSimple, @))
      when 'block'
        @$el.on('change', 'textarea', _.bind(@setSimple, @))
      when 'bool'
        @$el.on('change', 'input', _.bind(@setBool, @))
      when 'table'
        # each table element is handled separately via magic
      else
        @$el.on('change', 'input', _.bind(@setSimple, @))

    super

  render: ->
    data = @question.toJSON()
    data.value = @model.getAnswer(@question.get('name'))
    data[data.type + 'Type'] = true
    data.simpleType = data.type in ['text', 'integer', 'number']

    if data.type == 'bool'
      data.valueTrue = data.value == true
      data.valueFalse = data.value == false
    else if data.type == 'select'
      data.options = _.map data.properties.options, (option) ->
        value: option
        selected: option == data.value
        name: Util.ucFirst(option)
    else if data.type == 'date' && data.value
      date = new Date(data.value)
      dom = date.getDate().toString()
      month = (date.getMonth() + 1).toString()
      if month.length == 1
        month = '0' + month
      if dom.length == 1
        dom = '0' + dom
      data.value = date.getFullYear() + '-' + month + '-' + dom

    if data.type == 'table'
      tableModel = new Table({ @question, report: @model, submitted: @model.get('submitted') })
      @$el.html(new TableView({ model: tableModel, @question }).render().el)
    else
      @$el.html(@template('report_question', data))

    if data.type == 'date' && !(!@model.editable() || @model.get('submitted'))
      @$('.date').datepicker
        todayBtn: 'linked'
        autoclose: true
        todayHighlight: true
        format: 'yyyy-mm-dd'

    return @

  setSimple: ({ target }) ->
    @model.setAnswer(@question.get('name'), @$(target).val())

  setDate: ({ date }) ->
    @model.setAnswer(@question.get('name'), date)

  setBool: ({ target }) ->
    val = @$(target).val() in ['true', '1', true, 1]
    @model.setAnswer(@question.get('name'), val)

class SectionView extends AppView
  initialize: ({ @form, @section }) ->
    super

  render: ->
    data = @section.toJSON()
    data.submitted = @model.get('submitted')
    data.disabled = !@model.editable() || @model.get('submitted')

    @$el.html(@template('report_section', data))

    @$('.js-questions').empty()
    questions = @form.questions.filterBySection(@section.get('name'))
    _.each questions, (question) =>
      questionView = new QuestionView({ @model, question })
      @$('.js-questions').append(questionView.render().el)

    return @

class ReportView extends AppView
  events:
    'changeDate .js-report-month': 'setDate'
    'change .js-basic-property': 'setBasicProperty'
    'click .js-save-report': 'saveReport'
    'click .js-submit-report': 'submitReport'
    'click .js-reopen-report': 'reopenReport'

  initialize: ({ @form }) ->
    @listenTo @model, 'change:submitted', @render

    super

  render: ->
    data = @model.toJSON()
    data.dateFor = moment(data.dateFor).format('MMMM YYYY')
    data.disabled = !@model.editable() || @model.get('submitted')

    @$el.html(@template('report', data))

    if !data.disabled
      @$('.js-report-month').datepicker
        startView: 1
        minViewMode: 1
        format: 'MM yyyy'
        autoclose: true
        orientation: 'top auto'
        endDate: new Date()

    @$('.js-sections').empty()
    @form.sections.each (section) =>
      @$('.js-sections').append(new SectionView({ @model, @form, section }).render().el)

    return @

  setDate: ({ date }) ->
    @model.set('dateFor', new Date(date.getFullYear(), date.getMonth()))

  setBasicProperty: ({ target }) ->
    @model.set(@$(target).attr('data-property-name'), @$(target).val())

  saveReport: ->
    if @model.isNew()
      navigate = true

    @model.save().then =>
      if navigate
        Controller.navigate('reports/' + @model.id, trigger: true)
      Util.showAlert('Report saved', 'alert-success')

  submitReport: ->
    @model.submit()

  reopenReport: ->
    @model.reopen()

module.exports = ReportView
