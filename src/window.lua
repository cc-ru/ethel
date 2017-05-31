local newWindow do
  local meta = {}
  meta.__index = meta

  function meta:fromAbsCoords(x, y)
    return x - self.scrollRight + 1,
           self.h - (y - self.scrollUp)
  end

  function meta:toAbsCoords(x, y)
    return x + self.scrollRight - 1,
           (self.h + self.scrollUp) - (y - 1)
  end

  function newWindow(w, h)
    local o = {
      w = w,
      h = h,
      tilemap = nil,
      scrollRight = 0,
      scrollUp = 0
    }
    return setmetatable(o, meta)
  end
end
