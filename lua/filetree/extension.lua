local Extension = {}

---@returns Extension metatable
function Extension:inherit()
  local self = setmetatable({}, { __index = Extension })
  return self
end

---@param name  name of the extension
---@param conf  table with options {option = value, ...}. |filetree-config|
---@returns Extension metatable
function Extension:new(name, conf)
  local self = setmetatable({}, { __index = Extension })
  self.name = name
  self.config = conf
  return self
end

function Extension:setup_highlight()
end

function Extension:setup_config()
end

function Extension:setup_autocmds()
end

function Extension:setup_keymaps()
end

---@param filetree  FileTree metatable
function Extension:init(filetree)
end

return Extension
