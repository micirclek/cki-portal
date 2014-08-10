class Error.AjaxError extends Error
  constructor: (ajaxErr) ->
    if !(@ instanceof Error.AjaxError)
      error = new Error.AjaxError(arguments...)
      Error.captureStackTrace(error, arguments.callee)
      return error

    Error.call(@)
    Error.captureStackTrace(@, arguments.callee)
    @name = 'AjaxError'

    @response = ajaxErr.responseText
    @status = ajaxErr.status

    @message = @status + ': ' + @response
