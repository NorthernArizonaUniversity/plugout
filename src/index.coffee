###
Copyright 2013/2014 Northern Arizona University

This file is part of Plugout.

Plugout is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Plugout is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Plugout. If not, see <http://www.gnu.org/licenses/>.
###

merge = (obj, sources...) ->
  for source in sources
    for k, v of source
      obj[k] = v
  return obj


class Plugout

  constructor: (@context, @pluginPath, loadPlugins = {}) ->
    ### Creates a new plugin manager object ###
    throw new Exception 'Context object must exist and must emit events' unless @context and @context.emit
    throw new Exception 'Plugin path must be provided' unless @pluginPath

    @pluginPath = @pluginPath + '/' unless @pluginPath.match /\/$/

    @plugins = {}
    @listeners = {}
    @provides = {}
    @loadPlugins loadPlugins ? {}

    # @context.getPlugin ?= @getPlugin
    # @context.getPlugins ?= => @plugins
    # @context.invoke ?= @invoke


  addListeners: (plugin) ->
    ### Adds listeners to a plugin based on plugin options. ###
    for own event, listener of plugin.listeners
      key = plugin.options.prefix + event

      if typeof listener is 'function'
        @listeners[key] = listener
        @context.addListener event, listener
      else
        for sublistener in listener
          @listeners[key] = @listeners[key] ? []
          @listeners[key].push sublistener
          @context.addListener event, sublistener


  removeListeners: (plugin) ->
    ### removes all listeners from the given plugin ###
    for own event, listener of plugin.listeners
      key = plugin.options.prefix + event
      listener = @listeners[key]

      if typeof listener is 'function'
        @context.removeListener event, listener
      else
        for sublistener in listener
          @context.removeListener event, sublistener

      delete @listeners[key]


  getPlugin: (name) ->
    ### returns the plugin object by name ###
    cleanName = @pluginPath + name
    @plugins[cleanName]


  callPlugin: (plugin, args...) ->
    ### Calls a function provided by a plugin. The function should be defined in module.exports.provides ###
    @getPlugin(plugin)?.call.apply @, args


  loadPlugin: (name, options) ->
    ### Loads (or reloads) a plugin by name with the given options, attaches listeners and utility references. ###
    cleanName = @pluginPath + name
    full = require.resolve cleanName
    pl = require.cache[full]

    if pl?
      if pl.exports.reload?
        for module in pl.exports.reload
          delete require.cache[module]
      delete require.cache[full]

    @unloadPlugin(name) if @plugins[cleanName]

    @context.emit 'plugin-pre-load', name

    pl = require full
    @plugins[cleanName] = pl
    @initPlugin pl, name, options
    @addListeners pl
    @context.emit 'plugin-pre-init', name, pl

    pl.listeners.load?()
    pl.init?()
    @context.emit 'plugin-load', name, pl


  initPlugin: (pl, name, options) ->
    # References
    pl.context = @context
    pl.logger = @context.logger ? null
    pl.listeners ?= {}
    pl.provides ?= {}

    # Options
    defaultOptions = @plugins?[name] ? {}
    options = merge defaultOptions, options ? {}

    pl.options = merge (pl.defaultOptions ? { path: "/#{name}" }), options
    pl.options.prefix = name

    # Functions
    pl.getContext = => @context
    pl.invoke = @invoke
    pl.provide = @provide
    pl.emit = @context.emit
    pl.listen = @context.addListener


  unloadPlugin: (name, options) ->
    ### Unloads the given plugin. ###
    cleanName = @pluginPath + name
    pl = @plugins[cleanName]

    throw new Error("Plugin not found: #{name}") unless pl?

    @context.emit 'plugin-pre-unload', name, pl

    pl.options = options ? {}
    pl.options.prefix = name

    @removeListeners pl
    delete @plugins[cleanName]

    pl.listeners.unload?()
    @context.emit 'plugin-unload', name, pl


  loadPlugins: (plugins) ->
    ###
    Loads multiple plugins. Plugin list should be an object
    with the plugin names as keys and plugin option objects as values.
    ###
    for own name, options of plugins
      @loadPlugin name, options


  # Plugin Provides

  parseProvideName: (name) ->
    matches = name.match /^(([^.]+)\.)?(.*)/
    pl = @getPlugin matches[2]
    pl.provides ?= {} if pl
    [ pl, matches[3] ]


  provide: (name, fn) =>
    [pl, subname] = @parseProvideName name
    if pl?
      pl.provides[subname] = fn
    else
      @provides[name] = fn


  invoke: (fn, args...) =>
    # The fn is defined by name
    if @provides[fn]?
      return @provides[fn].apply @, args
    # Otherwise, parse it
    [pl, name] = @parseProvideName fn
    return pl?.provides?[name]?.apply pl, args


module.exports.Plugout = Plugout
