local objects = require("lua-objects.lua_objects")

local module = require("ethel.module")
local evt = module.load("event")

local getResource = module.load("resource").getResource

local newClass = objects.newClass


local function renderFromResource(resource)
  return function(self, window, tilemap, gx, gy)
    local x, y = window:toAbsCoords(gx, gy)
    if resource.texture.type == "static" then
      resource.texture:draw(gx, gy)
    elseif resource.texture.type == "connected" then
      local tx, ty = tilemap:fromAbsCoords(x, y)
      local left = tilemap:get(tx - 1, ty)
      local right = tilemap:get(tx + 1, ty)
      local top = tilemap:get(tx, ty + 1)
      local bottom = tilemap:get(tx, ty - 1)
      left   = left   and   left.type == self.type
      right  = right  and  right.type == self.type
      top    = top    and    top.type == self.type
      bottom = bottom and bottom.type == self.type
      resource.texture:get(left, right, top, bottom):draw(gx, gy)
    end
  end
end


local Tile = newClass(nil, {name="Tile"})
Tile.passable = false

function Tile:render()
  error("abstract class " .. self.NAME .. " doesn't have :render()")
end


local StaticTile = newClass(Tile, {name="StaticTile"})
StaticTile.instance = nil

function StaticTile:create()
  self.instance = self.instance or self()
  return self.instance
end


local DynamicTile = newClass(Tile, {name="DynamicTile"})

function DynamicTile:create(x, y)
  return self(x, y)
end


local Stone = newClass(StaticTile, {name="Stone"})
Stone.render = renderFromResource(getResource("tile.stone"))


local Teleporter = newClass(DynamicTile, {name="Teleporter"})
Teleporter.target = getResource("level.debug")
Teleporter.render = renderFromResource(getResource("tile.teleporter"))

function Teleporter:__new__(x, y)
  self.x = x
  self.y = y
  self._onPlayerDown = evt.engine:subscribe("player.down", 0,
                                            evt.wrap(self, self.onPlayerDown))
end

function Teleporter:onPlayerDown(hdr, e)
  local x, y = self.x, self.y

  local lx, py = e.window.player.x, e.window.player.y
  local ux = lx + e.window.player.w - 1
  lx, py = e.window.tilemap:fromAbsCoords(lx, py)
  ux = e.window.tilemap:fromAbsCoords(ux, py)

  if py - 1 == y then
    for ix = lx, ux, 1 do
      if ix == x then
        evt.engine:push(
          evt.engine:event("command.set-level"){level=self.target.level})
        return
      end
    end
  end
end

function Teleporter:__destroy__()
  self._onPlayerDown:destroy()
end


return {
  renderFromResource = renderFromResource,
  Tile = Tile,
  StaticTile = StaticTile,
  DynamicTile = DynamicTile,
  Stone = Stone,
  Teleporter = Teleporter
}
