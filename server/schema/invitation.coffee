Schema = require('./')

Db = App.module('database')

#TODO key, so that you can join with another email
InvitationSchema = new Schema 'Invitation',
  name: String
  email: String

  idClub: { type: Schema.ObjectId }
  idDistrict: { type: Schema.ObjectId }
  modelType: { type: String, enum: ['Club', 'District'] }

  start: { type: Date }
  end: { type: Date }

InvitationSchema.index('email': 1)
InvitationSchema.index(idDistrict: 1, modelType: 1)
InvitationSchema.index({ idClub: 1 }, { sparse: true })

module.exports = InvitationSchema
