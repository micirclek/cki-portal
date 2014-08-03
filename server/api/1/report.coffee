Handler = require('./handler')
Db = App.module('database')
Emailer = App.module('emailer')

moment = require('moment')
validators = require('./validators')

class Report extends Handler
  path: 'reports'
  collection: 'Report'

  validateAnswers = (answers, questions, final = false) ->
    if final
      for question in questions
        answers = _.where(answers, { question: question.name })

        if answers.length == 0
          if question.properties?.required
            throw Error.ApiError('Question ' + question.name + ' is required', 400)
        else if answers.length > 1
          throw Error.ApiError('Question ' + question.name + ' should only have one answer', 400)

    _.map answers, (answer) ->
      question = _.findWhere(questions, { name: answer.question })
      { value } = answer
      value =
        switch question.type
          when 'table'
            value
          when ['text', 'block']
            if _.isString(value)
              value
          when 'integer'
            parseInt(value, 10)
          when 'number'
            parseFloat(value)
          when 'select'
            if value in question.properties.options
              value
          when 'date'
            Util.getDate(value)
          when 'bool'
            Util.getBool(value)

      if !value?
        throw Error.ApiError('Invalid value for ' + question.name, 400)

      return { question: question.name, value }

  loadAuxModels: (model) ->
    if !model
      return Promise.resolve({})

    form = Db.Form.findById(model.idForm).exec()
    entity = Db[model.for.modelType].findById(model.for.idModel).exec()

    Promise.props({ form, entity }).tap ({ form, entity }) =>
      if !form || !entity
        throw Error.ApiError('Could not find entity', 500)

  verifyPermissions: (request) ->
    { permissions } = request.handler
    { me, model, auxModels } = request

    if me.admin
      return true

    for permission in permissions
      valid = switch permission
        when 'read'
          me.hasAccess(auxModels.entity, 'view')
        when 'write'
          if !model
            true
          else if model.submitted
            me.hasAccess(auxModels.entity, 'manage')
          else
            me.hasAccess(auxModels.entity, 'edit')
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
          dateFor: { validator: validators.date, optional: true }
          serviceHours: { validator: validators.number, optional: true }
          interclubs: { validator: validators.integer, optional: true }
          kfamEvents: { validator: validators.integer, optional: true }
          answers: { validator: validators.array(validators.reportAnswer), optional: true }
        fx: (req) ->
          { form, entity } = req.auxModels

          if req.args.answers?
            answers = validateAnswers(req.args.answers, form.questions)
            for answer in answers
              req.model.setAnswer(answer)

          for simple in ['dateFor', 'serviceHours', 'interclubs', 'kfamEvents']
            if req.args[simple]?
              req.model[simple] = req.args[simple]

          Promise.ninvoke(req.model, 'save').spread (model) ->
            model

      '/submitted':
        permissions: ['write']
        arguments:
          value: { validator: validators.bool }
        fx: (req) ->
          if !req.args.value
            req.model.submitted = false
            req.model.dateSubmitted = null
            return Promise.ninvoke(req.model, 'save').spread (model) =>
              model

          { form, entity } = req.auxModels
          validateAnswers(req.model.answers, form.questions, true)

          monthStart = new Date(req.model.dateFor.getFullYear(), req.model.dateFor.getMonth())
          monthEnd = new Date(req.model.dateFor.getFullYear(), req.model.dateFor.getMonth() + 1)

          countOthers = Db.Report.count
            'for.idModel': req.model._id
            dateFor: { $gte: monthStart, $lt: monthEnd }
            submitted: true

          Promise.resolve(countOthers.exec())
          .then (count) =>
            if count
              throw Error.ApiError('Report for that month already submitted', 409)

            req.model.submitted = true
            req.model.dateSubmitted = Date()

            Promise.ninvoke(req.model, 'save')
          .spread (model) =>
            model # get rid of useless second argument
          .tap =>
            data = req.model.toJSON()
            data.entityName = entity.name + ' ' + req.model.for.modelType
            data.monthFor = moment(req.model.dateFor).format('MMMM')
            data.url = Settings.get('server.fullDomain') + "/#reports/" + req.model.id

            if req.model.for.modelType == 'Club'
              directOfficers = Db.User.findByPosition(level: 'club', idClub: entity.id)
              superOfficers = Db.User.findByPosition(level: 'district', idDistrict: entity.idDistrict)
            else if req.model.for.modelType == 'District'
              directOfficers = Db.User.findByPosition(level: 'district', idDistrict: entity.id)
              superOfficers = Db.User.findByPosition(level: 'international')

            Promise.join directOfficers.exec(), superOfficers.exec(), (directOfficers, superOfficers) =>
              Emailer.send
                subject: data.monthFor + ' MRF Submitted by the ' + data.entityName
                to: _.pluck(superOfficers, 'email')
                cc: _.union(_.pluck(directOfficers, 'email'), [req.me.email])
                data: data
                template: 'mrf_submitted'

    post:
      '':
        permissions: ['write']
        noId: true
        arguments:
          idForm: { validator: validators.id }
          for: { validator: validators.reportFor }
          dateFor: { validator: validators.date }
          serviceHours: { validator: validators.number }
          interclubs: { validator: validators.integer }
          kfamEvents: { validator: validators.integer }
          answers: { validator: validators.array(validators.reportAnswer) }
        fx: (req) ->
          form = Db.Form.findById(req.args.idForm)
          entity = Db[req.args.for.modelType].findById(req.args.for.idModel)

          Promise.join form.exec(), entity.exec(), (form, entity) =>
            if !form || !entity
              throw Error.ApiError('Invalid entity loaded', 400)

            # form is for entity
            if form.for.modelType != req.args.for.modelType
              throw Error.ApiError('Form is not for this entity')

            if form.for.modelType == 'Club' && !entity.idDistrict.equals(form.for.idDistrict)
              throw Error.ApiError('Form is not for clubs in this district')

            idField = 'id' + form.for.modelType
            positions = req.me.getCurrentPositions()
            if !_.find(positions, (position) -> entity._id.equals(position[idField]))
              throw Error.ApiError('User does not have permission to report for this entity', 403)

            answers = validateAnswers(req.args.answers, form.questions)

            report =
              idForm: req.args.idForm
              for: req.args.for
              dateFor: req.args.dateFor
              serviceHours: req.args.serviceHours
              interclubs: req.args.interclubs
              kfamEvents: req.args.kfamEvents
              answers: answers

            Promise.resolve(Db.Report.create(report))

module.exports = Report
