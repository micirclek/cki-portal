winston = require('winston')

class RavenLogger extends winston.Transport
  constructor: (options) ->
    @name = 'raven'
    @level = options.level ? 'info'
    @raven = options.raven
    super

  log: (level, msg, meta, next) ->
    extras = _.clone(meta)
    if extras.err?
      extras.msg = msg
      msg = extras.err
      delete extras.err

    if msg instanceof Error
      @raven.captureError(msg, { level, extras })
    else
      @raven.captureMessage(msg, { level, extras })

    next(null, true) # just say it was successful

module.exports = RavenLogger
