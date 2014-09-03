Util =
  checkId: (id) ->
    return id?.constructor.name == "ObjectID" || (id?.length == 24 && ///^[a-f0-9]*$///.test(id))

  getDate: (date) ->
    if _.isDate(date)
      return date

    if /^\d+$/.test(date)
      return new Date(parseInt(date, 10))
    else
      num = Date.parse(date)
      if _.isFinite(num)
        return new Date(num)

  getBool: (value) ->
    if value in [true, 'true', 1]
      true
    else if value in [null, false, 'false', 0]
      false

  mixin: (mixins..., classReference) ->
    for mixin in mixins
      for key, value of mixin::
        classReference::[key] = value
    classReference

  questionTypes: ['text', 'integer', 'number', 'block', 'date', 'bool', 'select', 'table']

  getToken: (req) ->
    if req.method == 'GET' && req.query?.token
      token = req.query.token
    else if req.method == 'GET' && req.cookies?.token
      token = req.cookies.token
    else if req.body?.token
      token = req.body.token
    else
      throw Error('Could not find token')

    [ idUser, token ] = token.split('/')

    return { idUser, token }

  cleanUser: (user) ->
    _.omit(user, 'credentials', 'hash', 'salt', 'sessions')

module.exports = Util
