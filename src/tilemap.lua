local function checkBounds(x, y, w, h)
  if x < 0 or y < 0 or x > w - 1 or y > h - 1 then
    error("{" .. x .. ", " .. y .. "} out of bounds {" .. w .. ", " .. h .. "}")
  end
end

local newTilemap do
  local meta = {}
  meta.__index = meta

  function meta:index(x, y)
    checkBounds(x, y, self.w, self.h)
    return y * self.w + x
  end

  function meta:get(x, y)
    checkBounds(x, y, self.w, self.h)
    return self[self:index(x, y)]
  end

  function meta:set(tile, x, y)
    checkBounds(x, y, self.w, self.h)
    self[self:index(x, y)] = tile
  end

  function meta:fromAbsCoords(x, y)
    return math.floor(x / self.gridSize / 2),
           math.floor(y / self.gridSize)
  end

  function meta:toAbsCoords(x, y)
    return x * self.gridSize * 2,
           y * self.gridSize + self.gridSize - 1
  end

  function newTilemap(w, h, gridSize)
    local o = {
      w = w,
      h = h,
      gridSize = gridSize or 3
    }
    return setmetatable(o, meta)
  end
end

return {
  newTilemap = newTilemap
}
