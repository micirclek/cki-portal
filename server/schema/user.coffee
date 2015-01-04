Schema = require('./')

Db = App.module('database')

crypto = require('crypto')
ms = require('ms')
passportLocalMongoose = require('passport-local-mongoose')

PositionSchema = new Schema 'Position',
  start: Date
  end: Date
  level: { type: String, enum: ['international', 'district', 'club'] }
  idDistrict: Schema.ObjectId
  idClub: Schema.ObjectId

SessionSchema = new Schema 'Session',
  token: String
  expires: Date

UserSchema = new Schema 'User',
  name: String
  email: String
  admin: Boolean
  credentials: [{
    email: String
    provider: { type: String, enum: ['google', 'password'] }
  }]

  # the passport-local-mongoose plugin also adds hash and salt as strings here

  positions: [PositionSchema]

  sessions: [SessionSchema]

UserSchema.index('credentials.email': 1)
UserSchema.index('sessions.token': 1)
UserSchema.index('positions.level': 1, 'positions.idDistrict': 1, 'positions.idClub': 1, 'positions.end': 1)

UserSchema.plugin passportLocalMongoose,
  usernameLowerCase: true
  usernameField: 'email'

UserSchema.methods.confirmEmail = (email) ->
  Promise.resolve(Db.User.findByEmail(email).exec())
  .then (user) =>
    if user && user.id != @id
      throw Error('A user with that email already exists')

    Db.Invitation.find({ email }).exec()
  .each (invitation) =>
    if invitation.name && !@name
      @name = invitation.name

    @positions.push
      start: invitation.start
      end: invitation.end
      level: invitation.modelType.toLowerCase()
      idDistrict: invitation.idDistrict
      idClub: invitation.idClub

    Promise.ninvoke(invitation, 'remove')
  .then =>
    if !_.findWhere(@credentials, { email })?
      @credentials.push
        email: email
        provider: 'password'

    Promise.ninvoke(@, 'save')
  .then =>
    return @

UserSchema.methods.getCurrentPositions = ->
  _.filter @positions, (position) ->
    # have not yet started in your position
    if position.start? && position.start > Date.now()
      return false

    # already done with your term
    if position.end? && position.end < Date.now()
      return false

    return true

UserSchema.methods.getNewSession = ->
  token = crypto.randomBytes(64).toString('hex')
  @sessions.push
    token: token
    expires: new Date(Date.now() + ms('1y'))
  Promise.ninvoke(@, 'save')
  .then =>
    return token

# model is designed to be passed in either as the model that is attempting to
# be accessed, or as an object with information on that model.  If you are
# passing it in as an object:
#   typeName: type to check
#   id: id of the model
#   idDistrict: if the model is a club, the id of the district it is in
#
# Omitting either of the ids will cause it to function essentially as a
# wildcard.  For example, checking (typeName: 'Club', 'view') will see if the
# user has permission to view every single club there is.
UserSchema.methods.hasAccess = (model, access) ->
  positions = @getCurrentPositions()

  if model.typeName == 'Club'
    if access == 'view'
      return _.any positions, (position) ->
        (position.level == 'international') ||
        (position.level == 'district' && model.idDistrict.equals(position.idDistrict)) ||
        (position.level == 'club' && position.idClub.equals(model.id))
    else if access == 'edit'
      return _.any positions, (position) ->
        (position.level == 'club' && position.idClub.equals(model.id))
    else if access == 'manage'
      return _.any positions, (position) ->
        (position.level == 'district' && model.idDistrict.equals(position.idDistrict))
  else if model.typeName == 'District'
    if access == 'view'
      return _.any positions, (position) ->
        (position.level == 'international') ||
        (position.level == 'district' && position.idDistrict.equals(model.id))
    else if access == 'edit'
      return _.any positions, (position) ->
        (position.level == 'district' && position.idDistrict.equals(model.id))
    else if access == 'manage'
      return _.any positions, (position) ->
        (position.level == 'international')

  throw Error('Could not get position information')
  # international is excluded now since we have not yet gone into that

UserSchema.statics.findByEmail = (email, cb) ->
  @findOne({
    $or: [
      { email }
      { credentials: { $elemMatch: { email} } }
    ]
  }, cb)

UserSchema.statics.findByPosition = ({ level, idDistrict, idClub }) ->
  search =
    positions:
      $elemMatch:
        $and: [
          {
            $or: [
              { start: $lte: new Date() },
              { start: null }
            ]
          },
          {
            $or: [
              { end: $gte: new Date() },
              { end: null }
            ]
          }
        ]
  if level?
    search.positions.$elemMatch.$and.push({ level })
  if idDistrict?
    search.positions.$elemMatch.$and.push({ idDistrict })
  if idClub?
    search.positions.$elemMatch.$and.push({ idClub })
  @find(search)

module.exports = UserSchema
