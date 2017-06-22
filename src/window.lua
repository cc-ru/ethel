local buf = require("doubleBuffering")

local FORMATMETA = {}
local function format(p)
  return setmetatable(p, FORMATMETA)
end

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

  function meta:calculateOffsets()
    local x, y = self.player.x, self.player.y

    local halfW = self.w / 2
    local totalWidth = self.tilemap.w * self.tilemap.gridSize * 2
    if x > halfW and x < totalWidth - halfW then
      self.scrollRight = math.floor(x - halfW)
    elseif x <= halfW then
      self.scrollRight = 0
    elseif x >= totalWidth - halfW then
      self.scrollRight = totalWidth - self.w
    end

    local halfH = self.h / 2
    local totalHeight = self.tilemap.h * self.tilemap.gridSize
    if y > halfH and y < totalHeight - halfH then
      self.scrollUp = math.floor(y - halfH)
    elseif y <= halfH then
      self.scrollUp = 0
    elseif y >= totalHeight - halfH then
      self.scrollUp = totalHeight - self.h
    end
  end

  function meta:render()
    self.background.texture:draw(1, 1)
    local lx, ly = self.tilemap:fromAbsCoords(self:toAbsCoords(1, 1))
    local ux, uy = self.tilemap:fromAbsCoords(self:toAbsCoords(self.w, self.h))
    for x = lx, ux, 1 do
      for y = ly, uy, -1 do
        local tile = self.tilemap:get(x, y)
        if tile then
          local gx, gy = self:fromAbsCoords(self.tilemap:toAbsCoords(x, y))
          tile:render(self, self.tilemap, gx, gy)
        end
      end
    end
    self.player:render(self, self.tilemap,
                       self:fromAbsCoords(
                         math.floor(self.player.x),
                         math.floor(self.player.y + self.player.h - 1)))
    for k, v in pairs(self.sprites) do
      v:render(self, self.tilemap,
               self:fromAbsCoords(
                 math.floor(v.x),
                 math.floor(v.y + v.h  - 1)))
    end

    local lines = {}
    for k, v in ipairs(self.text) do
      local line = {}
      for i = 1, #v, 1 do
        if type(v[i]) == "table" and getmetatable(v[i]) == FORMATMETA then
          if v[i][1] == "format" then
            line[#line + 1] = v[i][2]:format(table.unpack(v[i], 3))
          end
        elseif type(v[i]) == "table" and (not getmetatable(v[i]) or
            not getmetatable(v[i]).__tostring) then
          line[#line + 1] = require("serialization").serialize(v[i])
        else
          line[#line + 1] = tostring(v[i])
        end
      end
      if self.debug or not v.debug then
        lines[#lines + 1] = table.concat(line, "")
      end
    end
    for i = 1, #lines, 1 do
      buf.text(3, i + 2, 0xFFFFFF, lines[i])
    end
  end

  function newWindow(w, h)
    local o = {
      w = w,
      h = h,
      tilemap = nil,
      scrollRight = 0,
      scrollUp = 0,
      background = nil,
      sprites = {},
      player = nil,
      debug = false,
      text = {
        {"Lives: ", 3},
        {"Level: ", -1, "-", -1},
        {"FPS: ", format {"format", "%2.0f", 0}, " / took ", 0, "s",
         debug=true},
        {"Mem: ", 0, " used, ", 0, " free, ", 0, " total : ",
         format {"format", "%.1f", 0}, "%",
         debug=true},
        {"X: ", 0,
         debug=true},
        {"Y: ", 0,
         debug=true},
        {"v: ", nil,
         debug=true},
        {"ov: ", nil,
         debug=true},
        {"sprites: ", 0,
         debug=true},
        {"sr: ", 0,
         debug=true},
        {"su: ", 0,
         debug=true},
        {"Sprite: ", "x=", format {"format", "%.4f", 0},
         ", y=", format {"format", "%.4f", 0},
         debug=true},
        {"sv: ", nil,
         debug=true},
        {"sov: ", nil,
         debug=true}
      }
    }
    return setmetatable(o, meta)
  end
end

return {
  newWindow = newWindow
}
