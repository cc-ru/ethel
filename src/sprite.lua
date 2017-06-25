local objects = require("lua-objects.lua_objects")
local vector = require("vector")

local module = require("ethel.module")
local tile = module.load("tile")

local getResource = module.load("resource").getResource
local newClass = objects.newClass

local Sprite = newClass(nil, {name="Sprite"})
Sprite.x = 0
Sprite.y = 0
Sprite.w = 0
Sprite.h = 0
Sprite.render = function() end
Sprite.velocity = vector(0, 0)
Sprite.ownVelocity = vector(0, 0)
Sprite.sprite = ""
Sprite.isDead = false

function Sprite:__new__(x, y)
  self.x = x
  self.y = y
  self.w = self.w * 2
  self.velocity = vector(0, 0)
  self.ownVelocity = vector(0, 0)
end

function Sprite:handleCollision(window, collision)
end

function Sprite:handleSpriteCollision(window, other, collision)
end

function Sprite:update()
end


local Enemy = newClass(Sprite, {name="Enemy"})


local Player = newClass(Sprite, {name="Player"})
Player.w = 2
Player.h = 5
Player.sprite = "player"
Player.render = tile.renderFromResource(getResource("sprite.player"))

function Player:handleCollision(window, collision)
  if collision[2] and self.ownVelocity[2] > 0 then
    self.ownVelocity[2] = 0
  end
end


local Chort = newClass(Enemy, {name="Chort"})
Chort.w = 3
Chort.h = 3
Chort.render = tile.renderFromResource(getResource("sprite.chort"))
Chort.direction = -1
Chort.sprite = "chort"

function Chort:update(window, tilemap)
  self.ownVelocity[1] = 0.2 * self.direction
end

function Chort:handleCollision(window, collision)
  if collision[1] then
    self.direction = -self.direction
  end
end

function Chort:handleSpriteCollision(window, other, collision)
  if other:isa(Player) then
    if collision[2] and collision[2] >= 0 then
      -- RIP.
      self.isDead = true
      other.velocity[2] = 0.5
    else
      -- RIP, too.
      other.isDead = true
    end
  end
end

return {
  Sprite = Sprite,
  Player = Player,
  Chort = Chort
}
