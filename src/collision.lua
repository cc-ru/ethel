local vector = require("vector")

local GRAVITY = vector(0, -0.1)
local MAXSPEED = 3

local function updateSprite(window, sprite)
  sprite.velocity[1] = math.min(sprite.velocity[1], MAXSPEED)
  sprite.velocity[1] = math.min(sprite.velocity[1], MAXSPEED)
  sprite.ownVelocity[2] = math.min(sprite.ownVelocity[2], MAXSPEED)
  sprite.ownVelocity[2] = math.min(sprite.ownVelocity[2], MAXSPEED)
  local v = sprite.velocity + sprite.ownVelocity
  sprite.x = sprite.x + v[1]
  sprite.y = sprite.y + v[2]
  local collide = false
  for x = math.floor(sprite.x), math.floor(sprite.x) + sprite.w - 1, 1 do
    for y = math.floor(sprite.y), math.floor(sprite.y) + sprite.h - 1, 1 do
      local tx, ty = window.tilemap:fromAbsCoords(x, y)
      local tile = window.tilemap:get(tx, ty)
      if tile then
        -- Collision!
        sprite.x = sprite.x - v[1]
        sprite.y = sprite.y - v[2]
        collide = true
        break
      end
    end
    if collide then
      break
    end
  end
  if collide then
    sprite.velocity = vector(0, 0)
    sprite.ownVelocity = vector(0, 0)
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
  else
    sprite.velocity = vector(0, 0)
  end
end

local function progress(window, t)
  for i = 1, t, 1 do
    for _, sprite in pairs(window.sprites) do
      updateSprite(window, sprite)
    end
    updateSprite(window, window.player)
  end
end

return {
  progress = progress
}
