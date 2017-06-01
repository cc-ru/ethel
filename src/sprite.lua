local vector = require("vector")

local newSprite do
  local meta = {}

  function newSprite(w, h, texture)
    return function(x, y)
      local o = {
        x = x,
        y = y,
        w = w,
        h = h,
        texture = texture,
        velocity = vector(0, 0)
      }
      return setmetatable(o, meta)
    end
  end
end
