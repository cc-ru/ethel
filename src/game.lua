local buf = require("doubleBuffering")
local objects = require("lua-object.lua_objects")

local module = require("ethel.module")

local getResource = module.load("resource").getResource
local newClass = objects.newClass

local W, H = require("component").gpu.getViewport()

local State = newClass(nil, {name="State"})

function State:__new__()
end

function State:__destroy__()
end

function State:update()
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
end
