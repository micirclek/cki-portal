exports.config =
  # See http://brunch.readthedocs.org/en/latest/config.html for documentation.
  files:
    javascripts:
      defaultExtension: 'coffee'
      joinTo:
        'js/app.js': /^app/
        'js/vendor.js': /^bower_components/
      order:
        before: []
        after: []
    stylesheets:
      joinTo:
        'css/app.css'
      order:
        before: []
        after: []
    templates:
      joinTo: 'js/app.js'
  overrides:
    production:
      sourceMaps: true
  onCompile: (files) ->
    # fix an issue with uglify writing the sourcemap twice
    exec = require('child_process').exec
    for file in files
      command = "sed -i '/^\\/\\/# sourceMappingURL=public\\/js\\//d' #{file.path}"
      exec(command)
