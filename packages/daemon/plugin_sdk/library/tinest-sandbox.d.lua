---@meta tinest.sandbox

---The Lua standard-library globals available to every Tinest plugin VM.
---Unsafe basic functions are intentionally absent from this definition.
---@class (exact) tinest.SandboxLibraries
---@field math mathlib
---@field string stringlib
---@field table tablelib
---@field utf8 utf8lib

---@generic T
---@param value? T
---@param message? any
---@param ... any
---@return T
---@return any ...
function assert(value, message, ...) end

---@param message any
---@param level? integer
function error(message, level) end

---@generic T: table, V
---@param value T
---@return fun(table: V[], index?: integer): integer, V
---@return T
---@return integer index
function ipairs(value) end

---@generic K, V
---@param value table<K, V>
---@param index? K
---@return K?
---@return V?
function next(value, index) end

---@generic T: table, K, V
---@param value T
---@return fun(table: table<K, V>, index?: K): K, V
---@return T
function pairs(value) end

---@param callback async fun(...): ...
---@param argument? any
---@param ... any
---@return boolean success
---@return any result
---@return any ...
function pcall(callback, argument, ...) end

---@param index integer|'#'
---@param ... any
---@return any ...
function select(index, ...) end

---@overload fun(value: string, base: integer): integer
---@param value any
---@return number?
function tonumber(value) end

---@param value any
---@return string
function tostring(value) end

---@alias tinest.LuaTypeName
---| 'nil'
---| 'number'
---| 'string'
---| 'boolean'
---| 'table'
---| 'function'
---| 'thread'
---| 'userdata'

---@param value any
---@return tinest.LuaTypeName
function type(value) end

---@param callback async fun(...): ...
---@param message_handler fun(error: any): any
---@param argument? any
---@param ... any
---@return boolean success
---@return any result
---@return any ...
function xpcall(callback, message_handler, argument, ...) end

---@param module_name string
---@return unknown module
---@return unknown loader_data
function require(module_name) end
