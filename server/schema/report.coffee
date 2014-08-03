Schema = require('./')

AnswerSchema = new Schema 'Answer',
  question: { type: String, required: true }
  value: Schema.Types.Mixed # this will vary depending on the qustion type

ReportSchema = new Schema 'Report',
  idForm: Schema.ObjectId

  for: {
    idModel: { type: Schema.ObjectId, required: true }
    modelType: { type: String, enum: ['Club', 'District'], required: true }
  }

  submitted: { type: Boolean, default: false }
  dateSubmitted: { type: Date, default: null }

  dateFor: { type: Date, required: true }

  # these are stored at the top level for convenience, however, districts
  # should always leave these as null (auto-calculated)
  serviceHours: { type: Number }
  interclubs: { type: Number }
  kfamEvents: { type: Number }

  answers: [AnswerSchema]

ReportSchema.methods.setAnswer = (answer) ->
  a = _.findWhere(@answers, { question: answer.question })
  if a?
    a.value = answer.value
    a.markModified('value')
  else
    @answers.push answer

module.exports = ReportSchema
