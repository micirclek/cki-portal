Schema = require('./')

QuestionSchema = new Schema 'Question',
  name: { type: String, required: true }
  type: { type: String, required: true, enum: Util.questionTypes }
  prompt: { type: String }
  section: { type: String, required: true }
  properties:
    required: { type: Boolean, default: false }
    fields: [
      type: { type: String, enum: Util.questionTypes }
      prompt: { type: String }
      name: { type: String }
    ]
    options: [String]

SectionSchema = new Schema 'Section',
  name: { type: String, required: true }
  title: { type: String }
  subtitle: { type: String }

FormSchema = new Schema 'Form',
  name: { type: String, default: 'Report' }
  properties:
    autoStats: { type: Boolean, default: false }
    table: String
    serviceField: String
    kfamField: String
    interclubField: String

  # for clubs in a district: { 'Club', idDistrict }
  # for all clubs: { 'Club', idDistrict }
  # for all districts: { 'District', null }
  for: {
    modelType: { type: String, emun: ['Club', 'District'] }
    idDistrict: { type: Schema.ObjectId }
  }

  # the lifespan of a form (descriptions are { published, active }):
  # { false, true }: the form was just created.  You can edit it however you
  #                  want and no one can fill it out
  # { true, true }:  you are done creating the form, it can now be filled out
  #                  by whoever it is intended for.  Updates at this point are
  #                  restricted to copy changes
  # { *, false }:    the form has reached the end of its life.  It can no
  #                  longer be edited at all and no new reports may be started
  #                  based off of this form
  published: { type: Boolean, default: false }
  active: { type: Boolean, default: true }

  sections: [SectionSchema]

  questions: [QuestionSchema]

FormSchema.index('for.modelType': 1, 'for.idDistrict': 1, published: 1, active: 1)

module.exports = FormSchema
