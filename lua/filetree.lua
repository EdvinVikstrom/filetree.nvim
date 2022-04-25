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
  conf.namespace = (conf.namespace or vim.api.nvim_create_namespace("filetree"))
  conf.win_ids = (conf.win_ids or {"a", "o", "e", "u", "h", "t", "n", "s"})
  self:set_directory(conf.directory or vim.fn.getcwd())
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
  local suitable = {}
  for i, win in ipairs(wins) do
    if (win ~= self.view.win) then
      if (#suitable >= #self.config.win_ids) then
	break
      end
      table.insert(suitable, win)
    end
  end

  if (#suitable > 1) then
    local ids = self.config.win_ids

    for i, win in ipairs(suitable) do
      local sl = vim.api.nvim_win_get_option(win, "statusline")
      vim.api.nvim_win_set_option(win, "statusline", "%=["..ids[i].."]%=")
      suitable[i] = {win = win, sl = sl}
    end

    local index = 0
    while (index == 0) do
      local input = Help:get_user_input("Pick window")
      for i, id in ipairs(ids) do
	if (vim.stricmp(id, input) == 0) then
	  index = i
	  break
	end
      end
    end

    for i, item in ipairs(suitable) do
      vim.api.nvim_win_set_option(item.win, "statusline", item.sl)
    end

    vim.api.nvim_set_current_win(suitable[index].win)
    vim.cmd("edit "..file)
  elseif (#suitable == 0) then
    vim.cmd("edit "..file)
  else
    vim.api.nvim_set_current_win(suitable[1])
    vim.cmd("edit "..file)
  end
end

---@param file  file path
function FileTree:make_file(file)
  vim.fn.writefile({}, file, "b")
end

---@param file  file path
function FileTree:make_directory(file)
  vim.fn.mkdir(file)
end

---@param file  file to copy
---@param dest  destination path
-- TODO: better copy
function FileTree:copy_file(file, dest)
  local content = vim.fn.readfile(file, "b")
  vim.fn.writefile(content, dest, "b")
end

---@param file  file to move
---@param path  new path name
function FileTree:move_file(file, path)
  vim.fn.rename(file, path)
end

---@param file  file to remove
function FileTree:remove_file(file)
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

---@returns home relative path to root tree
function FileTree:get_rel_directory()
  return self.config.rel_directory
end

---@param path  new root directory path
function FileTree:set_directory(path)
  self.config.directory = path
  self.config.rel_directory = vim.fn.fnamemodify(path, ":p:~")
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
