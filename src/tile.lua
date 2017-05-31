local newTile do
  local meta = {}

  function newTile(type, renderFunc)
    return function()
      local o = {
        render = render,
        type = type
      }
      return setmetatable(o, meta)
    end
  end
end

local function renderFromResource(resource)
  return function(self, window, tilemap, gx, gy)
    local x, y = window:toAbsCoords(gx, gy)
    if resource.texture.type == "static" then
      resource.texture:draw(gx, gy)
    elseif resources.textures.type == "connected" then
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

local wall = newTile("wall", renderFromTexture(loadResource("tile.wall")))
