local Line = require("statline.view.line")
local Section = require("statline.view.section")

local Extension = require("filetree.extension")
local ExtStatline = Extension:inherit()

-- params: {conf: Table}
-- return: ExtStatline
function ExtStatline:new(conf)
  local self = setmetatable(Extension:new("statline", conf), { __index = ExtStatline })
  return self
end

-- params: {filetree: FileTree}
function ExtStatline:init(filetree)
  local theme = _G.statline:get_theme()
  self.line = self:setup_line(filetree)
  theme:add_line(self.line, function(win) return win == filetree.view.win end)
end

-- params: {filetree: FileTree}
-- return statline.view.Line
function ExtStatline:setup_line(filetree)
  local line = Line:new()
  self.path_section = Section:new(function(theme, info, builder)
    builder:highlight("color1"):append(" "..filetree.tree.path)
  end)

  line:add_left_section(self.path_section)
  return line
end

return ExtStatline
