local buf = require("doubleBuffering")

local newWindow do
  local meta = {}
  meta.__index = meta

  function meta:fromAbsCoords(x, y)
    return x - self.scrollRight + 1,
           self.h - (y - self.scrollUp)
  end

  function meta:toAbsCoords(x, y)
    return x + self.scrollRight - 1,
           (self.h + self.scrollUp) - y
  end

  function meta:render()
    self.background.texture:draw()
    local lx, ly = self.tilemap:fromAbsCoords(self:toAbsCoords(1, 1))
    local ux, uy = self.tilemap:fromAbsCoords(self:toAbsCoords(self.w, self.h))
    for x = lx, ux, 1 do
      for y = ly, uy, 1 do
        local tile = self.tilemap:get(x, y)
        if tile then
          local gx, gy = self:fromAbsCoords(self.tilemap:toAbsCoords(x, y))
          tile:render(self, self.tilemap, gx, gy)
        end
      end
    end
  end

  function newWindow(w, h)
    local o = {
      w = w,
      h = h,
      tilemap = nil,
      scrollRight = 0,
      scrollUp = 0,
      background = nil
    }
    return setmetatable(o, meta)
  end
end

return {
  newWindow = newWindow
}
