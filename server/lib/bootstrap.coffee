# initial requires (set up coffeescript stuff)
require('coffee-backtrace')

# reqired for the globals
path = require('path')
winston = require('winston')
ROOT_DIRECTORY = path.join(__dirname, '../..')

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
global.Util = require(App.path('/server/util'))
global.Logger = new winston.Logger

requireDir = require('require-dir')

requireDir(App.path('server/ext'))
require(App.path('templates')) # handlebars templates
