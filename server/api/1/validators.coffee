module.exports = validators =
  id: ->
    (value) ->
      if Util.checkId(value)
        return value

      throw Error.ApiError('Invalid id')

  array: (itemValidator) ->
    (values) ->
      for value in values
        itemValidator(value)

  date: ->
    (value) ->
      date = Util.getDate(value)
      if date?
        return date

      throw Error.ApiError('Invalid date')

  email: ->
    (value) ->
      # regex taken from http://stackoverflow.com/a/46181/732547
      re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
      if re.test(value)
        return value.toLowerCase()

      throw Error.ApiError('Invalid email address')

  formFor: ->
    (value) ->
      { modelType, idDistrict } = value
      if modelType == 'Club'
        if Util.checkId(idDistrict)
          return { modelType, idDistrict }
      else if modelType == 'District'
        return { modelType }

      throw Error.ApiError('Invalid formFor')

  reportFor: ->
    ({ modelType, idModel }) ->
      if Util.checkId(idModel) && _.isString(modelType) &&
          modelType in ['Club', 'District']
        return { modelType, idModel }

      throw Error.ApiError('Invalid reportFor')

  formQuestion: ->
    (question) ->
      { name, type, prompt, section, properties } = question
      if _.isString(name) && _.isString(type) && _.isString(prompt) &&
          _.isString(section) && (!properties? ||_.isObject(properties)) &&
          (type in Util.questionTypes)
        return { name, type, prompt, section, properties }

      throw Error.ApiError('Invalid value for form question')

  formSection: ->
    (section) ->
      { name, title, subtitle } = section
      if _.isString(name) && _.isString(title) && _.isString(subtitle)
        return { name, title, subtitle }

      throw Error.ApiError('Invalid form section')

  reportAnswer: ->
    (answer) ->
      { question, value } = answer
      if _.isString(question)
        return {question, value }

      throw Error.ApiError('Invalid answer')

  string: (min = 0, max = 16384) ->
    (value) ->
      if _.isString(value) && min <= value.length <= max
        return value

      throw Error.ApiError('String is outside of range', 400)

  number: (min = -Infinity, max = Infinity, integer = false) ->
    (value) ->
      if integer
        num = parseInt(value, 10)
      else
        num = parseFloat(value)

      if _.isFinite(value) && min <= num <= max
        return num

      throw Error.ApiError('Number exceeded range', 400)

  integer: (min, max) ->
    return validators.number(min, max, true)

  bool: ->
    (value) ->
      bool = Util.getBool(value)
      if bool?
        return bool
