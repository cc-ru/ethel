local event = require("event")

local listeners = {}

local function unregister(name)
  if listeners[name] then
    event.ignore(listeners[name].e, listeners[name].handler)
  end
end

local function register(name, e, handler)
  unregister(name)
  event.listen(e, handler)
  listeners[name] = {
    e = e,
    handler = handler
  }
end

return {
  register = register,
  unregister = unregister
}
