mongoose = require('mongoose')
Schema = mongoose.Schema
requireDir = require('require-dir')

class AppSchema extends Schema
  constructor: (typeName, schema) ->
    super(schema)

    @typeName = typeName
    @virtual('typeName').get -> typeName

module.exports = AppSchema

module.exports.schemas = []
for file, schema of requireDir()
  module.exports.schemas.push(schema)
