AppView = require('views/appview')
PopoverView = require('views/popover')
District = require('models/district')

class AddEntityView extends PopoverView
  events:
    'submit form': 'submit'

  initialize: ({ @parent, @parentModel }) ->
    super

  render: ->
    @$el.html(@template('add_entity'))
    return @

  submit: ->
    name = @$('#new-entity-name').val()
    kiwanisId = @$('#new-entity-kid').val()

    newEntity = { name, kiwanisId }

    if @parentModel instanceof District
      newEntity.idDistrict = @parentModel.id

    @model.create newEntity,
      wait: true
      success: =>
        @close()

    return false

  close: ->
    @parent.closePopover()

class EntityListView extends AppView
  events:
    'click .js-toggle-panel': (args...) -> Util.togglePanel(args...)
    'click .js-new-entity': 'openAddEntity'

  initialize: ({ @parent }) ->
    @listenTo @model, 'add remove reset', @render

    @visible = false
    @newEntity = new AddEntityView({ @model, parentModel: @parent, parent: @ })

    super

  render: ->
    entities = @model.map (entity) =>
      years = Util.mapToYears(entity.reports.toArray())
      thisYear = _.findWhere(years, year: Util.getServiceYear())
      thisMonth = _.find thisYear?.months ? [], (report) ->
        report.dateFor.getMonth() == (new Date().getMonth() - 1)

      countTotal = thisYear?.months.length ? 0
      countSubmitted = _.where(thisYear?.months ? [], { submitted: true }).length
      multipleSubmitted = countSubmitted != 1
      countInProgress = countTotal - countSubmitted

      currentMonthStarted = thisMonth?
      currentMonthSubmitted = thisMonth?.submitted

      _.extend entity.toJSON(), {
        basePath: entity.typeName.toLowerCase()
        years
        countTotal
        countSubmitted
        countInProgress
        multipleSubmitted
        currentMonth
        currentMonthStarted
        currentMonthSubmitted
      }
    entities = _.sortBy(entities, 'name')

    currentMonth = new Date(new Date().getFullYear(), new Date().getMonth() - 1)
    data = {
      entities
      currentMonth
      parent: @parent.toJSON()
      typeFor: @parent.typeName
      typeOf: @model.model::typeName
    }


    @$el.html(@template('entity_list', data))

    @$('.js-new-entity').popover
      html: true
      title: 'Add New ' + @model.model.name
      content: @newEntity.render().el
      trigger: 'manual'
    .popover('hide')

    return @

  openAddEntity: ->
    if !@visible
      @newEntity.render()
      @$('.js-new-entity').popover('show')
      @newEntity.delegateEvents()
      @visible = true
    return false

  closePopover: ->
    @visible = false
    @newEntity.undelegateEvents()
    @$('.js-new-entity').popover('hide')

module.exports = EntityListView
