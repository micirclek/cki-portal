AppView = require('views/appview')
AdminView = require('views/admin')
ReportListView = require('views/report_list')
EntityListView = require('views/entity_list')
GoalsView = require('views/goals')

class LandingView extends AppView
  render: ->
    data =
      name: @model.get('name')
      urlBase: @model.typeName.toLowerCase()
      id: @model.id
    @$el.html(@template('landing', data))

    if !@model.reports.isEmpty() || !@model.forms.isEmpty()
      models =
        model: @model.reports
        forms: @model.forms
        entity: @model
      @$('.js-report-list').html(new ReportListView(models).render().el)

    if @model.typeName == 'District'
      @$('.js-child-list').html(new EntityListView(model: @model.clubs, parent: @model).render().el)

    @$('.js-goals').html(new GoalsView(model: @model).render().el)
    @$('.js-admin').html(new AdminView(model: @model).render().el)

    return @

module.exports = LandingView
