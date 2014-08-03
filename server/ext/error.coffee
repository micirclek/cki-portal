class Error.ApiError extends Error
  constructor: (@message, @statusCode = 400, @data = {}) ->
    if !(@ instanceof Error.ApiError)
      error = new Error.ApiError(arguments...)
      Error.captureStackTrace(error, arguments.callee)
      return error

    Error.call(@)
    Error.captureStackTrace(@, arguments.callee)
    @name = 'ApiError'
