nodemailer = require('nodemailer')

Handlebars = require('handlebars')

class Emailer
  @initialize: ({ host, secure, port, user, pass, @from, @enable }) ->
    @transport = nodemailer.createTransport
      host: host
      secureConnection: secure
      port: port
      auth: { user, pass }

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
    if !@enable
      return Promise.resolve()

    options.subject = '[CK] ' + options.subject
    options = _.defaults options,
      from: @from
      text: @_template(options.template, options.data, false)
      html: @_template(options.template, options.data, true)

    Promise.ninvoke(@transport, 'sendMail', options)

module.exports = Emailer
