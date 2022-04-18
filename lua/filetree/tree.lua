local Node = require("filetree.node")
local Tree = Node:inherit()

local Help = require("filetree.help")

-- params: {conf: Table, path: String, parent: Tree, depth: Number, name: String, type: String}
-- return: Tree
function Tree:new(conf, path, parent, depth, name, type)
  local self = setmetatable(Node:new(conf, path, parent, depth, name, type), { __index = Tree })
  self.children = {}
  self.loaded = false
  self.expanded = false
  return self
end

function Tree:expand()
  if (self.loaded) then
    local new_time = vim.fn.getftime(self.path)
    if (new_time > self.cache.time) then
      self:reload()
    end
  else
    self:reload()
  end
  self.expanded = true
end

-- params: {recursive: Boolean}
function Tree:close(recursive)
  if (recursive) then
    self:close_recursive()
  else
    self.expanded = false
  end
end

function Tree:close_recursive()
  self.expanded = false
  for i, node in ipairs(self.children) do
    if (node.rtype == "dir") then
      node:close_recursive()
    end
  end
end

function Tree:reload()
  self.children = {}
  local files = vim.fn.glob(self.path.."/*", false, true)
  local hidden_files = vim.fn.glob(self.path.."/.*", false, true)
  vim.list_extend(files, hidden_files)
  self:load_files(files)
  self:sort()
end

function Tree:sort()
  -- TODO: config
  table.sort(self.children, function(a, b)
    if (a.rtype == "dir" and not(b.rtype == "dir")) then
      return true
    elseif (b.rtype == "dir" and not(a.rtype == "dir")) then
      return false
    end
    return (string.upper(a.name) < string.upper(b.name))
  end)
end

-- params: {files: Table{String ...}}
function Tree:load_files(files)
  for i, path in ipairs(files) do
    local name = Help:get_file_name(path)
    if (not(name == ".") and not(name == "..")) then
      table.insert(self.children, self:create_node(path, name, vim.fn.getftype(path)))
    end
  end
  self.loaded = true
end

-- params: {node: Node}
function Tree:add_node(node)
  table.insert(self.children, node)
end

-- params: {path: String}
function Tree:add_file(path)
  table.insert(self.children, self:create_node(path, Help:get_file_name(path), vim.fn.getftype(path)))
end

-- params: {node: Node}
function Tree:remove_node(node)
  local index = 0
  for i, child in ipairs(self.children) do
    if (child == node) then
      index = i
      break
    end
  end

  if (not(index == 0)) then
    table.remove(self.children, index)
  end
end

-- params: {path: String, name: String, type: String}
-- return: Node
function Tree:create_node(path, name, type)
  if (type == "dir") then
    return Tree:new(self.config, path, self, self.depth + 1, name, type)
  elseif (type == "link" and vim.fn.getftype(vim.fn.resolve(path)) == "dir") then
    return Tree:new(self.config, path, self, self.depth + 1, name, type)
  end
  return Node:new(self.config, path, self, self.depth + 1, name, type)
end

return Tree
