local Mapping = {}

local Help = require("filetree.help")

---@param filetree  FileTree metatable
---@param conf      table with options {option = value, ...}. |filetree-config|
---@returns Mapping metatable
function Mapping:new(filetree, conf)
  local self = setmetatable({}, { __index = Mapping })
  self.filetree = filetree
  self.config = conf
  return self
end

function Mapping:destroy()
  if (self.keymaps ~= nil) then
    for i, map in ipairs(self.keymaps) do
      vim.keymap.del(map.modes, map.lhs, {buffer = map.opts.buffer})
    end
  end

  if (self.autocmds ~= nil) then
    for i, cmd in ipairs(self.autocmds) do
      vim.api.nvim_del_autocmd(cmd.id)
    end
  end
end

function Mapping:setup_autocmds()
  self.autocmds = {
    { event = "VimEnter", callback = function(info) self:autocmd_vim_enter(info) end },
    { event = "VimLeave", callback = function(info) self:autocmd_vim_leave(info) end },
    { event = "VimResized", callback = function(info) self:autocmd_vim_resized(info) end },
    { event = "WinEnter", callback = function(info) self:autocmd_win_enter(info) end },
    { event = "WinScrolled", callback = function(info) self:autocmd_win_scrolled(info) end },
    { event = "BufWinEnter", callback = function(info) self:autocmd_buf_win_enter(info) end },
    { event = "WinClosed", callback = function(info) self:autocmd_win_closed(info) end },
    { event = "User", pattern = "dir_changed", callback = function(info) self:autocmd_user_dir_changed(info) end }
  }

  self.augroup = vim.api.nvim_create_augroup("filetree", { clear = true })
  for i, cmd in ipairs(self.autocmds) do
    local opts = {
      group = self.augroup,
      pattern = cmd.pattern,
      callback = cmd.callback
    }
    cmd.id = vim.api.nvim_create_autocmd(cmd.event, opts)
  end
end

function Mapping:setup_keymaps()
  self.keymaps = {}
  for key, map in pairs(self.config.keymaps) do
    local opts = {
      buffer = self.filetree.view.buf,
      silent = true
    }
    vim.keymap.set("n", key, function() map(self) end, opts)
    table.insert(self.keymaps, {modes = "n", lhs = key, opts = opts})
  end
end


-- ### Autocmd callback ### --

function Mapping:autocmd_vim_enter()
end

function Mapping:autocmd_vim_leave()
end

function Mapping:autocmd_vim_resized()
  self.filetree.view:force_redraw()
end

function Mapping:autocmd_win_enter(info)
  local win = vim.api.nvim_get_current_win()
  if (not(self.filetree.view:is_active()) or win ~= self.filetree.view.win) then return end
  if (self.filetree.view:is_active()) then
    self.filetree.tree:soft_reload_recursive()
    self.filetree.view:redraw()
  end
end

function Mapping:autocmd_win_scrolled(info)
  local win = vim.api.nvim_get_current_win()
  if (not(self.filetree.view:is_active()) or win ~= self.filetree.view.win) then return end
  if (self.filetree.view:should_redraw()) then
    self.filetree.view:force_redraw()
  end
end

function Mapping:autocmd_buf_win_enter(info)
  local win = vim.api.nvim_get_current_win()
  if (not(self.filetree.view:is_active()) or win ~= self.filetree.view.win) then return end
  vim.api.nvim_win_set_buf(self.filetree.view.win, self.filetree.view.buf)
end

function Mapping:autocmd_win_closed(info)
  if (not(self.filetree.view:is_active()) or info.match ~= ""..self.filetree.view.win) then return end
  self.filetree.view.win = nil
end

function Mapping:autocmd_user_dir_changed()
end


-- ### Keymap callback ### --

function Mapping:cursor_down() return function(self) self:keymap_cursor_down() end end
function Mapping:cursor_up() return function(self) self:keymap_cursor_up() end end
function Mapping:open() return function(self) self:keymap_open() end end
function Mapping:close() return function(self) self:keymap_close() end end
function Mapping:enter() return function(self) self:keymap_enter() end end
function Mapping:mark(reverse) return function(self) self:keymap_mark(reverse) end end
function Mapping:make_file() return function(self) self:keymap_make_file() end end
function Mapping:make_directory() return function(self) self:keymap_make_directory() end end
function Mapping:rename(what) return function(self) self:keymap_rename(what) end end
function Mapping:copy() return function(self) self:keymap_copy() end end
function Mapping:move() return function(self) self:keymap_move() end end
function Mapping:remove() return function(self) self:keymap_remove() end end
function Mapping:yank() return function(self) self:keymap_yank() end end
function Mapping:paste() return function(self) self:keymap_paste() end end
function Mapping:pack(remove_files) return function(self) self:keymap_pack(remove_files) end end
function Mapping:compress(remove_file) return function(self) self:keymap_compress(remove_file) end end
function Mapping:info() return function(self) self:keymap_info() end end
function Mapping:preview() return function(self) self:keymap_preview() end end
function Mapping:toggle_hidden() return function(self) self:keymap_toggle_hidden() end end
function Mapping:redraw() return function(self) self:keymap_redraw() end end
function Mapping:reload() return function(self) self:keymap_reload() end end
function Mapping:clear() return function(self) self:keymap_clear() end end

Mapping.default_keymaps = {
  ["j"] = Mapping:cursor_down(),
  ["k"] = Mapping:cursor_up(),
  ["l"] = Mapping:open(),
  ["h"] = Mapping:close(),
  ["<Enter>"] = Mapping:enter(),
  ["w"] = Mapping:mark(false),
  ["W"] = Mapping:mark(true),
  ["N"] = Mapping:make_file(),
  ["K"] = Mapping:make_directory(),
  ["r"] = Mapping:rename(),
  ["R"] = Mapping:rename("name"),
  ["e"] = Mapping:rename("ext"),
  ["c"] = Mapping:copy(),
  ["m"] = Mapping:move(),
  ["x"] = Mapping:remove(),
  ["y"] = Mapping:yank(),
  ["p"] = Mapping:paste(),
  ["P"] = Mapping:pack(false),
  ["C"] = Mapping:compress(false),
  ["i"] = Mapping:info(),
  ["v"] = Mapping:preview(),
  ["."] = Mapping:toggle_hidden(),
  [","] = Mapping:redraw(),
  [";"] = Mapping:reload(),
  ["<Esc>"] = Mapping:clear()
}

function Mapping:keymap_cursor_down()
  local cursor = self.filetree.view:get_cursor()
  local count = self.filetree.view:get_node_count()

  if (cursor == count) then
    if (self.config.wrap_cursor) then
      self.filetree.view:set_cursor(1)
    end
  else
    self.filetree.view:set_cursor(cursor + 1)
  end
end

function Mapping:keymap_cursor_up()
  local cursor = self.filetree.view:get_cursor()
  local count = self.filetree.view:get_node_count()

  if (cursor == 1) then
    if (self.config.wrap_cursor) then
      self.filetree.view:set_cursor(count)
    end
  else
    self.filetree.view:set_cursor(cursor - 1)
  end
end

function Mapping:keymap_open()
  local selected = self.filetree.view:get_selected()
  if (selected == nil) then
    return
  end

  if (selected.rtype == "directory") then
    if (selected.expanded) then
      selected:close(self.config.close_children)
      self.filetree.view:redraw()
    else
      selected:expand()
      self.filetree.view:redraw()
      self:keymap_cursor_down()
    end
  else
    self.filetree:open_file(selected.path)
  end
end

function Mapping:keymap_close()
  local selected = self.filetree.view:get_selected()
  if (selected == nil) then
    if (self.filetree:set_parent_as_root()) then
      self.filetree.view:set_cursor(1)
    end
  elseif (selected.rtype == "directory" and selected.expanded) then
    selected:close(self.config.close_children)
  else
    -- check if parent is root
    if (selected.parent.parent == nil) then
      local parent_path = Help:get_file_parent(self.filetree.tree.path)
      if (not(self.filetree.tree.path == parent_path)) then
	if (self.filetree:set_parent_as_root()) then
	  self.filetree.view:set_cursor(1)
	end
      end
    else
      selected.parent:close(self.config.close_children)
      self.filetree.view:set_selected(selected.parent)
    end
  end
  self.filetree.view:redraw()
end

function Mapping:keymap_enter()
  local selected = self.filetree.view:get_selected()
  if (selected == nil) then return end

  if (selected.rtype == "directory") then
    self.filetree:set_directory(selected.path)
    if (self.filetree:load_tree()) then
      self.filetree.view:set_cursor(1)
    end
  else
    self.filetree:open_file(selected.path)
  end
  self.filetree.view:redraw()
end

---@param reverse  move cursor up instead of down if true
function Mapping:keymap_mark(reverse)
  local selected = self.filetree.view:get_selected()
  if (selected == nil) then return end

  if (selected.marked) then
    self.filetree.view:remove_marked(selected)
  else
    self.filetree.view:add_marked(selected)
  end

  self.filetree.view:redraw()
  if (reverse) then
    self:keymap_cursor_up()
  else
    self:keymap_cursor_down()
  end
end

function Mapping:keymap_make_file()
  local selected = self.filetree.view:get_selected()
  local dir_node = self:get_node_tree(selected)
  if (dir_node == nil) then return end

  local input_names = Help:get_user_input("New file names (comma seperated)")

  for_each_name(input_names, function(name)
    local path = dir_node.path.."/"..name
    self.filetree:make_file(path)
    if (vim.fn.filereadable(path)) then
      local created = dir_node:add_node_by_path(path)
      if (created:is_dot_file()) then
	self.filetree.view.config.show_hidden = true
      end
      dir_node:sort()
      self.filetree.view:redraw()
      self.filetree.view:set_selected(created)
    end
  end)
end

function Mapping:keymap_make_directory()
  local selected = self.filetree.view:get_selected()
  local dir_node = self:get_node_tree(selected)
  if (dir_node == nil) then return end

  local input_names = Help:get_user_input("New directory names (comma seperated)")

  for_each_name(input_names, function(name)
    local path = dir_node.path.."/"..name
    self.filetree:make_directory(path)
    if (vim.fn.isdirectory(path)) then
      local created = dir_node:add_node_by_path(path)
      if (created:is_dot_file()) then
	self.filetree.view.config.show_hidden = true
      end
      dir_node:sort()
      self.filetree.view:redraw()
      self.filetree.view:set_selected(created)
    end
  end)
end

---@param what  if "name": rename file name, if "ext": rename file extension
function Mapping:keymap_rename(what)
  local selected = self.filetree.view:get_selected()

  if (selected == nil) then
    print("No file selected")
    return
  end

  local dir_node = self:get_node_tree(selected)

  local new_name = ""
  local ext = Help:get_file_extension(selected.name)
  local name = Help:remove_file_extension(selected.name, ext)
  if (what == "name" and name ~= "") then
    new_name = Help:get_user_input("New file name (non ext)", name)
    if (ext ~= "") then
      new_name = new_name.."."..ext
    end
  elseif (what == "ext" and ext ~= "") then
    new_name = Help:get_user_input("New file extension", ext)
    if (name ~= "") then
      new_name = name.."."..new_name
    end
  else
    new_name = Help:get_user_input("New file name", selected.name)
  end

  new_name = vim.trim(new_name)
  if (new_name == selected.name or new_name == "") then
    return
  end

  local new_path = Help:make_path(dir_node.path, new_name)
  if (Help:file_exists(new_path)) then
    if (not Help:get_user_yenso(new_name.." already exists. Overwrite file?", false)) then
      return
    end
  end

  self.filetree:move_file(selected.path, new_path)
  if (Help:file_exists(new_path)) then
    selected:delete()
    local created = dir_node:add_node_by_path(new_path)
    if (created:is_dot_file()) then
      self.filetree.view.config.show_hidden = true
    end
    dir_node:sort()
    self.filetree.view:redraw()
    self.filetree.view:set_selected(created)
  end

  self.filetree.view:redraw()
end

function Mapping:keymap_copy()
  local selected = self.filetree.view:get_selected()
  local dir_node = self:get_node_tree(selected)
  if (dir_node == nil) then return end
  local to_copy = self.filetree.view:get_marked()

  if (#to_copy == 0) then
    print("No files selected")
    return
  end

  local num = self:copy_nodes(to_copy, dir_node)
  self.filetree.view:clear_marked()
  self.filetree.view:redraw()

  print(num.." files copied.")
end

function Mapping:keymap_move()
  local selected = self.filetree.view:get_selected()
  local dir_node = self:get_node_tree(selected)
  if (dir_node == nil) then return end
  local to_move = self.filetree.view:get_marked()

  if (#to_move == 0) then
    print("No files selected")
    return
  end

  local num = self:move_nodes(to_move, dir_node)
  self.filetree.view:clear_marked()
  self.filetree.view:redraw()

  print(num.." files moved.")
end

function Mapping:keymap_remove()
  local to_remove = self:get_selected_nodes()
  if (to_remove == nil) then return end

  local confirm = Help:get_user_yesno("Remove "..#to_remove.." file(s)?", false)
  if (not confirm) then
    return
  end

  local num = self:remove_nodes(to_remove)
  self.filetree.view:clear_marked()
  self.filetree.view:redraw()

  print(num.." files removed.")
end

function Mapping:keymap_yank()
  if (self.yanked == nil) then return end

  if (self.config.yank_file_names == "path") then
    local file_paths = Help:make_string_from_list(self.yanked, function(node) return node.path end, "\n")
    vim.fn.setreg("\"", file_paths, "l")
  elseif (self.config.yank_file_names == "name") then
    local file_names = Help:make_string_from_list(self.yanked, function(node) return node.name end, "\n")
    vim.fn.setreg("\"", file_paths, "l")
  end

  print(#self.yanked.." files yanked.")

  self.filetree.view:clear_marked()
  self.filetree.view:redraw()
end

function Mapping:keymap_paste()
  local selected = self.filetree.view:get_selected()
  local dir_node = self:get_node_tree(selected)
  if (dir_node == nil) then return end

  if (self.yanked == nil or #self.yanked == 0) then
    print("No files yanked.")
    return
  end

  local num = self:move_nodes(self.yanked, dir_node)
  self.filetree.view:redraw()
  
  print(num.." files pasted.")
end

---@param remove_files  if true: removes the files after packed
function Mapping:keymap_pack(remove_files)
  local available_formats = Help:list_available_pkg_formats()
  if (#available_formats == 0) then
    print("No package format available")
    return
  end

  local to_pack = self:get_selected_nodes()
  if (to_pack == nil) then return end

  local selected = self.filetree.view:get_selected()
  local dir_node = self:get_node_tree(selected)

  local path = ""
  if (dir_node ~= nil) then
    path = dir_node.path.."/pkg"
  else
    path = "/"
  end
  path = Help:get_user_input("Package path", path)

  if (Help:file_exists(path)) then
    if (not Help:get_user_yesno(path.." already exists. Overwrite file?", false)) then
      return
    end
  end

  local format = nil
  local is_valid = false
  while (format == nil) do
    local input_format = Help:get_user_input("Package format ('l' list available)")
    if (input_format == "" or input_format == "q") then
      goto leave_loop
    end

    if (input_format == "l") then
      local formats_str = ""
      for i, fmt in ipairs(available_formats) do
	if (i == #available_formats) then
	  formats_str = formats_str..fmt[1]
	else
	  formats_str = formats_str..fmt[1]..", "
	end
      end
      Help:get_user_continue(formats_str)
    else
      for i, fmt in ipairs(available_formats) do
	if (input_format == fmt[1]) then
	  format = fmt
	  goto leave_loop
	end
      end
    end
  end

  :: leave_loop ::

  if (format == nil) then
    print("No package format selected")
    return
  end

  local options = format[2].default_opts
  options = Help:get_user_input("Options", options)

  options = vim.fn.substitute(options, "<path>", path, "g")

  local files = ""
  for i, node in ipairs(to_pack) do
    local file = vim.fn.fnamemodify(Help:make_path_cl_suitable(node.path), ":.")
    if (i == #to_pack) then
      files = "\""..files..file.."\""
    else
      files = "\""..files..file.."\" "
    end
  end
  options = vim.fn.substitute(options, "<files>", files, "g")

  format[2].pack_fn(options)
  self.filetree.view:clear_marked()
  self.filetree.view:redraw()
end

---@param remove_file  if true: removes the file after compressed
function Mapping:keymap_compress(remove_file)
end

function Mapping:keymap_info()
  local selected = self.filetree.view:get_selected()
  if (selected == nil) then return end
  self.filetree:open_file_info_view(selected)
end

function Mapping:keymap_preview()
  local selected = self.filetree.view:get_selected()
  if (selected == nil) then return end
  self.filetree:open_file_preview(selected.path)
end

function Mapping:keymap_toggle_hidden()
  self.filetree.view.config.show_dot_files = not self.filetree.view.config.show_dot_files
  self.filetree.view:redraw()
end

function Mapping:keymap_redraw()
  self.filetree.view:force_redraw()
end

function Mapping:keymap_reload()
  self.filetree.tree:soft_reload_recursive()
end

function Mapping:keymap_clear()
  self.filetree.view:clear_marked()
  self.filetree.view:redraw()
end


-- ### Helper functions ### --

function Mapping:copy_nodes(nodes, dir_node)
  local num = 0
  for i, node in ipairs(nodes) do
    local new_path = Help:make_path(dir_node.path, node.name)
    local continue = true
    if (Help:file_exists(new_path)) then
      continue = Help:get_user_yesno("A file with name '"..node.name.."' already exists. Overwrite file?", false)
    end

    if (continue) then
      self.filetree:copy_file(node.path, new_path)
      if (Help:file_exists(new_path)) then
	local created = dir_node:add_node_by_path(new_path)
	num = num + 1
	dir_node:sort()
      end
    end
  end
  return num
end

function Mapping:move_nodes(nodes, dir_node)
  local num = 0
  for i, node in ipairs(nodes) do
    local new_path = Help:make_path(dir_node.path, node.name)
    local continue = true
    if (Help:file_exists(new_path)) then
      continue = Help:get_user_yesno("A file with name '"..node.name.."' already exists. Overwrite file?", false)
    end

    if (continue) then
      self.filetree:move_file(node.path, new_path)
      if (Help:file_exists(new_path)) then
	node:delete(node)
	local created = dir_node:add_node_by_path(new_path)
	num = num + 1
	dir_node:sort()
      end
    end
  end
  return num
end

function Mapping:remove_nodes(nodes)
  local num = 0
  for i, node in ipairs(nodes) do
    local path = node.path
    if (node.type == "link") then
      local rm_link = Help:get_user_yesno(path.." is a symbolic link. Only remove the link?", true)
      if (not rm_link) then
	path = node.rpath
      end
    end
    self.filetree:remove_file(path)
    if (not Help:file_exists(path)) then
      node:delete()
      num = num + 1
    end
  end
  return num
end

function Mapping:get_selected_nodes()
  local selected = self.filetree.view:get_selected()
  local marked = self.filetree.view:get_marked()

  local nodes = {}

  if (#marked ~= 0) then
    vim.list_extend(nodes, marked)
  elseif (selected ~= nil) then
    table.insert(nodes, selected)
  else
    return nil
  end
  return nodes
end

function Mapping:get_node_tree(node)
  if (node == nil) then
    return self.filetree.tree
  end
  if (node.expanded) then
    return node
  else
    if (node.parent == nil) then
      return self.filetree.tree
    else
      return node.parent
    end
  end
end

function for_each_name(names, fn)
  local name_list = vim.split(names, ",")
  for i, name in ipairs(name_list) do
    name = vim.trim(name)
    if (name ~= "") then
      fn(name)
    end
  end
end

return Mapping
