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
    'for.idDistrict': @_id
  .select('dateFor submitted')
  .sort(dateFor: 1)

  Promise.resolve(query.exec())

DistrictSchema.methods.loadForms = ->
  query = Db.Form.find()
  .where
    'for.modelType': 'District'
    published: true
    active: true
  .select('name')

  Promise.resolve(query.exec())

DistrictSchema.methods.loadChildReports = ->
  query = Db.Report.find()
  .where
    'for.modelType': 'Club'
    'for.idDistrict': @_id
  .select('dateFor submitted for')
  .sort('for.idClub': 1, 'dateFor': 1)

  Promise.resolve(query.exec())

DistrictSchema.methods.loadChildForms = ->
  query = Db.Form.find()
  .where
    'for.modelType': 'Club'
    'for.idDistrict': @_id
    active: true
  .select('name published active')

  Promise.resolve(query.exec())

module.exports = DistrictSchema
