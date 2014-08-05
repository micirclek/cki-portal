AppView = require('views/appview')

class ChangePasswordView extends AppView
  events:
    'click .js-submit': 'submit'

  initialize: ({ @parent }) ->
    super

  delegateEvents: ->
    super
    $(window).bind('click.change-password', (e) => @anyClick(e))

  undelegateEvents: ->
    super
    $(window).unbind('click.change-password')

  render: ->
    data =
      password: 'password' in @model.get('loginTypes')

    @$el.html(@template('change_password', data))
    return @

  submit: ->
    oldPass = @$('#old-password')?.val?() ? ''
    newPass = @$('#new-password').val()
    newPass2 = @$('#new-password-again').val()
    if newPass != newPass2
      Util.showAlert('Passwords do not match')
      return false

    @model.setPassword(oldPass, newPass)
    .then =>
      Util.showAlert('Password changed', 'alert-success')
      @parent.closePopover()
    .catch =>
      return
    .done()

    return false

  anyClick: (e) ->
    if !$(e.target).closest('.popover').length
      @parent.closePopover()

class AccountView extends AppView
  events:
    'click .js-set-password': 'openSetPassword'

  initialize: ->
    @visible = false
    @changePassword = new ChangePasswordView({ @model, parent: @ })

    @listenTo @model, 'change:loginTypes', @render

    super

  render: ->
    data =
      password: 'password' in @model.get('loginTypes')

    @$el.html(@template('account', data))

    title = if data.password
      'Change Password'
    else
      'Set Password'

    @$('.js-set-password').popover
      html: true
      title: title
      content: @changePassword.render().el
      trigger: 'manual'
    .popover('hide')

    return @

  openSetPassword: ->
    if !@visible
      @changePassword.render()
      @$('.js-set-password').popover('show')
      @changePassword.delegateEvents()
      @visible = true
    return false

  closePopover: ->
    @visible = false
    @changePassword.undelegateEvents()
    @$('.js-set-password').popover('hide')

module.exports = AccountView
