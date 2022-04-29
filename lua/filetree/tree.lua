local Node = require("filetree.node")
local Tree = Node:inherit()

local Help = require("filetree.help")

---@param name    file name
---@param path    file path
---@param parent  Tree metatable with path of file parent
---@param depth   directory level
---@param type    file type
---@returns Tree metatable
function Tree:new(name, path, parent, depth, type)
  local self = setmetatable(Node:new(name, path, parent, depth, type), { __index = Tree })
  self.children = {}
  self.loaded = false
  self.expanded = false
  return self
end

function Tree:expand()
  if (not self.loaded) then
    self:reload()
  else
    self:soft_reload_recursive()
  end
  self.expanded = true
  self.changed = true
end

---@param recursive  close children if true
function Tree:close(recursive)
  if (recursive) then
    self:close_recursive()
  else
    self.expanded = false
  end
  self.changed = true
end

function Tree:close_recursive()
  self.expanded = false
  self.changed = true
  for i, node in ipairs(self.children) do
    if (node.rtype == "directory") then
      node:close_recursive()
    end
  end
end

function Tree:reload()
  self.children = Help:read_directory(self.rpath)

  if (self.children ~= nil) then
    for i, file in ipairs(self.children) do
      local path = Help:make_path(self.path, file.name)
      if (not(file.name == ".") and not(file.name == "..")) then
	if (file.type == "directory" or (file.type == "link" and Help:get_file_type(vim.fn.resolve(path)) == "directory")) then
	  self.children[i] = Tree:new(file.name, path, self, self.depth + 1, file.type)
	else
	  self.children[i] = Node:new(file.name, path, self, self.depth + 1, file.type)
	end
      end
    end

    self:sort()
  else
    self.children = {}
  end

  self.time = vim.fn.getftime(self.rpath)
  self.loaded = true
  self.changed = true
  return true
end

function Tree:soft_reload()
  local files = Help:read_directory(self.rpath)
  local new_files = {}

  -- check for new files
  for i, file in ipairs(files) do
    local node = self:find_node_by_name(file.name)
    if (node == nil) then
      self:add_node_by_name(file.name, file.type)
    end
  end

  -- check for deleted files
  for i1, node in ipairs(self.children) do
    local file = nil
    for i2, item in ipairs(files) do
      if (item.name == node.name) then
	file = item
      end
    end

    if (file == nil) then
      self:remove_node_by_name(file.name)
    end
  end

  self:sort()
end

function Tree:soft_reload_recursive()
  if (not self.loaded) then return end

  if (self:should_reload()) then
    self:soft_reload()
  end

  for i, node in ipairs(self.children) do
    if (node.expanded) then
      node:soft_reload_recursive(changed)
    end
  end
end

function Tree:sort()
  -- TODO: config
  table.sort(self.children, function(a, b)
    if (a.rtype == "directory" and not(b.rtype == "directory")) then
      return true
    elseif (b.rtype == "directory" and not(a.rtype == "directory")) then
      return false
    end
    return (string.upper(a.name) < string.upper(b.name))
  end)
  self.changed = true
end

---@param node  add Node metatable to children
function Tree:add_node(node)
  table.insert(self.children, node)
  self.changed = true
end

---@param path  file path
---@returns added Node metatable
function Tree:add_node_by_path(path, type)
  local node = self:create_node(Help:get_file_name(path), path, (type or Help:get_file_type(path)))
  table.insert(self.children, node)
  self.changed = true
  return node
end

---@param name  file name
---@returns added Node metatable
function Tree:add_node_by_name(name, type)
  local node = self:create_node(name, Help:make_path(self.path, name), (type or Help:get_file_type(path)))
  table.insert(self.children, node)
  self.changed = true
  return node
end

---@param node  remove Node metatable from children
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
  self.changed = true
end

---@param path  file path
function Tree:remove_node_by_path(path)
  local index = 0
  for i, child in ipairs(self.children) do
    if (child.path == path) then
      index = i
      break
    end
  end

  if (not(index == 0)) then
    table.remove(self.children, index)
  end
  self.changed = true
end

---@param name  file name
function Tree:remove_node_by_name(name)
  local index = 0
  for i, child in ipairs(self.children) do
    if (child.name == name) then
      index = i
      break
    end
  end

  if (not(index == 0)) then
    table.remove(self.children, index)
  end
  self.changed = true
end

function Tree:create_node(name, path, type)
  if (type == "directory" or (type == "link" and Help:get_file_type(vim.fn.resolve(path)) == "directory")) then
    return Tree:new(name, path, self, self.depth + 1, type)
  end
  return Node:new(name, path, self, self.depth + 1, type)
end

---@param path  file path
---@returns Node metatable
function Tree:find_node_by_path(path)
  for i, child in ipairs(self.children) do
    if (child.path == path) then
      return child
    end
  end
end

---@param path  file name
---@returns Node metatable
function Tree:find_node_by_name(name)
  for i, child in ipairs(self.children) do
    if (child.name == name) then
      return child
    end
  end
end


---@returns true if changes where made in file system
function Tree:should_reload()
  if (self.loaded == false) then
    return true
  end

  return vim.fn.getftime(self.rpath) > self.time
end

return Tree
