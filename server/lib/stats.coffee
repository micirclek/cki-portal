Db = App.module('database')

module.exports = {
  reportsByMonth: (dateStart, dateEnd, idDistrict, idClub) ->
    # district reports should not have stats, but let's be careful
    match = { $match: { 'for.modelType': 'Club' } }
    if dateStart || dateEnd
      match.$match.dateFor = {}
      if dateStart
        match.$match.dateFor.$gte = dateStart
      if dateEnd
        match.$match.dateFor.$lt = dateEnd

    if idDistrict?
      match.$match['for.idDistrict'] = idDistrict
    if idClub?
      match.$match['for.idClub'] = idClub

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
