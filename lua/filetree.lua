local FileTree = {}

local View = require("filetree.view")
local Mapping = require("filetree.mapping")
local Tree = require("filetree.tree")
local Help = require("filetree.help")

FileTree.View = View
FileTree.Mapping = Mapping

---@param conf  table with options {option = value, ...}. |filetree-config|
---@returns FileTree metatable
function FileTree:new(conf)
  local self = setmetatable({}, { __index = FileTree })
  self.config = (conf or {})
  self.view = View:new(self.config.view)
  self.mapping = Mapping:new(self, self.config.mapping)
  self.extensions = {}
  self.ignore_files = {}

  self:setup_config()

  self.view:setup_highlight()
  self.view:setup_config()
  self.view:setup_buffer()

  self.mapping:setup_config()
  self.mapping:setup_mappings()
  self.mapping:setup_autocmds()
  self.mapping:setup_keymaps()

  if (not(conf.extensions == nil)) then
    for i, ext in ipairs(conf.extensions) do
      if (type(ext) == "table") then
	self:enable_extension(ext.name, ext.conf)
      else
	self:enable_extension(ext, {})
      end
    end
  end
  self:load_extensions()
  self:load_tree()
  return self
end

function FileTree:setup_config()
  local conf = self.config
  conf.directory = (conf.directory or vim.fn.getcwd())
end

function FileTree:load_tree()
  local file_name = Help:get_file_name(self.config.directory)
  local file_type = Help:get_file_type(self.config.directory)

  local tree = Tree:new(file_name, self.config.directory, nil, 0, file_type)
  return self:set_root(tree)
end

---@param tree  Tree metatable
---@returns true if root was changed
---@private
function FileTree:set_root(tree)
  if (not tree:reload()) then
    return false
  end

  self.tree = tree
  self.view:set_tree(self.tree)
  return true
end

function FileTree:set_parent_as_root()
  local parent = Help:get_file_parent(self.tree.path)
  if (parent == self.tree.path) then
    return false
  end

  self:set_directory(parent)
  return self:load_tree()
end

---@param file  file to open in editor
function FileTree:open_file(file)
  if (not(self.config.file_callback == nil)) then
    self.config.file_callback(file)
    return
  end

  local wins = vim.api.nvim_list_wins()
  for i, win in ipairs(wins) do
    if (not(win == self.view.win)) then
      vim.api.nvim_set_current_win(win)
      break
    end
  end

  vim.api.nvim_command("edit "..file)
end

---@param file  file path
function FileTree:make_file(file)
  if (self.config.node.event_callback ~= nil) then
    table.insert(self.ignore_files, file)
  end
  vim.fn.writefile({}, file, "b")
end

---@param file  file path
function FileTree:make_directory(file)
  if (self.config.node.event_callback ~= nil) then
    table.insert(self.ignore_files, file)
  end
  vim.fn.mkdir(file)
end

---@param file  file to copy
---@param dest  destination path
-- TODO: better copy
function FileTree:copy_file(file, dest)
  if (self.config.node.event_callback ~= nil) then
    table.insert(self.ignore_files, dest)
  end
  local content = vim.fn.readfile(file, "b")
  vim.fn.writefile(content, dest, "b")
end

---@param file  file to move
---@param path  new path name
function FileTree:move_file(file, path)
  if (self.config.node.event_callback ~= nil) then
    table.insert(self.ignore_files, file)
    table.insert(self.ignore_files, path)
  end
  vim.fn.rename(file, path)
end

---@param file  file to remove
function FileTree:remove_file(file)
  if (self.config.node.event_callback ~= nil) then
    table.insert(self.ignore_files, file)
  end
  vim.fn.delete(file, "rf")
end

function FileTree:load_extensions()
  for i, ext in ipairs(self.extensions) do
    ext:setup_highlight()
    ext:setup_config()
    ext:setup_autocmds()
    ext:setup_keymaps()
    ext:init(self)
  end
end

---@param name  extension name
---@param conf  table with options {option = value, ...}. |filetree-config|
function FileTree:enable_extension(name, conf)
  if (name == "icons") then
    local ExtIcons = require("filetree.extensions.icons")
    local icons = ExtIcons:new(conf)
    table.insert(self.extensions, icons)
  elseif (name == "statline") then
    local ExtStatline = require("filetree.extensions.statline")
    local statline = ExtStatline:new(conf)
    table.insert(self.extensions, statline)
  end
end


-- ### Getters and setters ### ---

---@returns path to root tree
function FileTree:get_directory()
  return self.config.directory
end

---@param path  new root directory path
function FileTree:set_directory(path)
  self.config.directory = path
  vim.cmd("augroup filetree | doautocmd User dir_changed | augroup END")
end

---@returns status line text
function FileTree:get_status_line()
  if (self.tree == nil) then
    return ""
  end
  return self.tree.path
end

---@param conf  table with options {option = value, ...}. |filetree-config|
function FileTree:setup(conf)
  _G.filetree = FileTree:new(conf)
end

return FileTree
