Schema = require('./')

Db = App.module('database')

DistrictSchema = new Schema 'District',
  kiwanisId: String
  name: String

DistrictSchema.methods.loadClubs = ->
  query = Db.Club.find()
  .where
    idDistrict: @_id
  .select('name')

  Promise.resolve(query.exec())

DistrictSchema.methods.loadReports = ->
  query = Db.Report.find()
  .where
    'for.modelType': 'District'
    'for.idModel': @_id
  .select('dateFor submitted')
  .sort(dateFor: 1)

  Promise.resolve(query.exec())

DistrictSchema.methods.loadForms = ->
  query = Db.Form.find()
  .where
    'for.modelType': 'District'
    active: true
  .select('')

  Promise.resolve(query.exec())

module.exports = DistrictSchema
