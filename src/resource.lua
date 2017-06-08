local bit32 = require("bit32")
local buf = require("doubleBuffering")
local fs = require("filesystem")
local image = require("image")

local module = require("module")
local config = module.load("util.config")

local paths = {
  fs.concat(os.getenv("_"), "../resources"),
  "/usr/share/ethel"
}

for i = #paths, 1, -1 do
  local v = paths[i]
  if not fs.exists(v) or not fs.isDirectory(v) then
    table.remove(paths, i)
  end
end

local loaded = {}

local function newResource(resourceType)
  local o = {
    type = resourceType
  }
  return o
end

local loadTexture do
  local textureMeta = {}
  textureMeta.__index = textureMeta

  function textureMeta:draw(gx, gy)
    buf.image(gx, gy, self)
  end

  local meta = {}
  meta.__index = meta

  function meta:draw(gx, gy)
    self[1]:draw(gx, gy)
  end

  local connectedMeta = {}
  connectedMeta.__index = connectedMeta
  setmetatable(connectedMeta, meta)

  function connectedMeta:get(left, right, top, bottom)
    local index = bit32.bor(bit32.lshift(left and 1 or 0, 3),
                            bit32.lshift(right and 1 or 0, 2),
                            bit32.lshift(top and 1 or 0, 1),
                            bottom and 1 or 0)
    return self[index]
  end

  function loadTexture(params, name, path)
    local resource = newResource("texture")
    resource.texture = {}
    local files = {}
    for v in params.textures:gmatch("%S+") do
      table.insert(files, v)
    end
    if params["texture type"]:lower() == "static" then
      resource.texture[1] = setmetatable(image.load(fs.concat(path, files[1])),
                                         textureMeta)
      resource.texture.type = "static"
      setmetatable(resource.texture, meta)
    elseif params["texture type"]:lower() == "connected" then
      for i = 1, 16, 1 do
        resource.texture[i] = setmetatable(image.load(
          fs.concat(path, files[i])), textureMeta)
      end
      resource.texture.type = "connected"
      setmetatable(resource.texture, connectedMeta)
    elseif params["texture type"]:lower() == "compound" then
      for i = 1, #files, 1 do
        resource.texture[i] = setmetatable(image.load(
          fs.concat(path, files[i])), textureMeta)
      end
      resource.texture.type = "compound"
      setmetatable(resource.texture, meta)
    end
    return resource
  end
end

local resources = {}
for k, v in ipairs(paths) do
  for resourceCategory in fs.list(v) do
    for resource in fs.list(fs.concat(v, resourceCategory)) do
      local name = fs.name(resourceCategory) .. "." .. fs.name(resource)
      resources[name] = fs.concat(
        v,
        resourceCategory,
        resource)
    end
  end
end
for name, path in pairs(resources) do
  local metaPath = fs.concat(path, "resource.meta")
  if fs.exists(metaPath) then
    local params = config.loadFile(metaPath)

    local resource
    if params.type:lower() == "texture" then
      resource = loadTexture(params, name, path)
    end
    resource.path = path
    resource.name = name
    loaded[name] = resource
  end
end

local function getResource(name)
  if not loaded[name] then
    error("no such resource: " .. tostring(name))
  end
  return loaded[name]
end

return {
  getResource = getResource
}
