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
          officers: { validator: validators.bool(), default: false }

          clubs: { validator: validators.bool(), default: false }
          club_reports: { validator: validators.bool(), default: false }
          club_forms: { validator: validators.bool(), default: false }

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

          if req.args.clubs
            extras.clubs = req.model.loadClubs()
            .map (club) =>
              if req.args.club_reports
                club_reports = club.loadReports()
              if req.args.club_forms
                club_forms = club.loadForms()

              Promise.join club_reports, club_forms, (club_reports, club_forms) =>
                response = club.toJSON()
                if club_reports
                  response.reports = club_reports
                if club_forms
                  response.forms = club_forms
                return response

          if req.args.stats
            extras.stats = req.model.loadClubs()
            .map (club) =>
              club._id
            .then (idClubs) =>
              Stats.reportsByMonth(req.args.stats_start, req.args.stats_end, idClubs)

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
