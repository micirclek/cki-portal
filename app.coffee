# initial requires (set up coffeescript stuff)
require('./server/lib/bootstrap')

bodyParser = require('body-parser')
config = require('config')
cookieParser = require('cookie-parser')
express = require('express')
favicon = require('serve-favicon')
fs = require('fs')
http = require('http')
https = require('https')
loggly = require('winston-loggly')
morgan = require('morgan')
passport = require('passport')
raven = require('raven')
requireDir = require('require-dir')
winston = require('winston')

Handler = require(App.path('server/api/1/handler'))
LocalStrategy = require('passport-local').Strategy
RavenLogger = App.lib('ravenLogger')

# require and initialize modules
Db = App.module('database').initialize
  host: config.get('db.host')
  name: config.get('db.name')
  port: config.get('db.port')
Emailer = App.module('emailer').initialize
  host: config.get('email.host')
  secure: config.get('email.secure')
  port: config.get('email.port')
  user: config.get('email.user')
  pass: config.get('email.password')
  from: config.get('email.from')
  enable: config.get('email.enable')

Logger.add(winston.transports.Console, level: config.get('logging.consoleLevel'))

if config.get('logging.logglyLevel') != 'silent'
  Logger.add loggly.Loggly,
    level: config.get('logging.logglyLevel')
    subdomain: config.get('logging.logglySubdomain')
    inputToken: config.get('logging.logglyToken')
    json: true
    stripColors: true

if config.get('logging.ravenLevel') != 'silent'
  ravenClient = new raven.Client(config.get('logging.sentryDSN'))
  Logger.add RavenLogger,
    level: config.get('logging.ravenLevel')
    raven: ravenClient

app = express()

# do not log url parameters
morgan.token('url', (req, res) -> req.path)

loggerStream =
  write: (message) ->
    Logger.info(message.trim())

app.set('port', Number(process.env.PORT || config.get('server.port')))
app.use(morgan('dev', stream: loggerStream))
app.use(bodyParser.json())
app.use(bodyParser.urlencoded(extended: true))
app.use(cookieParser(config.get('secret')))
app.use(favicon(App.path(config.get('paths.staticPath'), '/favicon.ico')))
app.use(express.static(App.path(config.get('paths.staticPath'))))

passport.use(Db.User.createStrategy())
passport.serializeUser(Db.User.serializeUser())
passport.deserializeUser(Db.User.deserializeUser())

app.use passport.initialize
  userProperty: 'me'

app.use(passport.authenticate('token'))

Handler.listenAll(app)

server = http.createServer(app)
server.listen app.get('port'), ->
  Logger.debug('Express server listening on port ' + app.get('port'))
