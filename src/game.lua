local comp = require("computer")
local kbd = require("keyboard")

local buf = require("doubleBuffering")
local objects = require("lua-objects.lua_objects")

local module = require("ethel.module")
local evt = module.load("event")
local physics = module.load("physics")
local sprite = module.load("sprite")
local window = module.load("window")

local getResource = module.load("resource").getResource
local newClass = objects.newClass

local W, H = require("component").gpu.getViewport()


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
  {"Start game", "game-start"},
  {"Quit", "quit"}
}
Menu.ITEM_COLOR = 0xD2D2D2
Menu.SELECTED_ITEM_COLOR = 0xFFFFFF

function Menu:__new__()
  self.pos = 1
  self._subOnKeyDown = evt.engine:subscribe("key-down", 0, function(hdr, e)
    local key = e[3]
    if key == kbd.keys.up and self.pos > 1 then
      self.pos = self.pos - 1
    elseif key == kbd.keys.down and self.pos < #self.menu then
      self.pos = self.pos + 1
    elseif key == kbd.keys.enter then
      evt.engine:push(evt.engine:event(self.menu[self.pos][2])(self))
    end
  end)
end

function Menu:__destroy__()
  self._subOnKeyDown:destroy()
end

function Menu:update()
  getResource("background.main").texture:draw(1, 1)
  local texture = getResource("texture.title").texture
  local w = texture[1][1]
  local h = texture[1][2]
  local x = math.floor(W / 2 - w / 2)
  local y = 6
  texture:draw(x, y)

  local menuWidth = 0
  for k, v in pairs(self.menu) do
    menuWidth = math.max(menuWidth, #v[1])
  end
  x = math.floor(W / 2 - menuWidth / 2)

  local menuHeight = #self.menu * 2 - 1
  y = math.floor(H / 2 - menuHeight / 2)

  for i, item in ipairs(self.menu) do
    local color
    if self.pos == i then
      color = self.SELECTED_ITEM_COLOR
    else
      color = self.ITEM_COLOR
    end
    buf.text(x, y, color, item[1])
    y = y + 2
  end

  self:superCall('update')
end


local Game = newClass(State, {name="Game"})
Game.time = comp.uptime()

function Game:__new__(level)
  self.window = window.newWindow(W, H)
  self.lives = 3
  self:setLevel(level)

  self._subOnKeyDown = evt.engine:subscribe("key-down", 0, function(hdr, e)
    local key = e[3]
    if key == kbd.keys.right then
      self.window.player.ownVelocity[1] = 1.5
    end
    if key == kbd.keys.left then
      self.window.player.ownVelocity[1] = -1.5
    end
    if key == kbd.keys.up and
        not physics.isSpriteInMidair(self.window, self.window.player) then
      self.window.player.ownVelocity[2] = 2.75
    end
    if key == kbd.keys.down then
      evt.engine:push(
        evt.engine:event("player.down"){window=self.window, state=self})
    end
    if key == kbd.keys.f1 then
      self.window.debug = not self.window.debug
    end
  end)

  self._subOnKeyUp = evt.engine:subscribe("key-up", 0, function(hdr, e)
    local key = e[3]
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
  self._subOnKeyDown:destroy()
  self._subOnKeyUp:destroy()
end

function Game:setLevel(level)
  self.window.tilemap = level.tilemap:clone()
  self.window.background = level.background
  self.window.player = level.player.class(level.player.x,
                                          level.player.y)
  self.window.sprites = {}
  for k, v in pairs(level.sprites) do
    table.insert(self.window.sprites, v.class(v.x, v.y))
  end

  self.level = level
end

function Game:update()
  local dt = comp.uptime() - self.time
  self.time = comp.uptime()
  for k, v in pairs(self.window.sprites) do
    v:update(self.window, self.window.tilemap)
  end

  self.window.player:update(self.window, self.window.tilemap)
  physics.progress(self.window, 1)
  self.window:calculateOffsets()
  self.window:clearDeadSprites()

  self.window.text[1][2] = self.lives
  self.window.text[2][2] = self.level.world
  self.window.text[2][4] = self.level.level
  self.window.text[3][2][3] = 1 / dt
  self.window.text[3][4] = dt
  self.window.text[4][2] = comp.totalMemory() - comp.freeMemory()
  self.window.text[4][4] = comp.freeMemory()
  self.window.text[4][6] = comp.totalMemory()
  self.window.text[4][8][3] = 1 - comp.freeMemory() / comp.totalMemory()
  self.window.text[5][2] = self.window.player.x
  self.window.text[6][2] = self.window.player.y
  self.window.text[7][2] = self.window.player.velocity
  self.window.text[8][2] = self.window.player.ownVelocity
  self.window.text[9][2] = #self.window.sprites
  self.window.text[10][2] = self.window.scrollRight
  self.window.text[11][2] = self.window.scrollUp
  self.window.text[12][3][3] = self.window.sprites[1].x
  self.window.text[12][5][3] = self.window.sprites[1].y
  self.window.text[13][2] = self.window.sprites[1].velocity
  self.window.text[14][2] = self.window.sprites[1].ownVelocity

  self.window:render()

  self:superCall('update')
end

return {
  State = State,
  Menu = Menu,
  Game = Game
}
