local module = require("ethel.module")
local config = module.load("util.config")
local sprite = module.load("sprite")
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
  local lines = cfg.map
  while lines ~= "" do
    local nlPos = lines:find("\n")
    table.insert(map, lines:sub(1, (nlPos or 0) - 1))
    lines = nlPos and lines:sub(nlPos + 1) or ""
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
  level.tilemap = tilemap.newTilemap(level.width, level.height)
  level.sprites = {}

  local tiles do
    local env = {}
    for k, v in pairs(_G) do
      env[k] = v
    end
    env.module = module
    env.sprite = sprite
    env.tile = tile
    env.tilemap = tilemap
    local chunk, reason = load(cfg.tiles, "level", "t", env)
    if not chunk then
      error(reason)
    end
    tiles = chunk()
  end
  for y = 0, level.height - 1, 1 do
    local line = map[level.height - y]
    local x = 0
    line:gsub(".", function(c)
      if c ~= " " then
        if x < level.width then
          if tiles[c] then
            if tiles[c].type == "tile" then
              level.tilemap:set(tiles[c], x, y)
            elseif tiles[c]:isa(sprite.Sprite) then
              if tiles[c]:isa(sprite.Player) then
                level.player = tiles[c](x * level.tilemap.gridSize * 2,
                                        y * level.tilemap.gridSize)
              else
                table.insert(level.sprites,
                             tiles[c](x * level.tilemap.gridSize * 2,
                                      y * level.tilemap.gridSize))
              end
            end
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
