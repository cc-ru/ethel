local com = require("component")
local event = require("event")
local kbd = require("keyboard")

local buf = require("doubleBuffering")
local vector = require("vector")

local gpu = com.gpu

local w, h = gpu.getViewport()
buf.start()

local module = require("ethel.module")
module.clearCache()

local physics = module.load("physics")
local sprite = module.load("sprite")
local tile = module.load("tile")
local tilemap = module.load("tilemap")
local window = module.load("window")

local getResource = module.load("resource").getResource
local progress = module.load("physics").progress

buf.clear(0x000000)

local mainWindow = window.newWindow(160, 50)
local level = getResource("level.debug").level
mainWindow.tilemap = level.tilemap
mainWindow.background = level.background

for _, v in pairs(level.sprites) do
  if v.name == "player" then
    mainWindow.player = v
  else
    table.insert(mainWindow.sprites, v)
  end
end

local listeners = {
  {"key_down", function(_, _, code, key)
     if key == kbd.keys.right then
       mainWindow.player.ownVelocity[1] = 1.5
     end
     if key == kbd.keys.left then
       mainWindow.player.ownVelocity[1] = -1.5
     end
     if key == kbd.keys.up and
         not physics.isSpriteInMidair(mainWindow, mainWindow.player) then
       mainWindow.player.ownVelocity[2] = 1.5
     end
     if key == kbd.keys.f1 then
       mainWindow.debug = not mainWindow.debug
     end
   end},
  {"key_up", function(_, _, code, key)
     if key == kbd.keys.right then
       mainWindow.player.ownVelocity[1] = 0
     end
     if key == kbd.keys.left then
       mainWindow.player.ownVelocity[1] = 0
     end
     if key == kbd.keys.up then
       mainWindow.player.ownVelocity[2] = 0
     end
   end}
}

for k, v in pairs(listeners) do
  event.listen(v[1], v[2])
end

while true do
  local t0 = require("computer").uptime()
  if event.pull(0.05, "interrupted") then
    break
  end
  for k, v in pairs(mainWindow.sprites) do
    v:update(mainWindow, mainWindow.tilemap)
  end
  mainWindow.player:update(mainWindow, mainWindow.tilemap)
  progress(mainWindow, 1)
  mainWindow:calculateOffsets()

  local dt = require("computer").uptime() - t0
  mainWindow.text[2][2][3] = 1 / dt
  mainWindow.text[2][4] = dt
  mainWindow.text[3][2] = mainWindow.player.x
  mainWindow.text[4][2] = mainWindow.player.y
  mainWindow.text[5][2] = mainWindow.player.velocity
  mainWindow.text[6][2] = mainWindow.player.ownVelocity
  mainWindow.text[7][2] = #mainWindow.sprites
  mainWindow.text[8][2] = mainWindow.scrollRight
  mainWindow.text[9][2] = mainWindow.scrollUp
  mainWindow.text[10][3][3] = mainWindow.sprites[1].x
  mainWindow.text[10][5][3] = mainWindow.sprites[1].y
  mainWindow.text[11][2] = mainWindow.sprites[1].velocity
  mainWindow.text[12][2] = mainWindow.sprites[1].ownVelocity

  mainWindow:render()
  buf.draw()
end

for k, v in pairs(listeners) do
  event.ignore(v[1], v[2])
end

buf.draw(true)

buf.clear(0x000000)
buf.draw(true)

gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)
