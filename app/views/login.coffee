AppView = require('views/appview')
User = require('models/user')

class LoginView extends AppView
  events:
    'click .js-login': 'login'
    'click .js-register': 'register'

  render: ->
    @$el.html(@template('login'))
    return @

  login: ->
    email = @$('#email').val()
    password = @$('#password').val()
    Session.login(email, password)
    .catch (err) =>
      Util.showAlert("Invalid username or password")
    .done()
    return false

  register: ->
    email = @$('#email').val()
    password = @$('#password').val()
    Session.register(email, password).done()

    return false

module.exports = LoginView
