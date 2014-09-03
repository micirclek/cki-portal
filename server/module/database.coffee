mongoose = require('mongoose')

module.exports = class Db
  @initialize: ({ uri }) ->
    for schema in require(App.path('server/schema')).schemas
      @[schema.typeName] = mongoose.model(schema.typeName, schema)

    @mongoose = mongoose.connect uri,
      server:
        auto_reconnect: true

    return @
