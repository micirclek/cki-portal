mongoose = require('mongoose')

module.exports = class Db
  @initialize: ->
    for schema in require(App.path('server/schema')).schemas
      @[schema.typeName] = mongoose.model(schema.typeName, schema)

    @mongoose = mongoose.connect Settings.get('db.host'), Settings.get('db.name'), Settings.get('db.port'),
      server:
        auto_reconnect: true

    return @
