StringStore
===

Lua interface for preserving types in data structures that are out of control for the current environment.

StringStore was made for Noita (specifically, the Globals API), but it is written in such a way that it should only take a couple of minutes to get it working for any other program or environment.

Usage
===

In one LuaState:

```lua
dofile("mods/my_mod/files/stringstore/stringstore.lua")
dofile("mods/my_mod/files/stringstore/noitaglobalstore.lua")

local MY_EXTERN_GLOBAL = stringstore.open_store(stringstore.noita.global("MY_EXTERN_GLOBAL"))

MY_EXTERN_GLOBAL.some_numeric_field = 123
MY_EXTERN_GLOBAL.subtable = {}
MY_EXTERN_GLOBAL.subtable.x = 123
MY_EXTERN_GLOBAL.subtable.y = "a"
MY_EXTERN_GLOBAL.subtable.z = true
```

In another LuaState:

```lua
dofile("mods/my_mod/files/stringstore/stringstore.lua")
dofile("mods/my_mod/files/stringstore/noitaglobalstore.lua")

local MY_EXTERN_GLOBAL = stringstore.open_store(stringstore.noita.global("MY_EXTERN_GLOBAL"))

print(type(MY_EXTERN_GLOBAL.subtable.x)) --> "number"
print(MY_EXTERN_GLOBAL.subtable.x) --> 123
```

Support
===

Currently, StringStore supports writing and reading based on the StoreInfo. Iteration (`pairs`/`ipairs`) and length (`#` operator) are not yet supported.

StoreInfo Interface
===

To create a store, you must pass a table to `stringstore.create_store` that specifies functions implementing the interface. Note that all of the arguments to these functions are passed as strings (so there is no need to call `tostring` on them). Here are the functions that must be implemented:

* `set_type(key, type_str)` - Should register the type of the object at `key`
* `set(key, val)` - Should set the value of the object at `key` (**not called for tables**)
* `get_type(key)` - Should return the type of the object at `key`
* `get(key)` - Should return the value of the object at `key` (**not called for tables**)
* `get_sub_prefix(key)` - Should return a prefix to use for `set_type`, `set`, `get_type` and `get` functions for subtables (table keys will then be passed to the appropriate functions with this prefix prepended to the key)
* `get_typed_key(key, type)` - Should return the actual key to be passed to `set_type`, `set` `get_type` and `get` functions, based on the accessed key - this is used to preserve types of table keys (e.g. `1` vs `"1"`)
* `restrict(key)` - Should error if the key contains any characters that are invalid (i.e. characters that'd break the internal format)

Included Interfaces
===

StringStore comes with two implementations:

* `noitaglobalstore.lua` - `stringstore.noita.global(global_var_name)` - uses the `Globals` API in Noita to store the table
* `noitavariablestore.lua` - `stringstore.noita.variable_storage_components(entity_id)` - uses `VariableStorageComponent`s on a particular Entity in Noita to store the table
