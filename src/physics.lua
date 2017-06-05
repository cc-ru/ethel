local vector = require("vector")

local GRAVITY = vector(0, -0.1)
local MAXSPEED = 3

local function isSpriteInMidair(window, sprite)
  for x = sprite.x, sprite.x + sprite.w - 1, 1 do
    local tx, ty = window.tilemap:fromAbsCoords(x, sprite.y - 1)
    if not window.tilemap:inBounds(tx, ty) then
      return false
    end
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

local function checkCollision(window, sprite)
  for x = math.floor(sprite.x), math.floor(sprite.x) + sprite.w - 1, 1 do
    for y = math.floor(sprite.y), math.floor(sprite.y) + sprite.h - 1, 1 do
      local tx, ty = window.tilemap:fromAbsCoords(x, y)
      local tile = window.tilemap:get(tx, ty)
      if tile or not window.tilemap:inBounds(tx, ty) then
        return true
      end
    end
  end
  return false
end

local function resolveNearTileCollision(window, sprite, v)
  local collision = {false, false}
  if v[1] ~= 0 then
    local i = sprite.x - 1
    if v[1] > 0 then
      i = sprite.x + sprite.w
    end
    for j = sprite.y, sprite.y + sprite.h - 1, 1 do
      local tx, ty = window.tilemap:fromAbsCoords(i, j)
      if window.tilemap:get(tx, ty) or
          not window.tilemap:inBounds(tx, ty) then
        v[1] = 0
        collision[1] = true
      end
    end
  end
  if v[2] ~= 0 then
    local j = sprite.y - 1
    if v[2] > 0 then
      j = sprite.y + sprite.h
    end
    for i = sprite.x, sprite.x + sprite.w - 1, 1 do
      local tx, ty = window.tilemap:fromAbsCoords(i, j)
      if window.tilemap:get(tx, ty) or
          not window.tilemap:inBounds(tx, ty) then
        v[2] = 0
        collision[2] = true
      end
    end
  end
  -- corner case
  if v[1] ~= 0 and v[2] ~= 0 then
    local x, y = sprite.x, sprite.y
    if v[1] < 0 then
      x = x - 1
    elseif v[1] > 0 then
      x = x + sprite.w
    end
    if v[2] < 0 then
      y = y - 1
    elseif v[2] > 0 then
      y = y + sprite.h
    end
    local tx, ty = window.tilemap:fromAbsCoords(x, y)
    if window.tilemap:get(tx, ty) or
        not window.tilemap:inBounds(tx, ty) then
      v[1] = 0
      collision[1] = true
    end
  end
  return collision
end

local function updateSprite(window, sprite)
  local v = sprite.velocity + sprite.ownVelocity
  capSpeed(v, MAXSPEED)
  local collision = resolveNearTileCollision(window, sprite, v)
  sprite.x = sprite.x + v[1]
  sprite.y = sprite.y + v[2]
  if checkCollision(window, sprite) then
    sprite.x = sprite.x - v[1]
    sprite.y = sprite.y - v[2]
    if #v > 0 then
      local cv = v:normalize()
      while not checkCollision(window, sprite) do
        sprite.x = sprite.x + cv[1]
        sprite.y = sprite.y + cv[2]
      end
      sprite.x = sprite.x - cv[1]
      sprite.y = sprite.y - cv[2]
    end
    local collisionSide = resolveNearTileCollision(window, sprite, v)
    collision[1] = collision[1] or collisionSide[1]
    collision[2] = collision[2] or collisionSide[2]
  end
  if isSpriteInMidair(window, sprite) then
    sprite.velocity = sprite.velocity + GRAVITY
  else
    sprite.velocity[2] = 0
    sprite.y = math.floor(sprite.y)
  end
  if collision[1] or collision[2] then
    sprite:handleCollision(window, collision)
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
