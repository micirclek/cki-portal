module.exports = validators =
  id: (value) ->
    if Util.checkId(value)
      return value

  array: (itemValidator) ->
    (values) ->
      for value in values
        itemValidator(value)

  date: (value) ->
    Util.getDate(value)

  email: (value) ->
    # regex taken from http://stackoverflow.com/a/46181/732547
    re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    if re.test(value)
      return value.toLowerCase()

    throw Error('Invalid value for email address')

  formFor: (value) ->
    { modelType, idDistrict } = value
    if modelType == 'Club'
      if Util.checkId(idDistrict)
        return { modelType, idDistrict }
    else if modelType == 'District'
      return { modelType }

  reportFor: ({ modelType, idModel }) ->
    if Util.checkId(idModel) && _.isString(modelType) &&
        modelType in ['Club', 'District']
      return { modelType, idModel }

  formQuestion: (question) ->
    { name, type, prompt, section, properties } = question
    if _.isString(name) && _.isString(type) && _.isString(prompt) &&
        _.isString(section) && (!properties? ||_.isObject(properties)) &&
        (type in Util.questionTypes)
      return { name, type, prompt, section, properties }

    throw Error('Invalid value for form question')

  formSection: (section) ->
    { name, title, subtitle } = section
    if _.isString(name) && _.isString(title) && _.isString(subtitle)
      return { name, title, subtitle }

  reportAnswer: (answer) ->
    { question, value } = answer
    if _.isString(question)
      return {question, value }

    throw Error('Invalid value for report answer')

  string: { stringInRange: { min: 0, max: 16384 } }
  number: { numberInRange: { min: -Infinity, max: Infinity } }
  integer: { numberInRange: { min: -Infinity, max: Infinity, integer: true } }
  bool: (value) ->
    Util.getBool(value)
