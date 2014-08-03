Promise = require('bluebird')

# ninvoke code adapted from https://github.com/jden/ninvoke

nfapply = (func, context, args...) ->
  return new Promise (resolve, reject) ->
    args.push (err, ret...) ->
      if err?
        return reject(err)

      if ret.length == 0
        resolve()
      else if ret.length == 1
        resolve(ret[0])
      else
        resolve(ret)

    func.apply(context, args)



Promise.ninvoke = (object, methodName, args...) ->
  return nfapply(object[methodName], object, args...)

Promise.nfcall = (func, args...) ->
  return nfapply(func, @, args...)
