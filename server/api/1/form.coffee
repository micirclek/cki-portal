Handler = require('./handler')
Db = App.module('database')

validators = require('./validators')

class Form extends Handler
  path: 'forms'
  collection: 'Form'

  verifyPermissions: (request) ->
    permissions = request.handler.permissions
    { me, model } = request
    positions = me.getCurrentPositions()

    if me.admin
      return true

    for permission in permissions
      valid = switch permission
        when 'read'
          if model.for.modelType == 'Club'
            _.any positions, (position) ->
              (position.level in ['international', 'district']) ||
              (position.level == 'club' && position.idDistrict.equals(model.for.idDistrict))
          else if model.for.modelType == 'District'
            _.any positions, (position) ->
              position.level in ['international', 'district']
        when 'write'
          if !model
            # both international and district officers can make a form, we'll
            # check that the user is allowed to make that particular form
            # later
            _.any positions, (position) ->
              position.level in ['international', 'district']
          else if !model.active
            false # no one has permission to edit these
          else if model.for.modelType == 'Club'
            _.any positions, (position) ->
              position.level == 'district' && position.idDistrict.equals(model.for.idDistrict)
          else if model.for.modelType == 'District'
            _.any positions, (position) -> position.level == 'international'
        else
          throw Error('Unknown permission requested')

      if !valid
        throw Error.ApiError('invalid permission requested')
  handlers:
    get:
      '':
        permissions: ['read']
        fx: (req) ->
          req.model

    put:
      '':
        permissions: ['write']
        arguments:
          name: { validator: validators.string(), optional: true }
          questions: { validator: validators.array(validators.formQuestion()) }
          sections: { validator: validators.array(validators.formSection()) }
        fx: (req) ->
          Promise.try =>
            if req.args.name?
              req.model.name = req.args.name

            if req.model.published
              # we can update any section title/subtitle or any question prompt
              for question in req.args.questions
                existing = _.findWhere(req.model.questions, { name: question.name })
                existing?.prompt = question.prompt
              for section in req.args.sections
                existing = _.findWhere(req.model.sections, { name: section.name })
                existing?.title = section.title
                existing?.subtitle = section.subtitle
              return

            # we can update anything we feel like
            req.model.questions = req.args.questions
            req.model.sections = req.args.sections
          .then =>
            Promise.ninvoke(req.model, 'save')
          .then =>
            return req.model

      '/published':
        permissions: ['write']
        arguments:
          value: { validator: validators.bool() }
        fx: (req) ->
          if !req.args.value || req.model.published
            throw Error.ApiError('Cannot unpublish a form')

          req.model.published = true
          Promise.ninvoke(req.model, 'save').then =>
            return req.model

      '/active':
        permisisons: ['write']
        arguments:
          value: { validator: validators.bool() }
        fx: (req) ->
          if req.args.value || !req.model.active
            throw Error.ApiError('Cannot reactivate a form')

          req.model.active = false
          Promise.ninvoke(req.model, 'save').then =>
            return req.model

    post:
      '':
        permissions: ['write']
        noId: true
        arguments:
          name: { validator: validators.string(), optional: true }
          for: { validator: validators.formFor() }
          questions: { validator: validators.array(validators.formQuestion()) }
          sections: { validator: validators.array(validators.formSection()) }
        fx: (req) ->
          Promise.try =>
            # verify that we are allowed to create this form
            # we are going to cheat a bit for checking permissions
            if req.args.for.modelType == 'District'
              if !req.me.hasAccess(typeName: 'District', 'manage')
                throw Error.ApiError('User does not have permission to create this form', 403)
            else if req.args.for.modelType == 'Club'
              Promise.resolve(Db.District.findById(req.args.for.idDistrict).exec())
              .then (district) =>
                if !district
                  throw Error.ApiError('District does not exist')

                if !req.me.hasAccess(typeName: 'Club', idDistrict: district._id, 'manage')
                  throw Error.ApiError('User does not have permission to create this form', 403)
          .then =>
            sectionNames = _.pluck(req.args.sections, 'name')
            questionNames = _.pluck(req.args.questions, 'name')
            if _.uniq(sectionNames).length != sectionNames.length
              throw Error.ApiError('Duplicate section name')
            if _.uniq(questionNames).length != questionNames.length
              throw Error.ApiError('Duplicate question name')

            for question in req.args.questions
              if question.section !in sectionNames
                throw Error.ApiError('Unknown section name ' + question.section, 400)

            form =
              for: req.args.for
              questions: req.args.questions
              sections: req.args.sections

            if req.args.name?
              form.name = req.args.name

            Promise.resolve(Db.Form.create(form))

module.exports = Form
