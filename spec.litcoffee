# Specification

----------

[TOC]

----------

## Usage

Install *need* with `npm`:

```
npm install need
```

Use it easily in your code:
```
need = require('need');
modules = need('./modules/*')
```

## Methods

### need( patterns [, options] [, onFulfilled] )

Load modules synchronously or asynchronously.

**Parameters**

- `patterns`
  - `(String)` - [Minimatch][1] wildcard pattern
  - `(Array)` - An Array contains String patterns
  - `(Object)` - Nested value contains above types
  - `(Promise)` - A "thenable" [promise][2] which when finished, return a value above
  - `(String | Array | Object | Promise) Function()` - A function returns any of the the above values
- `[options]`
  - `(Object)` - If specified, would overwrite the default options of the current *need* instance. Details in [options](#options) section.
- `[onFulfilled]`
  - `Function()` - When specified, it is binded to the result handler after loading, and `options.async` is overwriten to `true`.
  - `true` - Overwrite `options.async` to `true`, the return value would be a thenable promise.

**Return**

- `(Array)` - when `options.object` is `false`.
- `(Object)` - when `options.object` is `true`.
- `(Promise)` - when `options.async` is `true`.

### need.async( patterns [, options] [, onFulfilled] )

Overwrite `options.async` to `true` then run `need(patterns, options, onFulfilled)`.

**Return:** same as [`need()`](#need-patterns-options-onFulfilled)

### need.async()

Overwrite default `options.async` to `true`.

**Return:** new `need` instance

### need.config( options )

Overwrite default `options`.

**Alias:** `need.default`

**Parameters**

- `options`
  - `(Object)` - The configurations to be modified.
  - `(undefined)` - Restore to the original default settings.

**Return:** new `need` instance

### need.set( name, map )

Define path mapping.

**Alias:** `need.define`, `need.def`

**Parameters**

- `name`
  - `(String)` - An alias for the mapping path
- `map`
  - `(String)` - A path to replace the alias in processing pattern

**Return:** new `need` instance

### need.set( mapping )

Define path mappings.

**Alias:** `need.define`, `need.def`

**Parameters**

- `mapping`
  - `Array([name, map]...)`
  - `(Object{name: map...})`
  - `(String) Function( pattern )` - A mapping function given the current processing pattern and return the mapped value.

**Return:** new `need` instance

### need.unset( name )

Remove path mappings.

**Alias:** `need.remove`, `need.rm`

**Parameters**

- `name`
  - `(String)` - The mapping alias to be removed
  - `(Array)` - A list of aliases to be removed

**Return:** new `need` instance

### need.register( extension, handler [, index] )

Add an extension handler, same as changing the default `options.extensions` values.

**Alias:** `need.reg`

**Parameters**

- `extension`
  - `(String)` - The extension to be handled like `'.js'`.
- `handler`
  - `Function( module, filename )` - The actual loading handler, see more [here][3].
- `index`
  - `(Number)` - The index of where the handler is added to the list. If `index < 0 || index > options.extensions.length` an error would be raised.

### need.unregister( extension )

Remove an extension handler, same as deleting an item from the default `options.extensions`.

**Alias:** `need.unreg`

**Parameters**

- `extension`
  - `(String)` - The extension to be removed.
  - `(Number)` - The index of the item to be removed.

**Return:** new `need` instance

## Options

Current settings saved in `need.options`. Please **DO NOT** change it directly, instead try to use `need.config()` and other alias methods to create new *need* instances with modified default options. Otherwise it's dangerous to pollute the original instance for other modules. You can get a clean *need* instance (original default options) by `need.config()` with no arguments.

### async

**Type:** `(Boolean)`

**Default:** `false`

Stay `false` to directly return the loaded modules. If `true` load files asynchronously, and return a thenable object.

### alias

**Alias:** map

**Type:** `Array([name, map]|[(String) Function( pattern )])`

**Default:** `[]`

A table of path alias mappings.

### base

**Type:** `false` | `(String)` | `(String) Function()`

**Default:** `false`

If specified, related paths and node_modules paths would be resolved based on this path.

### log

**Type:** `(Boolean)`

**Default:** `false`

If `true`, log the loading status on console.

**Type:** `Function( Module )`

Specify a custom logger.

### object

**Alias:** obj

**Type:** `(Boolean)`

**Default:** `false`

Return an object instead of an array. The keys would be the module names if provided in the patterns or the module name provided by the module itself if options.name is true, otherwise it's set to the file path. Values of each item is wrapped into a Module instance. Items with same key will merge into one by Module class.

### names

**Alias:** name

**Type:** `(Boolean)`

**Default:** `false`

When set to true, loader will retrieve module names by module.name (Type: String or (String) Function()

**Type:** `(String | Promise) Function( module, path, pattern )`

Set the module name by a function returns a `(String)` or `(Promise)`

- `module` - The loaded module
- `path` - The module's resolved file path
- `pattern` - The pattern matched the path

### extensions

**Alias:** exts

**Type:** `(Array)`

**Default:** flatten `require.extensions` into `Array([key, value])`

Extension handlers for *need*. When *need* is first loaded, it will copy `require.extensions` to this option in the form of `Array([key, value])`. For instance `[ [ '.js', [Function] ], [ '.json', [Function] ] ]`. We use an array because it's easier to control the order of file matching. For more information about extension handler, please read [this][3].

## Classes

### Module

```
class Module
  constructor: ({@pattern, @name, @path, @module}) ->
```

- `pattern`
  - `(String)` - The original pattern used to match the module path
- `name`
  - `(String)` - The module name if defined, otherwise it's same with `path`
- `path`
  - `(String)` - The resolved module file path
- `module`
  - `(Any)` - The loaded module

### NeedError

```
class NeedError
  constructor: ({@path, @caller, @error}) ->
```

- `path`
  - `(String)` - The error module file path
- `caller`
  - `(String)` - The path of the caller of the *need* function
- `error`
  - `(String)` - The error message

## Async Callbacks

Passed in `need()` method or linked by `then()` method in returned promise.

### onFulfilled

`Function( { modules, needed, send, each } )`

- `modules`
  - `(Array|Object|Promise)` - Loaded modules which type depends on the options.
- `needed`
  - `Array(Modules...)` - A list of the loaded modules in Module class form.
- `send`
  - `(Promise) Function( arguments... )` - Evaluate the exports from each required module with given `arguments`.
- `each`
  - `(Promise) Function( iterator( Module ) )` - Iterate through `needed` list.

### onRejected

`Function( NeedError )`

## Primitives

### Load Modules

When *need* a module, firstly look up the `node_modules` folder

```
# nodeModulesPath
find /current/path/node_modules
  if exists
    find module in nodeModulesPath
      if found return
else /current/node_modules
  if exists
    find module in nodeModulesPath
      if found return
else /node_modules
  if exists
    find module in nodeModulesPath
      if found return
else Not found
```

## Test

    need = require './lib/need'
    need './test/*', ({send}) ->
      send need

  [1]: https://github.com/isaacs/minimatch
  [2]: http://promises-aplus.github.io/promises-spec/
  [3]: http://github.com/joyent/node/blob/master/lib/module.js#L465