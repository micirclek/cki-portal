Session = require('models/session')
Controller = require('controller')

# set up analytics
require('lib/backbone.analytics')
# useful errors
require('lib/error')

config = require('config')

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
      err = Error.AjaxError(e)
      if handleError
        if err.status == 401
          Session.me?.clear()
          Util.showAlert('Invalid access: please log in', 'alert-warning', 20000)
          controller.navigate('', trigger: true)
        else
          Util.showAlert(err.message)

      throw err

  window.Util = require('util')
  window.Session = new Session

  if config.SENTRY_DSN
    Raven.config(config.SENTRY_DSN).install()

    Promise.onPossiblyUnhandledRejection (err, promise) =>
      Raven.captureException err,
        extras:
          fromUnhandledPromise: true

  if config.GA_ID
    ga('create', config.GA_ID, 'auto')

  Promise.longStackTraces()

  Handlebars.registerHelper 'date', (date, format = 'YYYY-MM-DD HH:mm') ->
    moment(date).format(format)

  controller = window.Controller = new Controller

  Backbone.history.start()
