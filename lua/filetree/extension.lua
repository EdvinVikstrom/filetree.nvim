local Extension = {}

-- return: Extension
function Extension:inherit()
  local self = setmetatable({}, { __index = Extension })
  return self
end

-- params: {name: String, conf: Table}
-- return: Extension
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

function Extension:init(filetree)
end

return Extension
