User = require('models/user')

class Session
  constructor: ->
    token = $.cookie('token')
    if token
      [ idUser, token ] = token.split('/')
    @me = new User(_id: idUser)

    if idUser?
      @setUserId(idUser)
      @me.fetch(data: { position_names: true })
      .catch =>
        @clear()
      .done()

  setUserId: (id) ->
    Raven.setUserContext({ id })
    ga('set', '&uid', id)

  login: (email, password) ->
    Backbone.ajax
      type: 'POST'
      url: '/1/auth/login'
      data: { email, password }
      handleError: false
    .then (me) =>
      @me.set(me)
      @setUserId(me.id)

  register: (email, password) ->
    Backbone.ajax
      type: 'POST'
      url: '/1/auth/register'
      data: { email, password }
    .then (me) =>
      @me.set(me)
      @setUserId(me.id)

  logout: ->
    # TODO we seem to be failing to handle this perfectly
    Backbone.ajax
      type: 'POST'
      url: '/1/auth/logout'
    .then =>
      Controller.navigate('', trigger: true)
      @me.clear()

  clear: ->
    $.removeCookie('token')
    @me.clear()
    Raven.setUserContext()
    ga('set', '&uid', null)

  loggedIn: ->
    return !@me.isNew()

module.exports = Session
