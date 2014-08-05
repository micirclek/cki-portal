AppView = require('views/appview')

class GoalView extends AppView
  initialize: ({ @field, @title }) ->

    lastYear = (0 for [0..11])
    lastYearTotal = 0
    thisYear = (0 for [0..11])
    thisYearTotal = 0

    currentServiceYear = Util.getServiceYear()
    lastServiceYear = Util.getServiceYear(moment().subtract(years: 1))

    for entry in @model.get('stats') ? []
      date = moment(year: entry.year, month: entry.month - 1)
      serviceYear = Util.getServiceYear(date)
      if serviceYear == currentServiceYear
        thisYear[(date.month() + 9) % 12] = entry[@field]
        thisYearTotal += entry[@field]
      else if serviceYear == lastServiceYear
        lastYear[(date.month() + 9) % 12] = entry[@field]
        lastYearTotal += entry[@field]

    months = _.map [0..11], (num) ->
      moment(month: (3 + num) % 12).format('MMM')

    options =
      chart:
        type: 'column'
        renderTo: @el
      title:
        text: @title
      xAxis:
        categories: months
      yAxis:
        min: 0
        title:
          text: @title
      series: [
        {
          name: 'Last Year (' + lastYearTotal + ')'
          data: lastYear
        },
        {
          name: 'This Year (' + thisYearTotal + ')'
          data: thisYear
        }
      ]
    options.chart.height = 250

    @chart = new Highcharts.Chart(options)

    # with backbone, the width is not going to be set correctly, so we will
    # just wait for the element to be actually rendered and the resize it
    reflow = =>
      if $(document).has(@$el).length
        @chart.reflow()
      else
        # every 10ms should not be too bad on a modern browser
        setTimeout((=> reflow()), 50)

    reflow()

    super

class GoalsView extends AppView
  render: ->
    @$el.html(@template('goals'))

    @$('.js-service-hours').html(new GoalView(model: @model, field: 'serviceHours', title: 'Service Hours').render().el)
    @$('.js-interclubs').html(new GoalView(model: @model, field: 'interclubs', title: 'Interclubs').render().el)
    @$('.js-kfam-events').html(new GoalView(model: @model, field: 'kfamEvents', title: 'K-Fam Events').render().el)

    return @

module.exports = GoalsView
