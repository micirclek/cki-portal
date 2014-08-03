Schema = require('./')

QuestionSchema = new Schema 'Question',
  name: { type: String, required: true }
  type: { type: String, required: true, enum: Util.questionTypes }
  prompt: { type: String }
  section: { type: String, required: true }
  properties: { type: Object }

SectionSchema = new Schema 'Section',
  name: { type: String, required: true }
  title: { type: String }
  subtitle: { type: String }

FormSchema = new Schema 'Form',
  # for a club: { 'Club', idDistrict }
  # for all districts: { 'District', null }
  for: {
    modelType: { type: String, emun: ['Club', 'District'] }
    idDistrict: { type: Schema.ObjectId }
  }

  active: { type: Boolean, default: false }

  sections: [SectionSchema]

  questions: [QuestionSchema]

module.exports = FormSchema
