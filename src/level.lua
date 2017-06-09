local module = require("module")
local config = module.load("util.config")
local tile = module.load("tile")
local tilemap = module.load("tilemap")

local function loadLevel(path)
  local cfg = config.loadFile(path)
  local level = {
    width = tonumber(cfg.width),
    height = tonumber(cfg.height),
    name = cfg.name or "Unnamed",
    world = tonumber(cfg.world) or -1,
    level = tonumber(cfg.level),
    background = cfg.background or "background.main"
  }

  if not cfg.map or not cfg.tiles then
    return false
  end

  local map = {}
  for line in cfg.map:gsub("[^\n]+") do
    table.insert(map, line)
  end

  level.height = level.height or #map
  if level.height < #map then
    for i = #map - level.height, 1, -1 do
      table.remove(map, i)
    end
  elseif level.height > #map then
    for i = 1, level.height - #map, 1 do
      table.insert(map, 1, "")
    end
  end

  if not level.width then
    level.width = 0
    for k, v in pairs(map) do
      level.width = math.max(level.width, #v)
    end
  end
  level.tilemap = newTilemap(level.width, level.height)
  level.sprites = {}

  local tiles = load(cfg.tiles)()

  for y = 0, level.height - 1, 1 do
    local line = map[#map - i]
    local x = 0
    line:gsub("[^ ]", function(c)
      if x < level.width then
        if tiles[c] then
          if tiles[c].type == "tile" then
            level.tilemap:set(tiles[c], x, y)
          elseif tiles[c].type == "sprite" then
            table.insert(level.sprites, tiles[c](x, y))
          end
        end
      end
      x = x + 1
    end)
  end
  return level
end

return {
  loadLevel = loadLevel
}
