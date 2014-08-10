AppView = require('views/appview')

class QuestionView extends AppView
  events:
    'change .js-question-name': 'changeName'
    'change .js-question-prompt': 'changePrompt'
    'change .js-question-required': 'changeRequired'
    'change .js-question-type': 'changeType'

  initialize: ({ @form }) ->
    super

  render: ->
    data = _.extend @model.toJSON(),
      uid: @cid
      disabled: if @form.get('published') then 'disabled' else ''
      requiredOption: @model.get('type') !in ['table']
      types: _.map Util.questionTypes, (type) =>
        value: type
        name: Util.ucFirst(type)
        selected: type == @model.get('type')

    @$el.html(@template('form_question', data))

    return @

  changeName: ({ target }) ->
    newName = @$(target).val()
    oldName = @model.get('name')

    duplicates = @form.questions.where({ name: newName })
    if !_.isEmpty(duplicates)
      Util.showAlert('Invalid value: duplicate question name')
      @$(target).val(oldName).focus().select()
      return

    @model.set(name: newName)

  changePrompt: ({ target }) ->
    @model.set(prompt: @$(target).val())

  changeRequired: ({ target }) ->
    properties = @model.get('properties')
    if target.checked
      properties.required = true
    else
      delete properties.required
    @model.set('properties', properties)

  changeType: ({ target }) ->
    @model.set(type: @$(target).val())

class SectionView extends AppView
  events:
    'click .js-add-question': 'addQuestion'
    'change .js-section-name': 'changeName'
    'change .js-section-title': 'changeTitle'
    'change .js-section-subtitle': 'changeSubtitle'

  initialize: ({ @form }) ->
    @listenTo @form.questions, 'add remove reset', @render

    super

  render: ->
    data = @model.toJSON()
    data.uid = @cid
    data.disabled = if @form.get('published') then 'disabled' else ''
    @$el.html(@template('form_section', data))

    questions = @form.questions.filterBySection(@model.get('name'))
    _.each questions, (question) =>
      @$('.js-questions').append(new QuestionView({ model: question, @form }).render().el)

    return @

  addQuestion: ->
    @form.questions.add({ name: _.uniqueId('question_'), section: @model.get('name') })

  changeName: ({ target }) ->
    newName = @$(target).val()
    oldName = @model.get('name')

    duplicates = @form.sections.where({ name: newName })
    if !_.isEmpty(duplicates)
      Util.showAlert('Invalid value: duplicate section name')
      @$(target).val(oldName).focus().select()
      return

    @model.set(name: newName)
    questions = @form.questions.filterBySection(oldName)
    for question in questions
      question.set(section: newName)

  changeTitle: ({ target }) ->
    @model.set(title: @$(target).val())

  changeSubtitle: ({ target }) ->
    @model.set(subtitle: @$(target).val())

class FormView extends AppView
  events:
    'click .js-add-section': 'addSection'
    'click .js-save-form': 'save'
    'click .js-publish-form': 'publish'
    'change .js-form-name': 'changeName'

  initialize: ->
    @listenTo @model.sections, 'add remove reset', @render
    @listenTo @model, 'change:published change:active', @render

    super

  render: ->
    data = @model.toJSON()
    data.disabled = if @model.get('published') then 'disabled' else ''

    @$el.html(@template('form', data))

    @$('.js-sections').empty()
    @model.sections.each (section) =>
      @$('.js-sections').append(new SectionView({ model: section, form: @model }).render().el)

    return @

  changeName: ({ target }) ->
    @model.set(name: @$(target).val())

  addSection: ->
    @model.sections.add({ name: _.uniqueId('section_') })

  save: ->
    if @model.isNew()
      navigate = true

    @model.save().then =>
      if navigate
        Controller.navigate('forms/' + @model.id, trigger: true)
      Util.showAlert('Form saved', 'alert-success')

  publish: ->
    @model.publish()

module.exports = FormView
