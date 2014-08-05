Entity = require('models/entity')

class Club extends Entity
  typeName: 'Club'
  urlRoot: '/1/clubs'

class ClubCollection extends Entity.Collection
  model: Club

Club.Collection = ClubCollection

module.exports = Club
