local vector = require("vector")

local GRAVITY = vector(0, -0.1)
local MAXSPEED = 3

local function isSpriteInMidair(window, sprite)
  for x = sprite.x, sprite.x + sprite.w - 1, 1 do
    local tx, ty = window.tilemap:fromAbsCoords(x, sprite.y - 1)
    local tile = window.tilemap:get(tx, ty)
    if tile then
      return false
    end
  end
  return true
end

local function signum(v)
  if v > 0 then
    return 1
  elseif v < 0 then
    return -1
  else
    return 0
  end
end

local function capSpeed(v, max)
  v[1] = signum(v[1]) * math.min(math.abs(v[1]), max)
  v[2] = signum(v[2]) * math.min(math.abs(v[2]), max)
end

local function updateSprite(window, sprite)
  local v = sprite.velocity + sprite.ownVelocity
  capSpeed(v, MAXSPEED)
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
  if isSpriteInMidair(window, sprite) then
    sprite.velocity = sprite.velocity + GRAVITY
  else
    sprite.velocity[2] = 0
    sprite.y = math.floor(sprite.y)
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
  isSpriteInMidair = isSpriteInMidair,
  progress = progress
}
