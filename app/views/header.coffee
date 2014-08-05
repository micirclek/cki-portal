AppView = require('views/appview')

class HeaderView extends AppView
  className: 'navbar navbar-inverse navbar-fixed-top'

  events:
    'click .logout': 'logout'
    'submit form': 'login'

  initialize: ->
    super
    @listenTo Session.me, 'change', @render
    @listenTo Session.me, 'change:positions', @render

  render: ->
    data = Session.me.toJSON()
    data.noPositions = !data.positions.length
    data.multiplePositions = data.positions.length > 1

    $(@el).html(@template('header', data))
    return @

  logout: ->
    Session.logout().done()
    return false

  login: ->
    email = @$('#email').val()
    password = @$('#password').val()
    Session.login(email, password)
    return false

module.exports = HeaderView
