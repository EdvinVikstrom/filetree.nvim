local Node = {}

local Help = require("filetree.help")

---@returns Node metatable
function Node:inherit()
  local self = setmetatable({}, { __index = Node })
  return self
end

---@param name    file name
---@param path    file path
---@param parent  Tree metatable with path of file parent
---@param depth   directory level
---@param type    file type
---@returns Node metatable
function Node:new(name, path, parent, depth, type)
  local self = setmetatable({}, { __index = Node })
  self.config = conf
  self.name = name
  self.path = path
  self.parent = parent
  self.depth = depth
  self.type = type

  self.rpath = vim.fn.resolve(self.path)
  if (self.rpath ~= self.path) then
    self.rname = Help:get_file_name(self.rpath)
    self.rtype = Help:get_file_type(self.rpath)
  else
    self.rname = self.name
    self.rtype = self.type
  end

  self.tail = Help:get_file_extension(self.name)

  self.marked = false
  self.changed = true
  return self
end

function Node:mark()
  self.marked = true
  self.changed = true
end

function Node:unmark()
  self.marked = false
  self.changed = true
end

function Node:delete()
  self.parent:remove_node(self)
end

function Node:is_first()
  return self == self.parent.children[1]
end

function Node:is_last()
  return self == self.parent.children[#self.parent.children]
end

---@returns true if name starts with '.'
function Node:is_dot_file()
  return vim.startswith(self.name, ".")
end

return Node
