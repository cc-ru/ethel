local function checkBounds(x, y, w, h)
  return x >= 0 and y >= 0 and x <= w - 1 and y <= h - 1
end

local newTilemap do
  local meta = {}
  meta.__index = meta

  function meta:index(x, y)
    if checkBounds(x, y, self.w, self.h) then
      return y * self.w + x
    end
  end

  function meta:get(x, y)
    if checkBounds(x, y, self.w, self.h) then
      return self[self:index(x, y)]
    end
  end

  function meta:set(tile, x, y)
    if checkBounds(x, y, self.w, self.h) then
      self[self:index(x, y)] = tile
    end
  end

  function meta:inBounds(x, y)
    return checkBounds(x, y, self.w, self.h)
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
