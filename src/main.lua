local buf = require("doubleBuffering")
local com = require("component")

local gpu = com.gpu

local w, h = gpu.getViewport()
buf.setDrawLimit(1, 1, w, h)

local module = require("ethel.module")
module.clearCache()

local tile = module.load("tile")
local tilemap = module.load("tilemap")
local window = module.load("window")

local getResource = module.load("resource").getResource

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

mainWindow:render()

buf.draw(true)

os.sleep(10)

buf.clear(0x000000)
buf.draw(true)

gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)
