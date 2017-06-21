local fs = require("filesystem")

local objects = require("lua-objects.lua_objects")

local newClass = objects.newClass


local Logger = newClass(nil, {name="Logger"})
Logger.lineFormat = "[#{date:%Y-%m-%d %H:%M:%S}] [#{level}] " ..
                    "#{stack:namewhat} #{stack:source}::#{stack:name}:" ..
                    "#{stack:currentline}: #{msg}"
Logger.LEVELS = {
  "DEBUG",
  "INFO",
  "ERROR",
  "FATAL",
  DEBUG = 1,
  INFO = 2,
  ERROR = 3,
  FATAL = 4
}
Logger.level = Logger.LEVELS.INFO

function Logger:__new__(buf)
  self.buf = buf
end

function Logger:__destroy__()
  self.buf:close()
end

function Logger:pack(...)
  local args = table.pack(...)
  for i = 1, args.n, 1 do
    args[i] = tostring(args[i])
  end
  return table.concat(args, "\t")
end

function Logger:writeLine(level, stackInfo, message)
  stackInfo = stackInfo or debug.getinfo(2)
  local line = self.lineFormat:gsub("#(%b{})", function(group)
    group = group:sub(2, -2)
    if group:sub(1, 5) == "date:" then
      return os.date(group:sub(6))
    elseif group:sub(1, 6) == "stack:" then
      return tostring(stackInfo[group:sub(7)])
    elseif group == "msg" then
      return message
    elseif group == "level" then
      return level
    end
  end)
  self.buf:write(line .. "\n")
end

function Logger:debug(...)
  local message = self:pack(...)
  if self.level <= self.LEVELS.DEBUG then
    self:writeLine("DEBUG", debug.getinfo(3), message)
  end
end

function Logger:info(...)
  local message = self:pack(...)
  if self.level <= self.LEVELS.INFO then
    self:writeLine("INFO", debug.getinfo(3), message)
  end
end

function Logger:error(...)
  local message = self:pack(...)
  if self.level <= self.LEVELS.ERROR then
    self:writeLine("ERROR", debug.getinfo(3), message)
  end
end

function Logger:fatal(...)
  local message = self:pack(...)
  if self.level <= self.LEVELS.FATAL then
    self:writeLine("FATAL", debug.getinfo(3), message)
  end
end

function Logger:traceback(level)
  level = level or "DEBUG"
  local stackInfo = debug.getinfo(3)
  self:writeLine(level, stackInfo, "Stack traceback:")
  for stackLevel = 1, math.huge, 1 do
    local info = debug.getinfo(stackLevel, "Slnu")
    if not info then
      break
    end

    self:writeLine(level, stackInfo, ("   %3d. "):format(stackLevel) ..
                                     tostring(info.what) .. " " ..
                                     tostring(info.namewhat) .. " " ..
                                     tostring(info.source) .. ":" ..
                                     tostring(info.linedefined) .. ".." ..
                                     tostring(info.lastlinedefined) .. "::" ..
                                     tostring(info.name) .. "(" ..
                                     tonumber(info.nparams) ..
                                     (info.isvararg and
                                              ", ..." or
                                              "") .. "):" ..
                                     tostring(info.currentline))
    stackLevel = stackLevel + 1
  end
end


local FileLogger = newClass(Logger, {name="FileLogger"})

function FileLogger:__new__(path, mode)
  mode = mode or "a"
  local buf = io.open(path, mode)
  assert(buf, "failed to open file")
  self:superCall("__new__", buf)
end


local mod = {logger = nil}
function mod.init(path)
  mod.logger = FileLogger(path)
  return mod.logger
end

return mod
