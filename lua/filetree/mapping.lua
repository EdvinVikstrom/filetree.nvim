local Mapping = {}

local Help = require("filetree.help")

---@param filetree  FileTree metatable
---@param conf  table with options {option = value, ...}. |filetree-config|
---@returns Mapping metatable
function Mapping:new(filetree, conf)
  local self = setmetatable({}, { __index = Mapping })
  self.filetree = filetree
  self.config = (conf or {})
  return self
end

function Mapping:setup_config()
  local conf = self.config
  if (conf.wrap_cursor == nil) then conf.wrap_cursor = false end
  if (conf.close_children == nil) then conf.close_children = true end
  conf.keymaps = (conf.keymaps or Mapping.default_keymaps)
end

function Mapping:setup_mappings()
  self.autocmds = {
    { event = "VimEnter", pattern = "*", callback = function() self:autocmd_vim_enter() end },
    { event = "VimLeave", pattern = "*", callback = function() self:autocmd_vim_leave() end },
    { event = "VimResized", pattern = "*", callback = function() self:autocmd_vim_resized() end },
    { event = "WinEnter", pattern = self.filetree.view.win, callback = function() self:autocmd_win_enter() end },
    { event = "WinScrolled", pattern = self.filetree.view.win, callback = function() self:autocmd_win_scrolled() end },
    { event = "User", pattern = "dir_changed", callback = function() self:autocmd_user_dir_changed() end }
  }

  vim.cmd("command FTreeOpen lua _G.filetree.view:open_window()")
  vim.cmd("command FTreeClose lua _G.filetree.view:close_window()")
end

function Mapping:setup_autocmds()
  self.augroup = vim.api.nvim_create_augroup("filetree", { clear = true })

  for i, map in ipairs(self.autocmds) do
    local opts = {
      group = self.augroup,
      pattern = map.pattern,
      callback = map.callback
    }
    map.id = vim.api.nvim_create_autocmd(map.event, opts)
  end
end

function Mapping:setup_keymaps()
  for key, map in pairs(self.config.keymaps) do
    vim.keymap.set('n', key, function() map(self) end, {buffer = self.filetree.view.buf, silent = true})
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

function Mapping:autocmd_win_enter()
  if (self.filetree.view:is_active()) then
    self.filetree.tree:soft_reload_recursive()
    self.filetree.view:redraw()
  end
end

function Mapping:autocmd_win_scrolled()
  if (self.filetree.view:should_redraw()) then
    self.filetree.view:force_redraw()
  end
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
function Mapping:rename() return function(self) self:keymap_rename() end end
function Mapping:copy() return function(self) self:keymap_copy() end end
function Mapping:move() return function(self) self:keymap_move() end end
function Mapping:remove() return function(self) self:keymap_remove() end end
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
  ["c"] = Mapping:copy(),
  ["m"] = Mapping:move(),
  ["x"] = Mapping:remove(),
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
      selected:close()
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
      dir_node:sort()
      self.filetree.view:redraw()
      self.filetree.view:set_selected(created)
    end
  end)
end

function Mapping:keymap_rename()
  local selected = self.filetree.view:get_selected()

  if (selected == nil) then
    print("No file selected")
    return
  end

  local dir_node = self:get_node_tree(selected)

  local new_name = Help:get_user_input("New file name", selected.name)
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

  for i, node in ipairs(to_copy) do
    local new_path = Help:make_path(dir_node.path, node.name)
    local continue = true
    if (Help:file_exists(new_path)) then
      continue = Help:get_user_yesno("A file with name '"..node.name.."' already exists. Overwrite file?", false)
    end

    if (continue) then
      self.filetree:copy_file(node.path, new_path)
      if (Help:file_exists(new_path)) then
	local created = dir_node:add_node_by_path(new_path)
	dir_node:sort()
      end
    end
  end

  self.filetree.view:clear_marked()
  self.filetree.view:redraw()
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

  for i, node in ipairs(to_move) do
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
	dir_node:sort()
      end
    end
  end

  self.filetree.view:clear_marked()
  self.filetree.view:redraw()
end

function Mapping:keymap_remove()
  local selected = self.filetree.view:get_selected()
  local marked = self.filetree.view:get_marked()

  local to_remove = {}

  if (not(#marked == 0)) then
    vim.list_extend(to_remove, marked)
  else
    table.insert(to_remove, selected)
  end

  local confirm = Help:get_user_yesno("Remove "..#to_remove.." file(s)?", false)
  if (not confirm) then
    return
  end

  for i, node in ipairs(to_remove) do
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
    end
  end

  self.filetree.view:clear_marked()
  self.filetree.view:redraw()
end

function Mapping:keymap_toggle_hidden()
  self.filetree.view.config.show_hidden = not self.filetree.view.config.show_hidden
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
