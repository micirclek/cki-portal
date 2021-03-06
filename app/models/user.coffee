AppModel = require('models/appmodel')

class Position extends AppModel
  urlRoot: '/1/users/position'

  parse: (data) ->
    if data.start?
      data.start = new Date(data.start)
    if data.end?
      data.end = new Date(data.end)

    super

  defaults:
    start: null
    end: null
    level: null
    idDistrict: null
    idClub: null
    entityName: null # TODO this should eventually get handled by a magic cache

  getLevelId: (level = @get('level')) ->
    if /club/i.test(level)
      return @get('idClub')
    else if /district/i.test(level)
      return @get('idDistrict')
    else
      return null

class PositionCollection extends Backbone.Collection
  model: Position

  getCurrent: ->
    positions = @filter (position) ->
      # have not yet started in your position
      if position.has('start') && position.get('start') > Date.now()
        return false

      # already done with your term
      if position.has('end') && position.get('end') < Date.now()
        return false

      return true

    return new PositionCollection(positions)

Position.Collection = PositionCollection

class User extends AppModel
  typeName: 'User'
  urlRoot: '/1/users'

  parse: (data) ->
    @positions.set(data.positions, parse: true)
    delete data.positions

    super

  toJSON: ->
    data = super
    data.positions = @positions.toJSON()
    return data

  constructor: ->
    @positions = new PositionCollection()

    super

  hasAccess: (model, access = 'read') ->
    positions = @positions.getCurrent()
    if model.typeName == 'Club'
      if access == 'view'
        return positions.any (position) =>
          (position.get('level') == 'club' && position.id == model.id) ||
          (position.get('level') == 'district' && position.get('idDistrict') == model.get('idDistrict')) ||
          (position.get('level') == 'international')
      else if access == 'edit'
        return positions.any (position) =>
          position.get('level') == 'club' && position.get('idClub') == model.id
      else if access == 'manage'
        return positions.any (position) =>
          position.get('level') == 'district' && position.get('idDistrict') == model.get('idDistrict')
    else if model.typeName == 'District'
      if access == 'view'
        return positions.any (position) =>
          (position.get('level') == 'district' && position.get('idDistrict') == model.id) ||
          (position.get('level') == 'international')
      else if access == 'edit'
        return positions.any (position) =>
          position.get('level') == 'district' && position.get('idDistrict') == model.id
      else if access == 'manage'
        return positions.any (position) =>
          position.get('level') == 'international'

  setPassword: (oldPass, newPass) ->
    Backbone.ajax
      type: 'POST'
      url: @url() + '/setPassword'
      data:
        oldPassword: oldPass
        newPassword: newPass
    .then =>
      @set(loginTypes: _.uniq(_.union(@get('loginTypes'), ['password'])))

  defaults:
    _id: null
    name: ''
    email: ''
    admin: false

class UserCollection extends Backbone.Collection
  model: User

User.Collection = UserCollection

module.exports = User
