Session = require('models/session')
Controller = require('controller')

# set up analytics
require('lib/backbone.analytics')

$ ->
  ajax = Backbone.ajax
  Backbone.ajax = (options) ->
    handleError = options.handleError ? true
    delete options.handleError
    options.data ?= {}
    if _.isString(options.data)
      data = JSON.parse(options.data)
      data.token = $.cookie('token')
      options.data = JSON.stringify(data)
    else
      options.data.token = $.cookie('token')

    Promise.resolve(ajax(options))
    .catch (e) ->
      if handleError
        if e.status == 401
          Session.me?.clear()
          Util.showAlert('Invalid access: please log in', 'alert-warning', 20000)
          controller.navigate('', trigger: true)
        else
          Util.showAlert(e.status + ': ' + e.responseText)

      throw e

  window.Util = require('util')
  window.Session = new Session

  Raven.config('https://5b2dc839571948f59ad3eb9470544017@app.getsentry.com/28379').install()

  Promise.onPossiblyUnhandledRejection (err, promise) =>
    Raven.captureException err,
      extras:
        fromUnhandledPromise: true

  Promise.longStackTraces()

  Handlebars.registerHelper 'date', (date, format = 'YYYY-MM-DD HH:mm') ->
    moment(date).format(format)

  controller = window.Controller = new Controller

  Backbone.history.start()
