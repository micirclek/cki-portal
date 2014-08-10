AppView = require('views/appview')
PopoverView = require('views/popover')

# to make removing people easier in the future
class OfficerView extends AppView
  tagName: 'li'
  className: 'list-group-item'

  initialize: ->
    @listenTo @model, 'change', @render

  render: ->
    @$el.html(@template('officer', @model.toJSON()))
    return @

class AddOfficerView extends PopoverView
  events:
    'submit form': 'submit'

  render: ->
    serviceYearStart = parseInt(Util.getServiceYear()[0..3], 10)

    data = {}
    data.years = for offset in [0..1]
      val: serviceYearStart + offset
      name: (serviceYearStart + offset) + '-' + (serviceYearStart + offset + 1)

    @$el.html(@template('add_officer', data))
    return @

  submit: ->
    name = @$('#new-officer-name').val()
    email = @$('#new-officer-email').val()
    year = parseInt(@$('#new-officer-year').val(), 10)

    if @model.findWhere({ email })?
      #TODO this will eventually give us problems with the some officer two
      #years in a row
      Util.showAlert('An officer with that email already exists')
      return false

    @model.create {
      name: name
      email: email
      start: new Date(year, 3, 1)
      end: new Date(year + 1, 3, 1)
    }, {
      wait: true
      success: =>
        @close()
    }

    return false

  close: ->
    @parent.closePopover()

class OfficerListView extends AppView
  events:
    'click .js-new-officer': 'openAddOfficer'

  initialize: ->
    @visible = false

    @listenTo @model, 'add remove reset', @help

    @newOfficer = new AddOfficerView({ @model, parent: @ })

    super

  help: ->
    @render()

  render: ->
    @$el.html(@template('officer_list'))

    @model.each (officer) =>
      @$('.js-officer-list').append(new OfficerView(model: officer).render().el)

    @$('.js-new-officer').popover
      html: true
      title: 'Add New Officer'
      content: @newOfficer.render().el
      trigger: 'manual'
    .popover('hide')

    return @

  openAddOfficer: ->
    if !@visible
      @newOfficer.render()
      @$('.js-new-officer').popover('show')
      @newOfficer.delegateEvents()
      @visible = true
    return false

  closePopover: ->
    @visible = false
    @newOfficer.undelegateEvents()
    @$('.js-new-officer').popover('hide')

class AdminView extends AppView
  events:
    'click .js-toggle-panel': (args...) -> Util.togglePanel(args...)

  render: ->
    @$el.html(@template('admin'))
    @$('.js-officers').html(new OfficerListView(model: @model.officers).render().el)

    return @

module.exports = AdminView
