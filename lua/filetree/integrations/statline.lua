local Line = require("statline.line")
local Part = require("statline.part")
local Help = require("statline.help")

local Extension = require("statline.extension")
local ExtStatline = Extension:inherit()

function ExtStatline:new(filetree, conf)
  local self = setmetatable(Extension:new("filetree", conf), { __index = ExtStatline })
  self.filetree = filetree
  self.config = (conf or {})
  return self
end

function ExtStatline:init(statline)
  self.info_line = self:setup_info_line(filetree)
  _G.statline:add_status_line(self.info_line)
end

function ExtStatline:setup_info_line()
  local line = Line:new("color1", function(conf) return conf.win == self.filetree.view.win end)

  self.path_part = Part:new(function(conf, builder)
    builder:write("color1", " "..self.filetree:get_rel_directory())
  end)

  self.pos_part = Part:new(function(conf, builder)
    builder:write("color1", self.filetree.view:get_cursor().."/"..self.filetree.view:get_node_count())
  end)

  line:add_left(self.path_part)
  line:add_right(self.pos_part)
  return line
end

return ExtStatline
