local com = require("component")
local event = require("event")
local kbd = require("keyboard")

local buf = require("doubleBuffering")
local vector = require("vector")

local gpu = com.gpu

buf.start()

local module = require("ethel.module")
local game = module.load("game")
module.clearCache()

local getResource = module.load("resource").getResource

buf.clear(0x000000)

local curState = game.Game(getResource("level.debug").level)

while true do
  if event.pull(0.05, "interrupted") then
    break
  end

  curState:update()
end

curState:destroy()

buf.clear(0x000000)
buf.draw(true)

gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)
