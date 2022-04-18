local Node = {}

local Help = require("filetree.help")

-- return Node
function Node:inherit()
  local self = setmetatable({}, { __index = Node })
  return self
end

-- params: {conf: Table, path: String, parent: Tree, depth: number, name: String, type: String}
-- return: Node
function Node:new(conf, path, parent, depth, name, type)
  local self = setmetatable({}, { __index = Node })
  self.config = conf
  self.path = path
  self.name = (name or Help:get_file_name(self.path))
  self.type = (type or vim.fn.getftype(self.path))
  self.parent = parent
  self.depth = depth

  if (self.type == "link") then
    self.rpath = vim.fn.resolve(self.path)
    self.rname = Help:get_file_name(self.rpath)
    self.rtype = vim.fn.getftype(self.rpath)
  else
    self.rpath = self.path
    self.rname = self.name
    self.rtype = self.type
  end

  self.marked = false
  self.cache = {}

  self.config.init(self)
  return self
end

function Node:update_cache()
  self.cache.time = vim.fn.getftime(self.path)
  self.cache.tail = vim.fn.fnamemodify(self.name, ":e")
end

-- return: Boolean
function Node:is_hidden()
  return vim.startswith(self.name, ".")
end

return Node
