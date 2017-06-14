local comp = require("computer")
local kbd = require("keyboard")

local buf = require("doubleBuffering")
local objects = require("lua-object.lua_objects")

local module = require("ethel.module")
local evt = module.load("event")
local physics = module.load("physics")
local sprite = module.load("sprite")
local window = module.load("window")

local getResource = module.load("resource").getResource
local newClass = objects.newClass

local W, H = require("component").gpu.getViewport()

local curState = nil


local State = newClass(nil, {name="State"})

function State:__new__()
end

function State:__destroy__()
end

function State:update()
  buf.draw()
end


local Menu = newClass(State, {name="Menu"})
Menu.menu = {
  "Start game",
  "Quit"
}
Menu.ITEM_COLOR = 0xB2B2B2
Menu.SELECTED_ITEM_COLOR = 0xFFFFFF

function Menu:__new__()
  self.pos = 1
  evt.register("menu.onKeyDown", "key_down", function(_, _, code, key)
    if key == kbd.keys.up and self.pos > 1 then
      self.pos = self.pos - 1
    elseif key == kbd.keys.down and self.pos < #self.menu then
      self.pos = self.pos + 1
    end
  end)
end

function Menu:__destroy__()
  evt.unregister("menu.onKeyDown")
end

function Menu:update()
  getResource("background.main").texture:draw(1, 1)
  local texture = getResource("texture.title").texture
  local w = texture[1][1]
  local h = texture[1][2]
  local x = math.floor(W / 2 - w / 2)
  local y = 6
  texture:draw(x, y)

  y = y + h + 2
  local menuWidth = 0
  for k, v in pairs(self.menu) do
    menuWidth = math.max(menuWidth, #v)
  end
  x = math.floor(W / 2 - menuWidth / 2)

  for i, item in ipairs(self.menu) do
    local color
    if self.pos == i then
      color = self.SELECTED_ITEM_COLOR
    else
      color = self.ITEM_COLOR
    end
    buf.text(x, y, color, item)
    y = y + 2
  end

  self:superCall('update')
end


local Game = newClass(State, {name="Game"})
Game.time = comp.uptime()

function Game:__new__(level)
  self.window = window.newWindow(W, H)
  self.window.tilemap = level.tilemap:clone()
  self.window.background = level.background
  for _, v in pairs(level.sprites) do
    if v:isa(sprite.Player) then
      self.window.player = v
    else
      table.insert(self.window.sprites, v)
    end
  end

  evt.register("game.onKeyDown", "key_down", function(_, _, code, key)
     if key == kbd.keys.right then
       self.window.player.ownVelocity[1] = 1.5
     end
     if key == kbd.keys.left then
       self.window.player.ownVelocity[1] = -1.5
     end
     if key == kbd.keys.up and
         not physics.isSpriteInMidair(self.window, self.window.player) then
       self.window.player.ownVelocity[2] = 1.5
     end
     if key == kbd.keys.f1 then
       self.window.debug = not self.window.debug
     end
  end)

  evt.register("game.onKeyUp", "key_up", function(_, _, code, key)
     if key == kbd.keys.right then
       self.window.player.ownVelocity[1] = 0
     end
     if key == kbd.keys.left then
       self.window.player.ownVelocity[1] = 0
     end
     if key == kbd.keys.up then
       self.window.player.ownVelocity[2] = 0
     end
  end)
end

function Game:__destroy__()
  evt.unregister("game.onKeyUp")
  evt.unregister("game.onKeyDown")
end

function Game:update()
  local dt = comp.uptime() - self.time
  for k, v in pairs(self.window.sprites) do
    v:update(self.window, self.window.tilemap)
  end

  self.window.player:update(self.window, self.window.tilemap)
  physics.progress(self.window, 1)
  self.window:calculateOffsets()

  self.window.text[2][2][3] = 1 / dt
  self.window.text[2][4] = dt
  self.window.text[3][2] = self.window.player.x
  self.window.text[4][2] = self.window.player.y
  self.window.text[5][2] = self.window.player.velocity
  self.window.text[6][2] = self.window.player.ownVelocity
  self.window.text[7][2] = #self.window.sprites
  self.window.text[8][2] = self.window.scrollRight
  self.window.text[9][2] = self.window.scrollUp
  self.window.text[10][3][3] = self.window.sprites[1].x
  self.window.text[10][5][3] = self.window.sprites[1].y
  self.window.text[11][2] = self.window.sprites[1].velocity
  self.window.text[12][2] = self.window.sprites[1].ownVelocity

  self.window:render()

  self:superCall('update')
end
