local Node = require("filetree.node")
local Tree = Node:inherit()

local Help = require("filetree.help")

---@param conf  table with options {option = value, ...}. |filetree-config|
---@returns Tree metatable
function Tree:new(conf, name, path, parent, depth, type)
  local self = setmetatable(Node:new(conf, name, path, parent, depth, type), { __index = Tree })
  self.children = {}
  self.loaded = false
  self.expanded = false
  return self
end

function Tree:expand()
  if (self.loaded) then
    --local new_time = vim.fn.getftime(self.path)
    --if (new_time > self.cache.time) then
    --  self:reload()
    --end
  else
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
  self.children = {}

  local dir, err, err_name = vim.loop.fs_opendir(self.path, nil, 4000)
  if (err ~= nil) then
    print("failed to open directory:", err)
    return err_name
  end

  local files, err, err_name = vim.loop.fs_readdir(dir)
  if (err ~= nil) then
    print("failed to read directory:", err)
    return err_name
  end

  vim.loop.fs_closedir(dir)

  if (files ~= nil) then
    for i, file in ipairs(files) do
      local path = Help:make_path(self.path, file.name)
      if (not(file.name == ".") and not(file.name == "..")) then
        table.insert(self.children, self:create_node(file.name, path, file.type))
      end
    end
  end

  self:sort()
  self.loaded = true
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
  local node = self:create_node(Help:get_file_name(path), path, Help:get_file_type(path))
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

---@param name  file name
---@param path  file path
---@param type  file type
---@returns Tree metatable if type is directory or link pointing to a directory, else Node metatable
function Tree:create_node(name, path, type)
  if (type == "directory") then
    return Tree:new(self.config, name, path, self, self.depth + 1, type)
  elseif (type == "link" and Help:get_file_type(vim.fn.resolve(path)) == "directory") then
    return Tree:new(self.config, name, path, self, self.depth + 1, type)
  end
  return Node:new(self.config, name, path, self, self.depth + 1, type)
end

return Tree
