Club = require('models/club')
District = require('models/district')
Form = require('models/form')
Report = require('models/report')

AccountView = require('views/account')
HeaderView = require('views/header')
LandingView = require('views/landing')
LoginView = require('views/login')
ReportView = require('views/report')
StaticView = require('views/static')
WelcomeView = require('views/welcome')

class Controller extends Backbone.Router
  initialize: ->
    @view = null
    @headerView = new HeaderView()
    $('#header').html(@headerView.render().el)
    @listenTo Session.me, 'change:_id', -> window.location.reload()

  routes:
    '': 'home'
    'home': 'home'
    ':level/home': 'home'
    'account': 'account'
    'club/:id': 'clubHome'
    'club/:id/home': 'clubHome'
    'district/:id': 'districtHome'
    'district/:id/home': 'districtHome'
    ':level/:id/report/new/:idForm': 'newReport'
    'reports/:id': 'openReport'

  switchView: (view) ->
    @view = view
    $('#content').html(view.render().el)

  wait: (requireAuth = false) ->
    if @view
      @view.stopListening()
    Promise.try =>
      if !Session.loggedIn()
        if requireAuth
          Util.showAlert('You must be logged in to view this page')
          @navigate('', trigger: true, replace: true)
        return false
      if Session.me.synced
        return true
      new Promise (resolve, reject) =>
        @listenToOnce Session.me, 'change:synced', =>
          resolve(Session.loggedIn())

  getPosition: (level) ->
    positions = Session.me.positions.getCurrent()
    if level
      positions = positions.filter (position) ->
        position.get('level') == level
    else
      positions = positions.toArray()

    if positions.length > 1
      throw Error('multiplePositions')
    else if positions.length < 1
      throw Error('noPosition')

    return _.first(positions)

  home: (level) ->
    @wait().then =>
      if !Session.loggedIn()
        return @switchView(new LoginView())

      try
        position = @getPosition(level)
        url = position.get('level') + '/' + position.getLevelId() + '/home'
        @navigate(url, trigger: true, replace: true)
      catch err
        if err.message in ['noPosition', 'multiplePositions']
          @switchView(new WelcomeView())
        else
          throw err
    .catch (err) =>
      Util.showAlert(err.message)
    .done()

  account: ->
    @wait(true).then (loggedIn) =>
      if !loggedIn
        return

      @switchView(new AccountView(model: Session.me))
    .done()

  clubHome: (idClub) ->
    @wait(true).then (loggedIn) =>
      if !loggedIn
        return

      club = new Club(_id: idClub)

      serviceYearStart = Util.getServiceYear()[0..3]

      data =
        reports: true
        forms: true
        stats: true
        stats_start: moment(year: serviceYearStart - 1, month: 3).toDate()
        officers: true

      club.fetch({ data }).then =>
        @switchView(new LandingView(model: club))
      .catch(Error.AjaxError, Util.noop)
    .done()

  districtHome: (idDistrict) ->
    @wait(true).then (loggedIn) =>
      if !loggedIn
        return

      district = new District(_id: idDistrict)

      serviceYearStart = Util.getServiceYear()[0..3]

      data =
        reports: true
        forms: true
        clubs: true
        club_reports: true
        stats: true
        stats_start: moment(year: serviceYearStart - 1, month: 3).toDate()
        officers: true

      district.fetch({ data }).then =>
        @switchView(new LandingView(model: district))
      .catch(Error.AjaxError, Util.noop)
    .done()

  newReport: (level, idEntity, idForm) ->
    @wait(true).then (loggedIn) =>
      if !loggedIn
        return

      report = new Report
        for: {
          idModel: idEntity
          modelType: Util.ucFirst(level)
        }

      if !report.editable()
        Util.showAlert('You do not have access to create a report for this ' + level)
        return

      form = new Form(_id: idForm)
      form.fetch().then =>
        report.set(idForm: form.id)

        @switchView(new ReportView({ model: report, form }))
      .catch(Error.AjaxError, Util.noop)
    .done()

  openReport: (idReport) ->
    @wait(true).then (loggedIn) =>
      if !loggedIn
        return

      report = new Report(_id: idReport)
      report.fetch().then =>
        form = new Form(_id: report.get('idForm'))
        form.fetch().then =>
          @switchView(new ReportView({ model: report, form }))
      .catch(Error.AjaxError, Util.noop)
    .done()

module.exports = Controller
