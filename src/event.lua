local engine = require("aevent")()

engine:stdEvent("key_down", engine:event("key-down"))
engine:stdEvent("key_up", engine:event("key-up"))

return {
  engine = engine
}
