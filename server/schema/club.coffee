Schema = require('./')

Db = App.module('database')

ClubSchema = new Schema 'Club',
  kiwanisId: String
  idDistrict: Schema.ObjectId

  name: String

ClubSchema.index(idDistrict: 1)

# returns the id, month, and submission status of all reports for this club
ClubSchema.methods.loadReports = ->
  query = Db.Report.find()
  .where
    'for.modelType': 'Club'
    'for.idClub': @_id
  .select('dateFor submitted')
  .sort(dateFor: 1)

  Promise.resolve(query.exec())
  .map (report) =>
    return _.pick(report, '_id', 'dateFor', 'submitted')

# returns the ids of all the active forms this club can fill out
ClubSchema.methods.loadForms = ->
  query = Db.Form.find()
  .where
    'for.modelType': 'Club'
    '$or': [
      { 'for.idDistrict': @idDistrict }
      { 'for.idDistrict': null }
    ]
    published: true
    active: true
  .select('name')

  Promise.resolve(query.exec())

module.exports = ClubSchema
