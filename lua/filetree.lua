local FileTree = {}

local Config = require("filetree.config")
local View = require("filetree.view")
local Mapping = require("filetree.mapping")
local Tree = require("filetree.tree")
local Help = require("filetree.help")
local TempView = require("filetree.temp_view")

FileTree.View = View
FileTree.Mapping = Mapping

---@param conf  table with options {option = value, ...}. |filetree-config|
---@returns FileTree metatable
function FileTree:new(conf)
  local self = setmetatable({}, { __index = FileTree })
  self.config = (conf or {})
  self.extensions = {}

  self:setup_config()
  self:setup_highlight()

  self.view = View:new(self.config.view)
  self.view:setup_buffer()

  self.mapping = Mapping:new(self, self.config.mapping)
  self.mapping:setup_autocmds()
  self.mapping:setup_keymaps()

  vim.cmd("command FTreeOpen lua _G.filetree:open()")
  vim.cmd("command FTreeClose lua _G.filetree:close()")
  return self
end

function FileTree:destroy()
  self.mapping:destroy()
  self.view:destroy()
end

function FileTree:setup_config()
  self.config_handler = Config:new(self.config)
  self.config_handler:setup()
  self.config_handler:validate()
  self:set_directory(self.config.directory)
end

function FileTree:setup_highlight()
  local prefix = "filetree_"
  for key, hl in pairs(self.config.highlight) do
    local opts = ""

    if (hl.cterm) then opts = opts.." cterm="..hl.cterm end
    if (hl.ctermfg) then opts = opts.." ctermfg="..hl.ctermfg end
    if (hl.ctermbg) then opts = opts.." ctermbg="..hl.ctermbg end

    if (opts ~= "") then
      vim.cmd("hi "..prefix..key..opts)
    end
  end
end

function FileTree:load_tree()
  local file_name = Help:get_file_name(self.config.directory)
  local file_type = Help:get_file_type(self.config.directory)

  local conf = {
    read_directory_fn = function(path) return self:read_directory(path) end,
    sort_nodes_fn = function(nodes) return self:sort_nodes(nodes) end
  }
  local tree = Tree:new(conf, file_name, self.config.directory, nil, 0, file_type)
  return self:set_root(tree)
end

function FileTree:set_parent_as_root()
  local parent = Help:get_file_parent(self.tree.path)
  if (parent == self.tree.path) then
    return false
  end

  self:set_directory(parent)
  return self:load_tree()
end

function FileTree:open()
  self:load_tree()
  if (not self.view:is_active()) then
    self.view:open_window()
  end
end

function FileTree:close()
  self.view:close_window()
end

---@param node  node to open in a info window
function FileTree:open_file_info_view(node)
  local conf = self.config.file_info_view

  local lines = {}
  local hls = {}
  for i, info in ipairs(conf.content) do
    if (info.callback ~= nil) then
      info.callback(lines, hls, node)
    else
      local head = ""
      if (type(info.prefix) == "boolean" and info.prefix) then head = info.key..": "
      elseif (type(info.prefix) == "string") then head = info.prefix..": "
      elseif (type(info.prefix) == "table") then
        head = info.prefix.text..": "
        table.insert(hls, {
          ns_id = (info.prefix.hlns or 0),
          hl_group = (info.prefix.hlg or ""),
          line = #lines,
          col_start = 0,
          col_end = #info.prefix.text
        })
      end

      local value = ""
      if (info.key == "name") then
        value = ((info.resolved and node.rname) or node.name)
      elseif (info.key == "path") then
        value = ((info.resolved and node.rpath) or node.path)
      elseif (info.key == "type") then
        local type = ((info.resolved and node.rtype) or node.type)
        if (info.list ~= nil) then
          if (info[type] ~= nil) then type = info[type] end
        end
        value = type
      elseif (info.key == "size") then
        local size = ((info.resolved and vim.fn.getfsize(node.rpath)) or vim.fn.getfsize(node.path))
        local prefix, size = Help:get_prefixed_size(size)
        value = string.format(info.fmt, size, prefix)
      elseif (info.key == "perm") then
        local perm = ((info.resolved and vim.fn.getfperm(node.rpath)) or vim.fn.getfperm(node.path))
        value = perm
      elseif (info.key == "created") then
        value = "idk"
      elseif (info.key == "modified") then
        local time = ((info.resolved and vim.fn.getftime(node.rpath)) or vim.fn.getftime(node.path))
        value = ((info.fmt and vim.fn.strftime(info.fmt, time)) or time)
      elseif (info.key == "readable") then
        local rd = ((info.resolved and vim.fn.filereadable(node.rpath)) or vim.fn.filereadable(node.path))
        value = ((rd and "true") or "false")
      elseif (info.key == "writable") then
        local wr = ((info.resolved and vim.fn.filewritable(node.rpath)) or vim.fn.filewritable(node.path))
        value = ((wr and "true") or "false")
      elseif (info.key == "link" and node.type == "link") then
        value = "maybe"
      end

      if (info.hlns ~= nil and info.hlg) then
        table.insert(hls, {
          ns_id = info.hlns,
          hl_group = info.hlg,
          line = #lines,
          col_start = #head,
          col_end = -1
        })
      end

      table.insert(lines, head..value)
    end
  end

  if (#lines == 0) then
    return
  end

  local width = 1
  for i, line in ipairs(lines) do
    width = math.max(width, #line)
  end

  local view_conf = {
    quit_on_esc = true,
    type = "float",
    relative = "cursor",
    absolute = true,
    width = width,
    height = #lines,
    row = 1,
    col = 0,
    border = "none",
    number = false,
    relativenumber = false,
    enter = true
  }
  local info_view = TempView:new(view_conf)
  info_view:setup_buffer(lines, hls)
  info_view:open_window()
  info_view:setup_autocmds()
  info_view:setup_keymaps()
end


---@param file  file to open in a preview window
function FileTree:open_file_preview(file)
  local conf = self.config.file_preview

  if (Help:get_file_type(file) == "directory") then
    return
  end

  local view_conf = {
    quit_on_esc = conf.quit_on_esc,
    type = conf.type,
    relative = conf.relative,
    absolute = conf.absolute,
    width = conf.width,
    height = conf.height,
    row = conf.row,
    col = conf.col,
    border = conf.border,
    number = conf.number,
    relativenumber = conf.relativenumber,
    enter = true
  }
  local preview = TempView:new(view_conf)
  local lines = self:read_file(file)
  preview:setup_buffer(lines)
  preview:open_window()
  preview:setup_autocmds()
  preview:setup_keymaps()
end

---@param nodes  list of nodes to sort
function FileTree:sort_nodes(nodes)
  local conf = self.config.actions.sort_nodes
  if (conf.callback ~= nil and conf.callback(nodes)) then
    return
  end

  -- TODO: more methods
  local sort_method_name = function(a, b) return string.upper(a.name) < string.upper(b.name) end
  local sort_method_name_cs = function(a, b) return a.name < b.name end
  local sort_method_type = function(a, b) return a.type < b.type end
  local sort_method_rtype = function(a, b) return a.rtype < b.rtype end
  local sort_method = function(a, b)
    if (conf.method == "name") then return sort_method_name(a, b)
    elseif (conf.method == "name_cs") then return sort_method_name_cs(a, b)
    elseif (conf.method == "type") then return sort_method_type(a, b)
    elseif (conf.method == "rtype") then return sort_method_rtype(a, b) end
    return false
  end

  local sort_dirs_top = function(a, b)
    if (a.rtype == "directory" and b.rtype ~= "directory") then
      return true
    elseif (b.rtype == "directory" and a.rtype ~= "directory") then
      return false
    end
    return sort_method(a, b)
  end
  local sort_dirs_bottom = function(a, b)
    if (a.rtype == "directory" and b.rtype ~= "directory") then
      return false
    elseif (b.rtype == "directory" and a.rtype ~= "directory") then
      return true
    end
    return sort_method(a, b)
  end

  if (conf.directories == "top") then
    table.sort(nodes, sort_dirs_top)
  elseif (conf.directories == "bottom") then
    table.sort(nodes, sort_dirs_bottom)
  else
    table.sort(nodes, sort_method)
  end

  if (conf.reverse) then
    vim.fn.reverse(nodes)
  end
end

---@param tree  Tree metatable
---@returns true if root was changed
---@private
function FileTree:set_root(tree)
  if (not tree:reload()) then
    return false
  end

  local conf = self.config.actions.root_changed

  if (conf.change_cwd) then
    vim.api.nvim_set_current_dir(tree.path)
  end

  self.tree = tree
  self.view:set_tree(self.tree)

  if (conf.callback ~= nil) then
    conf.callback(tree)
  end
  return true
end

---@param file  file to open
function FileTree:open_file(file)
  if (self.config.actions.open_file.callback ~= nil) then
    return self.config.actions.open_file.callback(file)
  end

  self:win_picker_open_file(file)
  if (self.config.actions.open_file.quit_tree) then
    self:close()
  end
end

---@param file  file to open in editor
function FileTree:win_picker_open_file(file)
  local conf = self.config.actions.open_file.window_picker

  local wins = vim.api.nvim_list_wins()
  local suitable = {}
  if (not conf.exclude.self) then
    table.insert(suitable, self.view.win)
  end
  for i, win in ipairs(wins) do
    if (win ~= self.view.win) then
      if (#suitable >= #conf.ids) then
	break
      end

      local continue = true

      -- check suitable callback
      if (conf.suitable_callback ~= nil) then
	continue = conf.suitable_callback(win)
      end

      local buf = vim.api.nvim_win_get_buf(win)
      local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
      local bufname = vim.api.nvim_buf_get_name(buf)

      -- check exclude buftypes
      for _, bt in ipairs(conf.exclude.buftypes) do
	if (bt == buftype) then
	  continue = false
	  break
	end
      end

      -- check exclude bufnames
      for _, bn in ipairs(conf.exclude.bufnames) do
	if (bn == bufname) then
	  continue = false
	  break
	end
      end

      if (continue) then
	table.insert(suitable, win)
      end
    end
  end

  if (#suitable > 1) then
    local ids = {}
    for i = 1, #conf.ids, 1 do
      table.insert(ids, string.sub(conf.ids, i, i))
    end

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
---@returns list of lines
function FileTree:read_file(file)
  local conf = self.config.actions.read_file
  if (conf.callback ~= nil) then
    local rv = conf.callback(file)
    if (rv) then return rv end
  end
  return vim.fn.readfile(file)
end

---@param path  directory path
---@returns list of files
function FileTree:read_directory(path)
  local conf = self.config.actions.read_directory

  local files = nil
  if (conf.callback ~= nil) then
    files = conf.callback(path)
  end

  if (files == nil) then
    local dir, err, err_name = vim.loop.fs_opendir(path, nil, 4000)
    if (err ~= nil) then
      print("failed to open directory:", err)
      return nil
    end

    files, err, err_name = vim.loop.fs_readdir(dir)
    if (err ~= nil) then
      print("failed to read directory:", err)
      return nil
    end
    vim.loop.fs_closedir(dir)
  end

  local exclude = self.config.filters.exclude
  if (exclude.dot_files) then
    vim.tbl_filter(function(file)
      return not vim.startswith(file, ".")
    end, files)
  end

  if (exclude.pattern) then
    vim.tbl_filter(function(file)
      return exclude.pattern:match_str(file) == nil
    end, files)
  end

  return files
end

---@param file  file path
function FileTree:make_file(file)
  local conf = self.config.actions.make_file
  if (conf.callback ~= nil and conf.callback(file)) then
    return
  end
  vim.fn.writefile({}, file, "b")
end

---@param path  directory path
function FileTree:make_directory(path)
  local conf = self.config.actions.make_directory
  if (conf.callback ~= nil and conf.callback(path)) then
    return
  end
  vim.fn.mkdir(path)
end

---@param file  file to copy
---@param dest  destination path
-- TODO: better copy
function FileTree:copy_file(file, dest)
  local conf = self.config.actions.copy_file
  if (conf.callback ~= nil and conf.callback(file)) then
    return
  end
  local content = vim.fn.readfile(file, "b")
  vim.fn.writefile(content, dest, "b")
end

---@param file  file to move
---@param path  new path name
function FileTree:move_file(file, path)
  local conf = self.config.actions.move_file
  if (conf.callback ~= nil and conf.callback(file)) then
    return
  end
  vim.fn.rename(file, path)
end

---@param file  file to remove
function FileTree:remove_file(file)
  local conf = self.config.actions.remove_file
  if (conf.callback ~= nil and conf.callback(file)) then
    return
  end
  vim.fn.delete(file, "rf")
end

function FileTree:load_extension(extension)
  table.insert(self.extensions, extension)
  extension:setup_highlight()
  extension:setup_config()
  extension:setup_autocmds()
  extension:setup_keymaps()
  extension:init(self)
end

---@param name  extension name
---@param conf  table with options {option = value, ...}. |filetree-config|
function FileTree:enable_extension(name, conf)
  if (name == "icons") then
    local ExtIcons = require("filetree.extensions.icons")
    local icons = ExtIcons:new(conf)
    self:load_extension(icons)
  end
end

function FileTree:enable_integration(name, conf)
  if (name == "statline") then
    local ExtStatline = require("filetree.integrations.statline")
    local statline = ExtStatline:new(self, conf)
    _G.statline:load_extension(statline)
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
