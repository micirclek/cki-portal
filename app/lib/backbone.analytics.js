/* from https://github.com/kendagriff/backbone.analytics */
(function(factory) {
  'use strict';
  factory(window.Backbone);
})(function(Backbone) {

  'use strict';

  var loadUrl = Backbone.History.prototype.loadUrl;

  Backbone.History.prototype.loadUrl = function(fragmentOverride) {
    var matched = loadUrl.apply(this, arguments),
        gaFragment = this.fragment;

    if (!/^\//.test(gaFragment)) {
      gaFragment = '/' + gaFragment;
    }

    // legacy version
    if (typeof window._gaq !== "undefined") {
      window._gaq.push(['_trackPageview', gaFragment]);
    }

    // Analytics.js
    var ga;
    if (window.GoogleAnalyticsObject && window.GoogleAnalyticsObject !== 'ga') {
      ga = window.GoogleAnalyticsObject;
    } else {
      ga = window.ga;
    }

    if (typeof ga !== 'undefined') {
      ga('send', 'pageview', gaFragment);
    }
    return matched;
  };

});
