nodemailer = require('nodemailer')

Handlebars = require('handlebars')

class Emailer
  @initialize: ->
    @transport = nodemailer.createTransport "SMTP",
      host: Settings.get('email.host')
      secureConnection: Settings.get('email.secure')
      port: Settings.get('email.port')
      auth:
        user: Settings.get('email.user')
        pass: Settings.get('email.password')

    return @

  @_template: (name, data = {}, html) ->
    template = Handlebars.templates['emails/' + name]
    if !template
      throw Error('Template not found')

    template _.extend({ html }, data),
      partials:
        header: Handlebars.templates['emails/header'] ? ''
        footer: Handlebars.templates['emails/footer'] ? ''


  # options should at a minimum contain subject, to, template, data
  @send: (options) ->
    if !Settings.get('email.enable')
      return Promise.resolve()

    options.subject = '[CK] ' + options.subject
    options = _.defaults options,
      from: Settings.get('email.from')
      text: @_template(options.template, options.data, false)
      html: @_template(options.template, options.data, true)

    Promise.ninvoke(@transport, 'sendMail', options)

module.exports = Emailer
