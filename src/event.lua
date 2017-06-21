local engine = require("aevent")()

local module = require("ethel.module")
local log = module.load("util.logger")

engine:stdEvent("key_down", engine:event("key-down"))
engine:stdEvent("key_up", engine:event("key-up"))

local function wrap(cls, method)
  return function(...)
    log.logger:debug("running wrapped method")
    return method(cls, ...)
  end
end

return {
  engine = engine,
  wrap = wrap
}
