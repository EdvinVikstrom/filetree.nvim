local InfoView = {}

function InfoView:new(conf)
  local self = setmetatable({}, { __index = InfoView })
  self.config = conf
  return self
end

return InfoView
