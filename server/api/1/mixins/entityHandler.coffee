Db = App.module('database')
Emailer = App.module('emailer')

moment = require('moment')

class EntityHandler
  # a very simple verifyPermissions handler that just checks the basic types
  # against user.hasAccess
  verifyPermissions: (request) ->
    { permissions } = request.handler
    { me, model } = request

    if me.admin
      return

    for permission in permissions
      valid = switch permission
        when 'read'
          me.hasAccess(model, 'view')
        when 'write'
          me.hasAccess(model, 'edit')
        when 'manage'
          me.hasAccess(model, 'manage')
        when 'write|manage'
          me.hasAccess(model, 'edit') || me.hasAccess(model, 'manage')
        else
          throw Error('Unknown permission requested')

      if !valid
        throw Error.ApiError('invalid permission requested')

  getOfficers: (model) ->
    query =
      level: model.typeName.toLowerCase()
    query['id' + model.typeName] = model.id
    active = Db.User.findByPosition(query).exec()

    invited = Db.Invitation.find(modelType: model.typeName)
    invited.where('id' + model.typeName, model._id)
    invited = invited.exec()

    return Promise.props({ active, invited })
    .then ({ active, invited }) =>
      officers = []
      for member in active
        officers.push({ email: member.email, confirmed: true })
      for invitation in invited
        officers.push({ email: invitation.email, confirmed: false })
      return officers

  addOfficer: (req) ->
    data =
      name: req.model.name
      type: req.model.typeName
      start: req.args.start
      end: req.args.end
      email: req.args.email

    if req.model.idDistrict?
      data.idClub = req.model.id
      data.idDistrict = req.model.idDistrict
    else
      data.idDistrict = req.model.id

    Promise.resolve(Db.User.findByEmail(data.email).exec())
    .then (user) =>
      if user
        user.positions.push
          start: data.start
          end: data.end
          level: data.type.toLowerCase()
          idDistrict: data.idDistrict
          idClub: data.idClub
        return Promise.ninvoke(user, 'save').then =>
          return true

      lookup = Db.Invitation.findOne
        email: data.email
        idClub: data.idClub
        idDistrict: data.idDistrict
        modelType: data.type
      Promise.resolve(lookup.exec()).then (invitation) =>
        isNew = false
        if !invitation
          isNew = true
          invitation = new Db.Invitation
            email: data.email
            start: data.start
            end: data.end
            idClub: data.idClub
            idDistrict: data.idDistrict
            modelType: data.type

        invitation.start = moment.min(moment(data.start), moment(invitation.start)).toDate()
        invitation.end = moment.max(moment(data.end), moment(invitation.end)).toDate()

        Promise.ninvoke(invitation, 'save')
        .then =>
          if isNew
            data.url = Settings.get('server.fullDomain')
            Emailer.send
              subject: 'You have been added as an officer of the ' + data.name + ' ' + data.type
              to: data.email
              data: data
              template: 'invitation'

          return false
    .then (confirmed) =>
      return { email: data.email, confirmed: confirmed }

module.exports = EntityHandler
