passport = require('passport')
Db = App.module('database')

class TokenStrategy extends passport.Strategy
  constructor: ->
    super
    @name = 'token'

  authenticate: (req, options = {}) ->
    token = null

    try
      { idUser, token } = Util.getToken(req)
    catch
      return @pass()

    Promise.resolve(Db.User.findOne({ 'sessions.token': token }).exec()).then (user) =>
      if !user || user.id != idUser || _.findWhere(user.sessions, { token }).expires < Date.now()
        req.res.clearCookie('token')
        return @pass()

      @success(user)

module.exports.Strategy = TokenStrategy
