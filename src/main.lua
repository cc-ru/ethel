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
mainWindow.tilemap = tilemap.newTilemap(160, 50)
mainWindow.background = getResource("background.main")

local lx = mainWindow.tilemap:fromAbsCoords(mainWindow:toAbsCoords(1, h))
local ux = mainWindow.tilemap:fromAbsCoords(mainWindow:toAbsCoords(w, h))
for i = lx, ux, 1 do
  for j = 0, 1, 1 do
    mainWindow.tilemap:set(tile.stone, i, j)
  end
end

for i = 5, 9, 1 do
  mainWindow.tilemap:set(tile.stone, 10, i)
end
for i = 10, 15, 1 do
  mainWindow.tilemap:set(tile.stone, i, 9)
end

for i = 4, 15, 1 do
  mainWindow.tilemap:set(tile.stone, 17, i)
end

for i = 20, 158, 2 do
  for j = 0, 1, 1 do
    mainWindow.tilemap:set(tile.stone, i, j)
    mainWindow.tilemap:set(nil, i + 1, j)
    mainWindow.tilemap:set(tile.stone, i, 4)
    mainWindow.tilemap:set(tile.stone, i + 1, 4)
  end
end

mainWindow.player = sprite.player(3, 6)

local running = true

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

while running do
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
