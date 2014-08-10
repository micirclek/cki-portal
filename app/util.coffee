Util =
  showAlert: (message, className = 'alert-danger', fadeOut = 5000) ->
    alert = $('#alert')
    alert
      .show()
      .text(message)
      .removeClass('alert-success alert-info alert-warning alert-danger')
      .addClass(className)

    if fadeOut
      alert.fadeOut(fadeOut)

  hideAlert: ->
    $('.alert').hide()

  getServiceYear: (date = moment()) ->
    date = moment(date).utc()
    month = date.month()
    year = date.year()
    if month <= 2 # January - march
      return (year - 1) + '-' + year
    else
      return year + '-' + (year + 1)

  mapToYears: (reports, reverseYears = true) ->
    years = {}
    for report in reports
      serviceYear = Util.getServiceYear(report.get('dateFor'))
      month = report.get('dateFor').getMonth()

      years[serviceYear] ?= { year: serviceYear, months: [] }
      years[serviceYear].months.push report.toJSON()

    years = _.chain(years).values().sortBy('year').value()
    if reverseYears
      years = years.reverse()
    for year in years
      year.months = _.sortBy(year.months, 'dateFor')

    return years

  questionTypes: ['text', 'integer', 'number', 'block', 'date', 'bool', 'select', 'table']

  togglePanel: ({ target }) ->
    $(target).closest('.panel').children('.panel-body').collapse('toggle')
    return false

  ucFirst: (str) ->
    str[0].toUpperCase() + str[1..]

  noop: ->

module.exports = Util
