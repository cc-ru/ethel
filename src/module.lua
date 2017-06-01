local fs = require("filesystem")


local module = {}
module.cache = {}

module.path = {
  "/usr/lib/ethel/?.lua",
  "/usr/lib/ethel/?/init.lua",
  fs.concat(os.getenv("_"), "../?.lua"),
  fs.concat(os.getenv("_"), "../?/init.lua")
}

function module.load(name)
  if not module.cache[name] then
    local relPath = name:gsub("%.", "/")
    local path = false
    for _, lpath in pairs(module.path) do
      local candidate = lpath:gsub("?", relPath, nil, true)
      if fs.exists(candidate) then
        path = candidate
        break
      end
    end
    if not path then
      error("module not found: " .. name)
    end

    local chunk, reason = loadfile(path)
    if not chunk then
      error("could not load module '" .. name .. "': " .. tostring(reason))
    end
    local result = table.pack(xpcall(chunk, debug.traceback))
    if not result[1] then
      error("could not load module '" .. name .. "': " .. tostring(result[2]) .. "\n")
    end
    module.cache[name] = result
  end
  return table.unpack(module.cache[name], 2)
end

function module.clearCache()
  module.cache = {}
end

return module
