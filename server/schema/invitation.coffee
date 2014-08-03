Schema = require('./')

Db = App.module('database')

#TODO key, so that you can join with another email
InvitationSchema = new Schema 'Invitation',
  email: String

  idClub: { type: Schema.ObjectId }
  idDistrict: { type: Schema.ObjectId }
  modelType: { type: String, enum: ['Club', 'District'] }

  start: { type: Date }
  end: { type: Date }

module.exports = InvitationSchema
