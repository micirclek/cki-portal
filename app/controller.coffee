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

  wait: (requireAuth = false) ->
    Promise.try =>
      if !Session.loggedIn()
        if requireAuth
          Util.showAlert('You must be logged in to view this page')
          @navigate('', trigger: true, replace: true)
        return
      if Session.me.synced
        return
      new Promise (resolve, reject) =>
        @listenToOnce Session.me, 'change:synced', resolve

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
        return $('#content').html(new LoginView().render().el)

      try
        position = @getPosition(level)
        url = position.get('level') + '/' + position.getLevelId() + '/home'
        @navigate(url, trigger: true, replace: true)
      catch err
        if err.message in ['noPosition', 'multiplePositions']
          $('#content').html(new WelcomeView().render().el)
        else
          throw err
    .catch (err) =>
      Util.showAlert(err.message)
    .done()

  account: ->
    @wait().then =>
      $('#content').html(new AccountView(model: Session.me).render().el)
    .done()

  clubHome: (idClub) ->
    @wait(true).then =>
      club = new Club(_id: idClub)

      serviceYearStart = Util.getServiceYear()[0..3]

      data =
        reports: true
        forms: true
        stats: true
        stats_start: moment(year: serviceYearStart - 1, month: 3).toDate()
        officers: true

      club.fetch({ data }).then =>
        landingView = new LandingView(model: club)
        $('#content').html(landingView.render().el)

  districtHome: (idDistrict) ->
    @wait(true).then =>
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
        landingView = new LandingView(model: district)
        $('#content').html(landingView.render().el)

  newReport: (level, idEntity, idForm) ->
    @wait(true).then =>
      report = new Report
        for: {
          idModel: idEntity
          modelType: Util.ucFirst(level)
        }

      if !report.editable()
        Util.showAlert('You do not have access to create a report for this ' + level)
        return

      form = new Form(_id: idForm)
      form.fetch().then ->
        report.set(idForm: form.id)

        view = new ReportView({ model: report, form })
        $('#content').html(view.render().el)

  openReport: (idReport) ->
    @wait(true).then =>
      report = new Report(_id: idReport)
      report.fetch().then ->
        form = new Form(_id: report.get('idForm'))
        form.fetch().then ->
          view = new ReportView({ model: report, form })
          $('#content').html(view.render().el)

module.exports = Controller
