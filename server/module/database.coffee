mongoose = require('mongoose')

module.exports = class Db
  @initialize: ({ host, name, port }) ->
    for schema in require(App.path('server/schema')).schemas
      @[schema.typeName] = mongoose.model(schema.typeName, schema)

    @mongoose = mongoose.connect host, name, port,
      server:
        auto_reconnect: true

    return @
