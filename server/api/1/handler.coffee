Db = App.module('database')
requireDir = require('require-dir')

class Request
  constructor: (@handler, @req, @res) ->
    @args = {}
    @me = @req.me

  processArguments: ->
    for name, about of @handler.arguments ? []
      if !about?
        throw Error('No argument information provided')

      query = _.extend({}, @req.query, @req.body)

      value = null
      if @req.params.hasOwnProperty(name)
        value = @req.params[name]
      else
        value = query[name]

      if !value?
        if about.default?
          value = about.default
        else if !about.optional
          throw Error.ApiError('No value provided')
      else if about.validator
        try
          value = @validateArgument(about, value)
        catch e
          if e !instanceof Error.ApiError
            Logger.error(e)

          throw Error.ApiError('Invalid value for ' + name, 400)

      @args[name] = value

  validateArgument: (about, value) ->
    { validator } = about
    if !_.isFunction(validator)
      throw Error('Invalid validator')

    return validator(value, about)

class Handler
  loadModel: (request) ->
    id = request.req.params.id
    if request.model? || request.handler.noId
      return Promise.resolve()

    if !(id? && Util.checkId(id))
      return Promise.reject(Error.ApiError('Invalid id', 400))

    Promise.resolve(Db[@collection].findById(request.req.params.id).exec())
    .then (model) ->
      if !model?
        throw Error.ApiError('Could not lookup model', 400)

      return model

  loadAuxModels: (model) ->
    Promise.resolve({})

  verifyPermissions: (permissions, request) ->
    # can be extended later

  handleRequest: (req, res, handler) ->
    request = new Request(handler, req, res)
    Promise.try =>
      if !handler.anonymous && !request.me?
        throw Error.ApiError('Please log in', 401)

      @loadModel(request)
    .then (model) =>
      request.model = model
      @loadAuxModels(model)
    .then (auxModels) =>
      request.auxModels = auxModels
      @verifyPermissions(request)
      request.processArguments()
      handler.fx.call(@, request)
    .then (result) ->
      res.send(result)
    .catch Error.ApiError, (err) ->
      res.status(err.statusCode).send(err.message)
    .catch (err) ->
      Logger.error(err.message, { err })
      res.status(500).send(err.message)
    .done()

  listen: (app) ->
    for method, routes of @handlers
      for route, handlers of routes
        if !_.isArray(handlers)
          handlers = [handlers]

        for handler in handlers

          fn = do (handler) =>
            (req, res) =>
              @handleRequest(req, res, handler, @)

          register = '/1/' + @path
          if !handler.noId
            register += '/:id'
          register += route

          Logger.debug("Registering #{ method }: #{ register }")
          app[method](register, fn)

  # okay, pretty obvious what this should be...
  @run: (route, options) ->
    throw Error('Not implemented')

  @listenAll: (app) ->
    @handlers ?= {}
    for file, handler of requireDir()
      if handler.prototype instanceof @
        @handlers[handler.path] = handler
        new handler().listen(app)

module.exports = Handler
