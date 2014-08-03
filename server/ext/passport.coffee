passport = require('passport')
Db = App.module('database')
GoogleStrategy = require('passport-google-oauth').OAuth2Strategy
TokenStrategy = App.module('passport-token').Strategy

passport.use(Db.User.createStrategy())
passport.serializeUser(Db.User.serializeUser())
passport.deserializeUser(Db.User.deserializeUser())

processAuth = (provider, profile) ->
  email = profile.emails[0].value.toLowerCase()

  Promise.resolve(Db.User.findByEmail(email).exec())
  .then (user) ->
    if !user
      user = new Db.User({ email })

    if !_.findWhere(user.credentials, { provider })
      user.credentials.push { email, provider }

    user.confirmEmail(email)

passport.use new GoogleStrategy {
    callbackURL: Settings.get('server.fullDomain') + '/1/auth/google/callback'
    clientID: Settings.get('auth.googleClientId'),
    clientSecret: Settings.get('auth.googleClientSecret'),
  }, (accessToken, refreshToken, profile, next) ->
    processAuth('google', profile).nodeify(next)

passport.use(new TokenStrategy)
