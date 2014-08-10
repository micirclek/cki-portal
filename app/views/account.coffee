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
      @parent.closeSetPassword()
    .catch =>
      return
    .done()

    return false

  anyClick: (e) ->
    if !$(e.target).closest('.popover').length
      @parent.closeSetPassword()

class EditProfileView extends AppView
  events:
    'submit form': 'submit'

  initialize: ({ @parent }) ->
    super

  delegateEvents: ->
    super
    $(window).bind('click.change-password', (e) => @anyClick(e))

  undelegateEvents: ->
    super
    $(window).unbind('click.change-password')

  render: ->
    @$el.html(@template('edit_profile', @model.toJSON()))
    return @

  submit: ->
    name = @$('#name').val() ? ''
    @model.save({ name })
    .then =>
      @parent.closeEditProfile()
    .catch =>
      return
    .done()

    return false

  anyClick: (e) ->
    if !$(e.target).closest('.popover').length
      @parent.closeEditProfile()

class AccountView extends AppView
  events:
    'click .js-set-password': 'openSetPassword'
    'click .js-edit-profile': 'openEditProfile'

  initialize: ->
    @changePassword = new ChangePasswordView({ @model, parent: @ })
    @editProfile = new EditProfileView({ @model, parent: @ })

    @listenTo @model,
      'change:loginTypes change:name': @render

    super

  render: ->
    data = _.extend @model.toJSON(),
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

    @$('.js-edit-profile').popover
      html: true
      title: title
      content: @editProfile.render().el
      trigger: 'manual'
    .popover('hide')

    return @

  openSetPassword: ->
    if !@changePassword.visible
      @changePassword.render()
      @$('.js-set-password').popover('show')
      @changePassword.delegateEvents()
      @changePassword.visible = true
    return false

  closeSetPassword: ->
    @changePassword.visible = false
    @changePassword.undelegateEvents()
    @$('.js-set-password').popover('hide')

  openEditProfile: ->
    if !@editProfile.visible
      @editProfile.render()
      @$('.js-edit-profile').popover('show')
      @editProfile.delegateEvents()
      @editProfile.visible = true
    return false

  closeEditProfile: ->
    @editProfile.visible = false
    @editProfile.undelegateEvents()
    @$('.js-edit-profile').popover('hide')

module.exports = AccountView
