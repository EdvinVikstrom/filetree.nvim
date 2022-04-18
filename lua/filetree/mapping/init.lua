local Mapping = {}

local Help = require("filetree.help")

-- params: {filetree: FileTree, conf: Table}
-- return: Mapping
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
end

function Mapping:setup_mappings()
  self.autocmds = {
    { event = "VimEnter", pattern = "*", callback = function() self:autocmd_vim_enter() end },
    { event = "WinScrolled", pattern = "*", callback = function() self:autocmd_win_scrolled() end },
    { event = "User", pattern = "dir_changed", callback = function() self:autocmd_user_dir_changed() end }
  }
  self.keymaps = {
    { lhs = "j", rhs = function() self:keymap_move_down() end },
    { lhs = "k", rhs = function() self:keymap_move_up() end },
    { lhs = "l", rhs = function() self:keymap_open() end },
    { lhs = "h", rhs = function() self:keymap_close() end },
    { lhs = "<Enter>", rhs = function() self:keymap_load() end },
    { lhs = "w", rhs = function() self:keymap_mark(false) end },
    { lhs = "W", rhs = function() self:keymap_mark(true) end },
    { lhs = "N", rhs = function() self:keymap_make_file() end },
    { lhs = "K", rhs = function() self:keymap_make_directory() end },
    { lhs = "r", rhs = function() self:keymap_rename() end },
    { lhs = "m", rhs = function() self:keymap_move() end },
    { lhs = "x", rhs = function() self:keymap_remove(false) end },
    { lhs = "X", rhs = function() self:keymap_remove(true) end },
    { lhs = ".", rhs = function() self:keymap_toggle_hidden() end },
    { lhs = ",", rhs = function() self:keymap_reload() end },
    { lhs = "<Esc>", rhs = function() self:keymap_clear() end }
  }
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
  for i, map in ipairs(self.keymaps) do
    vim.keymap.set('n', map.lhs, map.rhs, {buffer = self.filetree.view.buf, silent = true})
  end
end

function Mapping:setup_watcher()
  -- TODO
end

function Mapping:full_redraw()
  self.filetree.view:begin_render()
  self.filetree:render_tree()
  self.filetree.view:redraw()
end


-- ### Autocmd callback ### --

function Mapping:autocmd_vim_enter()
  self.filetree:load_tree()
end

function Mapping:autocmd_win_scrolled()
  self.filetree.view:full_redraw()
end

function Mapping:autocmd_user_dir_changed()
  self:setup_watcher()
end


-- ### Keymap callback ### --

function Mapping:keymap_move_down()
  local line = vim.fn.line(".")
  if (line == vim.api.nvim_buf_line_count(self.filetree.view.buf)) then
    if (self.config.wrap_cursor) then
      vim.fn.cursor(1, 0)
    end
  else
    vim.fn.cursor(line + 1, 0)
  end
end

function Mapping:keymap_move_up()
  local line = vim.fn.line(".")
  if (line == 1) then
    if (self.config.wrap_cursor) then
      vim.fn.cursor(vim.api.nvim_buf_line_count(self.filetree.view.buf), 0)
    end
  else
    vim.fn.cursor(line - 1, 0)
  end
end

function Mapping:keymap_open()
  local selected = self.filetree.view:get_selected()
  if (selected.rtype == "dir") then
    if (selected.expanded) then
      selected:close()
      self.filetree.view:render_node(selected)
      self.filetree.view:redraw()
    else
      selected:expand()
      self.filetree.view:render_node(selected)
      self.filetree.view:redraw()
      self:keymap_move_down()
    end
  else
    selected:open()
  end
end

function Mapping:keymap_close()
  local selected = self.filetree.view:get_selected()
  if (selected.rtype == "dir" and selected.expanded) then
    selected:close(self.config.close_children)
    self.filetree.view:render_node(selected)
  else
    -- check if parent is root
    if (selected.parent.parent == nil) then
      local parent_path = Help:get_file_parent(self.filetree.tree.path)
      if (not(self.filetree.tree.path == parent_path)) then
	self.filetree:set_directory(parent_path)
	self.filetree:load_tree()
      end
    else
      selected.parent:close(self.config.close_children)
      self.filetree.view:set_selected(selected.parent)
      self.filetree.view:render_node(selected.parent)
    end
  end
  self.filetree.view:redraw()
end

function Mapping:keymap_load()
  local selected = self.filetree.view:get_selected()
  if (selected.rtype == "dir") then
    self.filetree:set_directory(selected.path)
    self.filetree:load_tree()
  else
    selected:open()
  end
  self.filetree.view:redraw()
end

-- params: {reverse: Boolean}
function Mapping:keymap_mark(reverse)
  local selected = self.filetree.view:get_selected()

  if (selected.marked) then
    self.filetree.view:remove_marked(selected)
  else
    self.filetree.view:add_marked(selected)
  end

  self.filetree.view:redraw()
  if (reverse) then
    self:keymap_move_up()
  else
    self:keymap_move_down()
  end
end

function Mapping:keymap_make_file()
  local selected = self.filetree.view:get_selected()
  local dir_node = get_node_tree(selected)

  local input_names = Help:get_user_input("New file names (comma seperated)")

  for_each_name(input_names, function(name)
    local path = dir_node.path.."/"..vim.trim(name)
    vim.fn.writefile({}, path, "b")
    if (vim.fn.filereadable(path)) then
      dir_node:add_file(path)
      dir_node:sort()
    end
  end)

  self.filetree.view:redraw()
end

function Mapping:keymap_make_directory()
  local selected = self.filetree.view:get_selected()
  local dir_node = get_node_tree(selected)

  local input_names = Help:get_user_input("New directory names (comma seperated)")

  for_each_name(input_names, function(name)
    local path = dir_node.path.."/"..vim.trim(name)
    vim.fn.mkdir(path)
    if (vim.fn.isdirectory(path)) then
      dir_node:add_file(path)
      dir_node:sort()
    end
  end)

  self.filetree.view:redraw()
end

function Mapping:keymap_rename()
  local selected = self.filetree.view:get_selected()

  if (selected == nil) then
    print("No file selected")
    return
  end

  local dir_node = get_node_tree(selected)

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

  vim.fn.rename(selected.path, new_path)
  if (Help:file_exists(new_path)) then
    selected:delete()
    dir_node:add_file(new_path)
    dir_node:sort()
  end

  self.filetree.view:redraw()
end

function Mapping:keymap_move()
  local selected = self.filetree.view:get_selected()
  local dir_node = get_node_tree(selected)
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
      vim.fn.rename(node.path, new_path)
      if (Help:file_exists(new_path)) then
	node:delete(node)
	dir_node:add_file(new_path)
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
    vim.fn.delete(path, "rf")
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

function Mapping:keymap_reload()
  self.filetree.view:full_redraw()
end

function Mapping:keymap_clear()
  self.filetree.view:clear_marked()
  self.filetree.view:redraw()
end


-- ### Helper functions ### --

-- params: {node: Node}
-- return: Node
function get_node_tree(node)
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

-- params: {names: Table{String ...}, fn: Function}
function for_each_name(names, fn)
  local name_list = vim.split(names, ",")
  for i, name in ipairs(name_list) do
    fn(name)
  end
end

return Mapping
