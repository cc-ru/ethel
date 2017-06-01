local module = require("ethel.module")

local tile = module.load("tile")
local tilemap = module.load("tilemap")
local window = module.load("window")

local getResource = module.load("resource").getResource

local mainWindow = window.newWindow(160, 50)
mainWindow.tilemap = tilemap.newTilemap(160, 50)
mainWindow.background = getResource("background.main")
mainWindow.tilemap:set(tile.wall, 4, 4)
mainWindow:render()
