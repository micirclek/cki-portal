module.exports =
  server:
    port: 5080
    host: 'localhost'
    fullDomain: 'http://localhost:5080'
  db:
    uri: 'mongodb://localhost/portal'
  auth:
    googleClientId: ''
    googleClientSecret: ''
  email:
    enable: false

    host: ''
    port: 0
    secure: false
    user: ''
    password: ''

    from: ''
  logging:
    consoleLevel: 'silent'

    logglyLevel: 'silent'
    logglySubdomain: ''
    logglyToken: ''

    ravenLevel: 'silent'
    sentryDSN: ''
  paths:
    staticPath: 'public'

  secret: ''
