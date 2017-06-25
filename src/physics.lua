local vector = require("vector")

local module = require("ethel.module")
local log = module.load("util.logger")

local GRAVITY = vector(0, -0.2)
local MAXSPEED = 10

local function checkRectCollision(a, b)
  return a.x < b.x + b.w and
         a.x + a.w > b.x and
         a.y < b.y + b.h and
         a.y + a.h > b.y
end

local function isTileCollisionable(window, x, y)
  if not window.tilemap:inBounds(x, y) then
    return true
  end
  local tile = window.tilemap:get(x, y)
  if not tile then
    return false
  end
  if tile.passable then
    return false
  end
  return true
end

local function isSpriteInMidair(window, sprite)
  for x = sprite.x, sprite.x + sprite.w - 1, 1 do
    local tx, ty = window.tilemap:fromAbsCoords(x, sprite.y - 1)
    if isTileCollisionable(window, tx, ty) then
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
      if isTileCollisionable(window, tx, ty) then
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
      if isTileCollisionable(window, tx, ty) then
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
      if isTileCollisionable(window, tx, ty) then
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
    if isTileCollisionable(window, tx, ty) then
      v[1] = 0
      collision[1] = true
    end
  end
  return collision
end

local function updateSprite(window, sprite)
  local vsum = sprite.velocity + sprite.ownVelocity
  capSpeed(vsum, MAXSPEED)
  local normalized = vsum:normalize()
  local magnitude = #vsum
  for i = 1, math.ceil(magnitude), window.tilemap.gridSize do
    i = math.min(i, magnitude)
    local v = normalized * i
    local collision
    if not sprite.isDead then
      collision = resolveNearTileCollision(window, sprite, v)
    else
      collision = {false, false}
    end
    sprite.x = sprite.x + v[1]
    sprite.y = sprite.y + v[2]
    if not sprite.isDead and checkCollision(window, sprite) then
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
    if isSpriteInMidair(window, sprite) or sprite.isDead then
      sprite.velocity = sprite.velocity + GRAVITY
    else
      sprite.velocity[2] = 0
      sprite.y = math.floor(sprite.y)
    end
    if collision[1] or collision[2] then
      sprite:handleCollision(window, collision)
    end
  end
end

local function checkSpriteNear(a, b)
  local ax, ay, aw, ah = math.floor(a.x), math.floor(a.y), a.w, a.h
  local bx, by, bw, bh = math.floor(b.x), math.floor(b.y), b.w, b.h
  local collision = {false, false}
  if ax + aw == bx and ay + ah - 1 >= by - 1 and ay <= by + bh then
    collision[1] = 1
  elseif ax == bx + bw and ay + ah - 1 >= by - 1 and ay <= by + bh then
    collision[1] = -1
  elseif ay + ah == by and ax + aw - 1 >= bx - 1 and ax <= bx + bw then
    collision[2] = 1
  elseif ay == by + bh and ax + aw - 1 >= bx - 1 and ax <= bx + bw then
    collision[2] = -1
  end
  return collision
end

local function checkSpriteCollision(window)
  local sprites = {}
  if not window.player.isDead then
    sprites[1] = window.player
  end
  for k, v in pairs(window.sprites) do
    if not v.isDead then
      sprites[#sprites + 1] = v
    end
  end
  for i = 1, #sprites - 1, 1 do
    for j = i + 1, #sprites, 1 do
      local a, b = sprites[i], sprites[j]
      local collision = checkRectCollision(a, b)
      if collision then
        collision = {0, 0}
      else
        collision = checkSpriteNear(a, b)
      end
      log.logger:debug("collision", a, b, collision[1], collision[2])
      if collision[1] or collision[2] then
        a:handleSpriteCollision(window, b, collision)
        b:handleSpriteCollision(window, a,
                                {collision[1] and -collision[1] or false,
                                 collision[2] and -collision[2] or false})
      end
    end
  end
end

local function progress(window, t)
  for i = 1, t, 1 do
    for _, sprite in pairs(window.sprites) do
      updateSprite(window, sprite)
    end
    updateSprite(window, window.player)
    checkSpriteCollision(window)
  end
end

return {
  checkRectCollision = checkRectCollision,
  isSpriteInMidair = isSpriteInMidair,
  progress = progress
}
