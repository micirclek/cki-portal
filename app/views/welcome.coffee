AppView = require('views/appview')

class EntityView extends AppView
  render: ->
    return @

class WelcomeView extends AppView
  render: ->
    currentPositions = Session.me.positions.getCurrent().map (position) =>
      link = switch position.get('level')
        when 'club'
          '#club/' + position.get('idClub') + '/home'
        when 'district'
          '#district/' + position.get('idDistrict') + '/home'

      name: position.get('entityName') + ' ' + Util.ucFirst(position.get('level'))
      link: link

    data =
      positions: currentPositions

    @$el.html(@template('welcome', data))

    currentPositions.forEach (position) =>


    return @

module.exports = WelcomeView
