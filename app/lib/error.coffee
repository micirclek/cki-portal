class Error.AjaxError extends Error
  constructor: (ajaxErr) ->
    if !(@ instanceof Error.AjaxError)
      error = new Error.AjaxError(arguments...)
      if Error.captureStackTrace
        Error.captureStackTrace(error, arguments.callee)
      else if (stack = new Error().stack)
        error.stack = stack
      return error

    Error.call(@)
    if Error.captureStackTrace
      Error.captureStackTrace(@, arguments.callee)
    else if (stack = new Error().stack)
      @stack = stack

    @name = 'AjaxError'

    @response = ajaxErr.responseText
    @status = ajaxErr.status

    @message = @status + ': ' + @response

doCrash = ->
  Promise.delay(null, 500).then ->
    crash.crash()
  .done()

window.crashTest = -> setTimeout(doCrash, 1)
