# initial requires (set up coffeescript stuff)
require('coffee-backtrace')

# reqired for the globals
path = require('path')
winston = require('winston')
ROOT_DIRECTORY = __dirname

# globals
global.Promise = require('bluebird')
global.App =
  module: (name) ->
    require(path.join(ROOT_DIRECTORY, 'server/module', name))

  lib: (name) ->
    require(path.join(ROOT_DIRECTORY, 'server/lib', name))

  path: (relpath...) ->
    path.join(ROOT_DIRECTORY, relpath...)
global._ = require('underscore')
global.Settings = require('config')
global.Util = require('./server/util')
global.Logger = new winston.Logger

bodyParser = require('body-parser')
cookieParser = require('cookie-parser')
express = require('express')
favicon = require('serve-favicon')
fs = require('fs')
http = require('http')
https = require('https')
loggly = require('winston-loggly')
morgan = require('morgan')
passport = require('passport')
path = require('path')
raven = require('raven')
requireDir = require('require-dir')

Handler = require(App.path('server/api/1/handler'))
LocalStrategy = require('passport-local').Strategy
RavenLogger = App.lib('ravenLogger')

# require and initialize modules
Db = App.module('database').initialize()
Emailer = App.module('emailer').initialize()

requireDir(App.path('server/ext'))
require(App.path('templates')) # handlebars templates

Logger.add(winston.transports.Console, level: Settings.get('logging.consoleLevel'))

if Settings.get('logging.logglyLevel') != 'silent'
  Logger.add loggly.Loggly,
    level: Settings.get('logging.logglyLevel')
    subdomain: Settings.get('logging.logglySubdomain')
    inputToken: Settings.get('logging.logglyToken')
    json: true
    stripColors: true

if Settings.get('logging.ravenLevel') != 'silent'
  ravenClient = new raven.Client(Settings.get('logging.sentryDSN'))
  Logger.add RavenLogger,
    level: Settings.get('logging.ravenLevel')
    raven: ravenClient

app = express()

# do not log url parameters
morgan.token('url', (req, res) -> req.path)

loggerStream =
  write: (message) ->
    Logger.info(message.trim())

app.set('port', Number(process.env.PORT || Settings.get('server.port')))
app.use(morgan('dev', stream: loggerStream))
app.use(bodyParser.json())
app.use(bodyParser.urlencoded(extended: true))
app.use(cookieParser(Settings.get('secret')))
app.use(favicon(App.path(Settings.get('paths.staticPath'), '/favicon.ico')))
app.use(express.static(App.path(Settings.get('paths.staticPath'))))

app.use passport.initialize
  userProperty: 'me'

app.use(passport.authenticate('token'))

Handler.listenAll(app)

server = http.createServer(app)
server.listen app.get('port'), ->
  Logger.debug('Express server listening on port ' + app.get('port'))
