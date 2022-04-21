local Node = require("filetree.node")
local Tree = Node:inherit()

local Help = require("filetree.help")

---@param name  file name
---@param path  file path
---@param parent  Tree metatable with path of file parent
---@param depth  directory level
---@param type  file type
---@returns Tree metatable
function Tree:new(name, path, parent, depth, type)
  local self = setmetatable(Node:new(name, path, parent, depth, type), { __index = Tree })
  self.children = {}
  self.loaded = false
  self.expanded = false
  return self
end

function Tree:expand()
  self:reload_recursive()
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
  for i, node in ipairs(self.children) do
    if (node.rtype == "directory") then
      node:close_recursive()
    end
  end
end

function Tree:reload()
  local dir, err, err_name = vim.loop.fs_opendir(self.path, nil, 4000)
  if (err ~= nil) then
    print("failed to open directory:", err)
    return false
  end

  self.children, err, err_name = vim.loop.fs_readdir(dir)
  if (err ~= nil) then
    print("failed to read directory:", err)
    return false
  end

  vim.loop.fs_closedir(dir)

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

function Tree:reload_recursive()
  if (self:should_reload()) then
    self:reload()
  end

  for i, node in ipairs(self.children) do
    if (node.expanded) then
      node:reload_recursive(changed)
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

---@param node  add Node metatable with path to children
function Tree:add_file(path)
  local node = Node:new(Help:get_file_name(path), path, self, self.depth + 1, Help:get_file_type(path))
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
---@returns Node metatable
function Tree:find_node(path)
  for i, child in ipairs(self.children) do
    if (child.path == path) then
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
