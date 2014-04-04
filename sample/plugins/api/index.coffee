async = require 'async'
util = require 'util'
plugin  =
  defaultOptions:
    path: '/' # By default, the API plugin mounts to root

module.exports = plugin


plugin.init = ->
  plugin.logger.info "[API] Initializing REST API"
  #plugin.getContext().app.get...
  #plugin.emit 'event'
