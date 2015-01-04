Handler = require('./handler')
Db = App.module('database')
EntityHandler = require('./mixins/entityHandler')
Stats = App.lib('stats')

validators = require('./validators')

class District extends Handler
  Util.mixin EntityHandler, @

  path: 'districts'
  collection: 'District'

  handlers:
    get:
      '':
        permissions: ['read']
        arguments:
          reports: { validator: validators.bool(), default: false }
          forms: { validator: validators.bool(), default: false }
          childForms: { validator: validators.bool(), default: false }
          officers: { validator: validators.bool(), default: false }

          clubs: { validator: validators.bool(), default: false }
          club_reports: { validator: validators.bool(), default: false }

          stats: { validator: validators.bool(), default: false }
          stats_start: { validator: validators.date(), optional: true }
          stats_end: { validator: validators.date(), optional: true }
        fx: (req) ->
          extras = {}
          if req.args.reports
            extras.reports = req.model.loadReports()
          if req.args.forms
            extras.forms = req.model.loadForms()
          if req.args.childForms
            extras.childForms = req.model.loadChildForms()
          if req.args.officers
            extras.officers = @getOfficers(req.model)

          if req.args.clubs
            club_reports =
              if req.args.club_reports
                req.model.loadChildReports()
              else
                Promise.resolve([])

            extras.clubs = Promise.join req.model.loadClubs(), club_reports, (clubs, reports) =>
              if reports?
                reports = _.groupBy reports, (report) ->
                  return report.for.idClub

              _.map clubs, (club) =>
                response = club.toJSON()
                if reports?
                  response.reports = _.map reports[club._id] ? [], (report) =>
                    _.pick(report.toJSON(), 'dateFor', 'submitted', '_id')
                return response

          if req.args.stats
            extras.stats = Stats.reportsByMonth(req.args.stats_start, req.args.stats_end, req.model._id)

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

module.exports = District
