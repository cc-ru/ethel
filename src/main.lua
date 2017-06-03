local com = require("component")
local event = require("event")
local kbd = require("keyboard")

local buf = require("doubleBuffering")
local vector = require("vector")

local gpu = com.gpu

local w, h = gpu.getViewport()

local module = require("ethel.module")
module.clearCache()

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

mainWindow.tilemap:set(tile.stone, 10, 5)

mainWindow.player = sprite.player(3, 6)

local running = true

local listeners = {
  {"key_down", function(_, _, code, key)
     if key == kbd.keys.right then
       mainWindow.player.ownVelocity[1] = 1
     end
     if key == kbd.keys.left then
       mainWindow.player.ownVelocity[1] = -1
     end
     if key == kbd.keys.up and mainWindow.player.ownVelocity[2] == 0 then
       mainWindow.player.ownVelocity[2] = 2
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
  mainWindow:render()
  buf.draw()
  gpu.setForeground(0xFFFFFF)
  gpu.set(2, 2, tostring(require("computer").uptime() - t0) .. " {" .. table.concat({mainWindow.player.x, mainWindow.player.y}, "; ") .. "}")
  gpu.set(2, 3, tostring(mainWindow.player.ownVelocity) .. "; " .. tostring(mainWindow.player.velocity))
end

for k, v in pairs(listeners) do
  event.ignore(v[1], v[2])
end

buf.draw(true)

buf.clear(0x000000)
buf.draw(true)

gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)
