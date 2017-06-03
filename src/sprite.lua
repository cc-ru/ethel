local vector = require("vector")

local module = require("ethel.module")
local tile = module.load("tile")

local getResource = module.load("resource").getResource

local newSprite do
  local meta = {}

  function newSprite(w, h, isEnemy, render, update, properties)
    return function(x, y)
      local o = {
        x = x,
        y = y,
        w = w * 2,
        h = h,
        emeny = isEnemy,
        render = render,
        update = update,
        velocity = vector(0, 0),
        ownVelocity = vector(0, 0)
      }
      if properties then
        properties(o)
      end
      return setmetatable(o, meta)
    end
  end
end

local player = newSprite(2, 5, false,
                         tile.renderFromResource(getResource("sprite.player")),
                         function() end)

local chort = newSprite(
  3,
  3,
  true,
  tile.renderFromResource(getResource("sprite.chort")),
  function(self, window, tilemap)
    self.velocity = vector(0.05 * self.props.direction, 0)
  end,
  function(o)
    o.direction = 1
  end)

return {
  newSprite = newSprite,
  player = player
}
