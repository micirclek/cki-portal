Handler = require('./handler')
Db = App.module('database')

validators = require('./validators')

class User extends Handler
  path: 'users'
  collection: 'User'

  # need to override this so we can take usernames as well
  loadModel: (request) ->
    id = request.req.params.id
    if Util.checkId(id)
      return super
    else if id == 'me'
      return Promise.resolve(request.me)
    else if _.isString(id)
      return Promise.resolve(Db.User.findByEmail(id).exec()).then (user) ->
        if !user?
          throw Error.ApiError('Unknown user', 400)
        return user
    else
      return Promise.Reject(Error.ApiError('Invalid user id', 400))

  verifyPermissions: (request) ->
    permissions = request.handler.permissions

    if request.me.admin
      return

    for permission in permissions
      switch permission
        when 'admin'
          throw Error.ApiError('Invalid permissions requested', 403)
        when 'read', 'write'
          if !request.me
            throw Error.ApiError('Must be logged in', 401)
          if request.me.id != request.model.id
            throw Error.ApiError('Invalid permissions requested', 403)
        else
          throw Error('Unknown permission requested')

  getLoginTypes: (model) ->
    loginTypes = []
    if model.hash
      loginTypes.push('password')

    for credential in model.credentials
      loginTypes.push(credential.provider)

    return _.uniq(loginTypes)


  handlers:
    get:
      '':
        arguments:
          position_names: { validator: validators.bool(), default: false }
        permissions: ['read']
        fx: (req) ->
          extras = {}
          response = _.omit(req.model.toJSON(), 'credentials', 'hash', 'salt')

          if req.args.position_names
            idClubs = _.chain(req.model.positions).map (position) =>
              if position.level == 'club'
                return position.idClub
            .compact().value()

            idDistricts = _.chain(req.model.positions).map (position) =>
              if position.level == 'district'
                return position.idDistrict
            .compact().value()

            clubs = Db.Club.find({ _id: { $in: idClubs } }, { name: 1 }).exec()
            districts = Db.District.find({ _id: { $in: idDistricts } }, { name: 1 }).exec()
            extras.position_names = Promise.props({ clubs, districts })
            .then ({ clubs, districts }) =>
              Promise.each response.positions, (position) =>
                if position.level == 'club'
                  club = _.findWhere(clubs, id: position.idClub.toString())
                  position.entityName = club?.name ? ''
                else if position.level == 'district'
                  district = _.findWhere(districts, id: position.idDistrict.toString())
                  position.entityName = district?.name ? ''
                else if position.level == 'international'
                  position.entityName = 'Circle K International'

          Promise.props(extras).then =>
            response.loginTypes = @getLoginTypes(req.model)
            return response

    put:
      '':
        permissions: ['write']
        arguments:
          name: { validator: validators.string() }
        fx: (req) ->
          req.model.name = req.args.name
          Promise.ninvoke(req.model, 'save').then =>
            response = _.omit(req.model.toJSON(), 'credentials', 'hash', 'salt')
            response.loginTypes = @getLoginTypes(req.model)
            return response

      '/name':
        permissions: ['write']
        arguments:
          value: { validator: validators.string() }
        fx: (req) ->
          req.model.name = req.args.value
          Promise.ninvoke(req.model, 'save').then =>
            response = _.omit(req.model.toJSON(), 'credentials', 'hash', 'salt')
            response.loginTypes = @getLoginTypes(req.model)
            return response

    post:
      '/setPassword':
        permissions: ['write']
        arguments:
          oldPassword: { validator: validators.string(), optional: true }
          newPassword: { validator: validators.string(4) }
        fx: (req) ->
          allowed = if req.model.hash
            Promise.ninvoke(req.model, 'authenticate', req.args.oldPassword)
            .then (user) => # user will either be this model or a weird array
              if user?.id != req.model.id
                throw Error.ApiError('Old Password Incorrect', 400)
          else
            Promise.resolve()

          allowed.then =>
            Promise.ninvoke(req.model, 'setPassword', req.args.newPassword)
          .then =>
            Promise.ninvoke(req.model, 'save')
          .then =>
            response = _.omit(req.model.toJSON(), 'credentials', 'hash', 'salt')
            response.loginTypes = @getLoginTypes(req.model)
            return response

module.exports = User
