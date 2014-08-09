Handler = require('./handler')
Db = App.module('database')

ms = require('ms')
passport = require('passport')
validators = require('./validators')

class Auth extends Handler
  path: 'auth'

  startSession: (req) ->
    req.req.me.getNewSession()
    .then (token) =>
      token = req.req.me.id + '/' + token
      req.res.cookie('token', token, expires: new Date(Date.now() + ms('1y')), secure: req.req.protocol == 'https')
      return token

  handlers:
    get:
      '':
        noId: true
        anonymous: true
        fx: (req) ->
          _.omit(req.me?.toJSON() ? {}, 'credentials', 'hash', 'salt')

      '/google':
        noId: true
        anonymous: true
        fx: (req) ->
          strategy = passport.authenticate 'google',
            session: false
            stateless: true
            scope: 'openid email profile'
          Promise.nfcall(strategy, req.req, req.res)


      '/google/callback':
        noId: true
        anonymous: true
        fx: (req) ->
          strategy = passport.authenticate('google', { session: false, stateless: true })
          Promise.nfcall(strategy, req.req, req.res)
          .then =>
            @startSession(req)
          .then (token) =>
            req.res.redirect('/')

    post:
      '/register':
        noId: true
        anonymous: true
        arguments:
          email: { validator: validators.email() }
          password: { validator: validators.string(4) }
        fx: (req) ->
          email = req.args.email

          if req.me
            throw Error.ApiError('You cannot register a new account while logged in')

          req.me = req.req.me = new Db.User({ email })
          # confirm the email first, mostly as a check that it does not exist already
          req.me.confirmEmail(email) # TODO actually require the email to be confirmed
          .catch (err) =>
            throw Error.ApiError(err)
          .tap =>
            Promise.ninvoke(req.me, 'setPassword', req.args.password)
          .tap =>
            @startSession(req)
          .then =>
            _.omit(req.req.me.toJSON(), 'credentials', 'hash', 'salt')

      '/login':
        noId: true
        anonymous: true
        arguments:
          email: { validator: validators.email() }
          password: { validator: validators.string() }
        fx: (req) ->
          strategy = passport.authenticate('local', { session: false })
          Promise.nfcall(strategy, req.req, req.res)
          .then =>
            @startSession(req)
          .then =>
            _.omit(req.req.me.toJSON(), 'credentials', 'hash', 'salt')

      '/logout':
        noId: true
        anonymous: true
        fx: (req) ->
          { token } = Util.getToken(req.req)
          _.findWhere(req.me.sessions, { token }).remove()
          Promise.ninvoke(req.me, 'save').then =>
            req.res.clearCookie('token')
            req.req.logout()
          .catch (err) =>
            Logger.error(msg: 'Error logging out', err: err)
          .then =>
            return {}

module.exports = Auth
