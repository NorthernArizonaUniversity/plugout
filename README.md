Plugout
=======

Plugout is a general purpose plugin manager with no dependencies.

- Easily add plugins to your application with a consistent and flexible format
- Load, unload, reload plugins on-the-fly
- Plugins can:
 - Listen for events on the main application
 - Emit events on the main application
 - Provide an API that can be used by the main application or other plugins

Plugins
-------

### Format

Plugins are defined as node.js modules in a directory of your choosing. The module exports object should be the
plugin object and can have the following keys:

- **defaultOptions**: An object containing default options. These can be overwritten at load, and the final options object will be in plugins.options.
- **init**: a function that is called just after the plugin has been loaded. Most setup functionality should be done in this function.
- **listeners**: an object defining event names and listeners (see plugin.listen() below [preferred])
- **provides**: an object defining provided functions (see plugin.provide() below [preferred])

### API

The following objects/functions are available once the plugin has been loaded (ie, in the init function, but not in
the bare module).

- **plugin.context** / **plugin.getContext()**: A reference to the main application. Set in the constructor.
- **plugin.logger**: A shortcut to plugin.context.logger (if defined)
- **plugin.options**: Merged options object containing defaultOptions, overrides, and prefix (name of the plugin)
- **plugin.provide(name, fn)**: Defines a function to provide to the outside world.
- **plugin.invoke(name, args...)**: Calls another plugin's provided function.
- **plugin.emit(name, args...)**: Emits an event on the context object (main application).
- **plugin.listen(name, listener)**: Defines a listener for events on the context object (main application).

See samples directory


License
-------

Copyright 2013/2014 Northern Arizona University

This file is part of Plugout.

Plugout is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Plugout is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Plugout. If not, see <http://www.gnu.org/licenses/>.
