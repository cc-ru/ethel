local engine = require("aevent")()

engine:stdEvent("key_down", engine:event("key-down"))
engine:stdEvent("key_up", engine:event("key-up"))

local function wrap(cls, method)
  return function(...)
    return method(cls, ...)
  end
end

return {
  engine = engine,
  wrap = wrap
}
