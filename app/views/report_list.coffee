AppView = require('views/appview')

# view to list current and past reports as well as to offer a chance to start
# a new report
class ReportListView extends AppView
  initialize: ({ @forms, @entity }) ->
    @listenTo @model, 'change', @render
    @listenTo @forms, 'change', @render

  render: ->
    years = {}

    submittedReports = @model.where(submitted: true)
    activeReports = @model.where(submitted: false)
    activeReports = _.map activeReports, (report) =>
      report.toJSON()

    years = Util.mapToYears(submittedReports)

    data = {
      forms: @forms.toJSON()
      years
      activeReports
      idEntity: @entity.id
      urlBase: @entity.typeName.toLowerCase()
      entityName: @entity.get('name')
    }

    @$el.html(@template('report_list', data))
    return @

module.exports = ReportListView
