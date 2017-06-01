local vector = require("vector")

local FRICTION = 0.9
local GRAVITY = vector(0, 1)
local MAXSPEED = 3

local function updateSprite(window, sprite)
  sprite.velocity[1] = sprite.velocity * FRICTION
  sprite.x = sprite.x + sprite.velocity[1]
  sprite.y = sprite.y + sprite.velocity[2]
  local collide = false
  for x = sprite.x, sprite.x + sprite.w - 1, 1 do
    for y = sprite.y, sprite.y + sprite.h - 1, 1 do
      local tx, ty = window.tilemap:fromAbsCoords(x, y)
      local tile = window.tilemap:get(tx, ty)
      if tile then
        -- Collision!
        sprite.x = sprite.x - sprite.velocity[1]
        sprite.y = sprite.y - sprite.velocity[2]
        collide = true
        break
      end
    end
    if collide then
      break
    end
  end
  if collide then
    sprite.velocity[1] = 0
    sprite.velocity[2] = 0
  end
  local inMidair = true
  for x = sprite.x, sprite.x + sprite.w - 1, 1 do
    local tx, ty = window.tilemap:fromAbsCoords(x, sprite.y - 1)
    local tile = window.tilemap:get(tx, ty)
    if tile then
      inMidair = false
      break
    end
  end
  if inMidair then
    sprite.velocity = sprite.velocity + GRAVITY
  end
  sprite.velocity[1] = math.min(sprite.velocity[1], MAXSPEED)
  sprite.velocity[2] = math.min(sprite.velocity[2], MAXSPEED)
end

local function progress(window, t)
  for i = 1, t, 1 do
    for _, sprite in pairs(window.sprites) do
      updateSprite(window, sprite)
    end
  end
end

return {
  progress = progress
}
