Handler = require('./handler')
Db = App.module('database')
Emailer = App.module('emailer')
EntityHandler = require('./mixins/entityHandler')
Stats = App.lib('stats')

validators = require('./validators')

class Club extends Handler
  Util.mixin EntityHandler, @

  path: 'clubs'
  collection: 'Club'

  handlers:
    get:
      '':
        permissions: ['read']
        arguments:
          reports: { validator: validators.bool(), default: false }
          forms: { validator: validators.bool(), default: false }
          officers: { validator: validators.bool(), default: false }

          stats: { validator: validators.bool(), default: false }
          stats_start: { validator: validators.date(), optional: true }
          stats_end: { validator: validators.date(), optional: true }
        fx: (req) ->
          extras = {}
          if req.args.reports
            extras.reports = req.model.loadReports()
          if req.args.forms
            extras.forms = req.model.loadForms()
          if req.args.officers
            extras.officers = @getOfficers(req.model)
          if req.args.stats
            extras.stats = Stats.reportsByMonth(req.args.stats_start, req.args.stats_end, [req.model._id])

          Promise.props(extras).then (extras) =>
            response = req.model.toJSON()

            for key, val of extras
              if val?
                response[key] = val

            return response

    post:
      '/officers':
        permissions: ['write|manage']
        arguments:
          name: { validator: validators.string(), optional: true }
          email: { validator: validators.email() }
          start: { validator: validators.date() }
          end: { validator: validators.date() }
        fx: (req) ->
          @addOfficer(req)


module.exports = Club
