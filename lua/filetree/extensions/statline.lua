local Line = require("statline.line")
local Part = require("statline.part")
local Help = require("statline.help")

local Extension = require("filetree.extension")
local ExtStatline = Extension:inherit()

function ExtStatline:new(conf)
  local self = setmetatable(Extension:new("statline", conf), { __index = ExtStatline })
  return self
end

function ExtStatline:init(filetree)
  self.info_line = self:setup_info_line(filetree)
  _G.statline:add_status_line(self.info_line)
end

function ExtStatline:setup_info_line(filetree)
  local line = Line:new("color1", function(conf) return conf.win == filetree.view.win end)

  self.path_part = Part:new(function(conf, builder)
    builder:write("color1", " "..filetree:get_rel_directory())
  end)

  self.pos_part = Part:new(function(conf, builder)
    builder:write("color1", filetree.view:get_cursor().."/"..filetree.view:get_node_count())
  end)

  line:add_left(self.path_part)
  line:add_right(self.pos_part)
  return line
end

return ExtStatline
