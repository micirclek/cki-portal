Db = App.module('database')

module.exports = {
  reportsByMonth: (dateStart, dateEnd, idClubs) ->
    match = { $match: {} }
    if dateStart || dateEnd
      match.$match.dateFor = {}
      if dateStart
        match.$match.dateFor.$gte = dateStart
      if dateEnd
        match.$match.dateFor.$lt = dateEnd

    if idClubs
      match.$match['for.idModel'] = { $in: idClubs }

    reports = Db.Report.aggregate [
      match,
      {
        $group: {
          _id: {
            month: {
              $month: '$dateFor'
            }
            year: {
              $year: '$dateFor'
            }
          }
          serviceHours: { $sum: "$serviceHours" }
          interclubs: { $sum: "$interclubs" }
          kfamEvents: { $sum: "$kfamEvents" }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1 }
      }
    ]
    Promise.resolve(reports.exec())
    .map (stat) =>
      _.extend(stat, stat._id)
      delete stat._id
      stat
}
