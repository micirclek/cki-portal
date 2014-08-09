AppView = require('views/appview')

class EntityListView extends AppView
  events:
    'click .js-toggle-panel': (args...) -> Util.togglePanel(args...)

  initialize: ({ @parent }) ->
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
    data = { entities, currentMonth, parent: @parent.toJSON(), typeFor: @parent.typeName }

    @$el.html(@template('entity_list', data))

    return @

module.exports = EntityListView
