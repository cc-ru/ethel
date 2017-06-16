local com = require("component")
local event = require("event")

local buf = require("doubleBuffering")

local gpu = com.gpu

buf.start()

local module = require("ethel.module")
module.clearCache()

local evt = module.load("event")
local game = module.load("game")

local getResource = module.load("resource").getResource

buf.clear(0x000000)

local curState = game.Menu()
local running = true

evt.engine:subscribe("game-start", 0, function(hdr, e)
  curState = game.Game(getResource("level.debug").level)
end)

evt.engine:subscribe("quit", 0, function(hdr, e)
  running = false
end)

while running do
  if event.pull(0.05, "interrupted") then
    break
  end

  curState:update()
end

curState:destroy()

evt.engine:__gc()

buf.clear(0x000000)
buf.draw(true)

gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)
