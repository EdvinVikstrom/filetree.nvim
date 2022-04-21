local Node = require("filetree.node")
local Tree = Node:inherit()

local Help = require("filetree.help")

---@param conf  table with options {option = value, ...}. |filetree-config|
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
  end
  self.expanded = true
end

---@param recursive  close children if true
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
  end

  self:sort()
  self.loaded = true
  return true
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
end

---@param node  add Node metatable to children
function Tree:add_node(node)
  table.insert(self.children, node)
end

---@param node  add Node metatable with path to children
function Tree:add_file(path)
  local node = Node:new(Help:get_file_name(path), path, self, self.depth + 1, Help:get_file_type(path))
  table.insert(self.children, node)
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

return Tree
