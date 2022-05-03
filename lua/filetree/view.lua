local View = {}

---@param conf  table with options {option = value, ...}. |filetree-config|
---@returns View metatable
function View:new(conf)
  local self = setmetatable({}, { __index = View })
  self.config = conf
  self.nodes = {}
  self.marked_nodes = {}
  return self
end

function View:destroy()
  self:close_window()
  if (self.buf ~= nil) then
    vim.api.nvim_buf_delete(self.buf, {force = true})
  end
end

function View:setup_buffer()
  self.buf = vim.fn.bufadd("")
  self.buf = vim.api.nvim_create_buf(false, false)

  vim.api.nvim_buf_set_option(self.buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

function View:open_window()
  vim.api.nvim_command("vsplit")
  self.win = vim.api.nvim_get_current_win()

  if (self.config.position == "right") then
    vim.api.nvim_command("wincmd r")
  end

  vim.api.nvim_win_set_width(self.win, self.config.width)
  vim.api.nvim_win_set_buf(self.win, self.buf)
  vim.api.nvim_win_set_option(self.win, "wrap", false)
  vim.api.nvim_win_set_option(self.win, "number", false)
  vim.api.nvim_win_set_option(self.win, "relativenumber", false)
  vim.api.nvim_win_set_option(self.win, "fillchars", "eob: ")

  self:force_redraw()
end

function View:close_window()
  if (self.win ~= nil) then
    vim.api.nvim_win_close(self.win, false)
    self.win = nil
  end
end

function View:refresh()
  self.width = vim.api.nvim_win_get_width(self.win)
end

function View:force_redraw()
  self:refresh()
  for i, node in ipairs(self.nodes) do
    node.changed = true
  end
  self:redraw()
end

function View:redraw()
  self.nodes = {}
  self.lines = {}

  self:draw_tree(self.tree)
  self:draw_lines()

  for i, node in ipairs(self.nodes) do
    self:highlight_node(node)
  end
end

---@private
function View:draw_lines()
  vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, self.lines)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

---@private
function View:highlight_node(node)
  for i, hl in ipairs(node.hl) do
    vim.api.nvim_buf_add_highlight(self.buf, hl.namespace, hl.group, node.lnum, hl.first, hl.last)
  end
end

---@private
function View:draw_tree(tree)
  for i, node in ipairs(tree.children) do
    self:draw_node(node)
  end
end

---@private
function View:draw_node(node)
  if (node:is_dot_file() and not(self.config.show_dot_files)) then
    return
  end

  self:render_node(node)
  table.insert(self.nodes, node)
  node.index = #self.nodes
  node.lnum = #self.lines

  table.insert(self.lines, node.text)

  if (node.expanded and #node.children ~= 0) then
    self:draw_tree(node)
  end
end

---@param node  Node metatable
function View:render_node(node)
  if (node.changed) then
    node.text = ""
    node.hl = {}
    self:render_line(node)
    node.changed = false
  end
end

---@param node  Node metatable
function View:render_line(node)
  if (self.config.render_callback ~= nil and self.config.render_callback(node)) then
    return
  end

  local symbol = nil
  local name = nil
  local ext = nil

  if (self.config.file_symbols.callback ~= nil) then
    symbol = self.config.file_symbols.callback(node)
  end

  if (self.config.file_names.callback ~= nil) then
    name = self.config.file_names.callback(node)
  end

  if (self.config.file_exts.callback ~= nil) then
    ext = self.config.file_exts.callback(node)
  end

  if (node.rtype == "directory") then
    if (node.expanded) then
      if (node.type == "link") then
	symbol = (symbol or self.config.file_symbols.link_dir_expanded)
	name = (name or self.config.file_names.link_dir_expanded)
	ext = (ext or self.config.file_exts.link_dir_expanded)
      else
	symbol = (symbol or self.config.file_symbols.dir_expanded)
	name = (name or self.config.file_names.dir_expanded)
	ext = (ext or self.config.file_exts.dir_expanded)
      end
    else
      if (node.type == "link") then
	symbol = (symbol or self.config.file_symbols.link_dir)
	name = (name or self.config.file_names.link_dir)
	ext = (ext or self.config.file_exts.link_dir)
      else
	symbol = (symbol or self.config.file_symbols.dir)
	name = (name or self.config.file_names.dir)
	ext = (ext or self.config.file_exts.dir)
      end
    end
  elseif (node.rtype == "link") then
    symbol = (symbol or self.config.file_symbols.link)
    name = (name or self.config.file_names.link)
    ext = (ext or self.config.file_exts.link)
  elseif (node.rtype == "block") then
    symbol = (symbol or self.config.file_symbols.block)
    name = (name or self.config.file_names.block)
    ext = (ext or self.config.file_exts.block)
  elseif (node.rtype == "char") then
    symbol = (symbol or self.config.file_symbols.char)
    name = (name or self.config.file_names.char)
    ext = (ext or self.config.file_exts.char)
  elseif (node.rtype == "socket") then
    symbol = (symbol or self.config.file_symbols.socket)
    name = (name or self.config.file_names.socket)
    ext = (ext or self.config.file_exts.socket)
  elseif (node.rtype == "fifo") then
    symbol = (symbol or self.config.file_symbols.fifo)
    name = (name or self.config.file_names.fifo)
    ext = (ext or self.config.file_exts.fifo)
  else
    symbol = (symbol or self.config.file_symbols.file)
    name = (name or self.config.file_names.file)
    ext = (ext or self.config.file_exts.file)
  end

  symbol = (symbol or self.config.file_symbols.__default)
  name = (name or self.config.file_names.__default)
  ext = (ext or self.config.file_exts.__default)

  local head = symbol.symbol.." "
  local tail = ext.symbol.." "
  node.text = head..node.name..name.suffix

  if (node.marked) then
    node.text = node.text.." *"
  end

  local depth2 = node.depth * self.config.indent
  local indent = ""

  -- indent markers
  if (self.config.indent_markers.enable and node.depth ~= 1) then
    indent = string.rep(" ", self.config.indent)
    local indent_symbol = nil
    local i = 1
    while (i ~= node.depth - 1) do
      indent = indent..self.config.indent_markers.symbols.edge..string.rep(" ", self.config.indent - 1)
      i = i + 1
    end
    if (node:is_last()) then
      indent_symbol = self.config.indent_markers.symbols.corner
      indent = indent..self.config.indent_markers.symbols.corner..string.rep(" ", self.config.indent - 1)
    else
      indent_symbol = self.config.indent_markers.symbols.edge
      indent = indent..self.config.indent_markers.symbols.edge..string.rep(" ", self.config.indent - 1)
    end
  else
    indent = string.rep(" ", depth2)
  end
  node.text = indent..node.text

  -- highlight
  self:add_highlight(node, self.config.indent_markers.hl.ns, self.config.indent_markers.hl.group, 0, #indent)
  self:add_highlight(node, symbol.hlns, symbol.hlg, #indent, #indent + #head)
  self:add_highlight(node, name.hlns, name.hlg, (#indent + #head), #node.text)

  -- wrap
  local width = self.width - self.config.line_width
  if (#node.text > width) then
    node.text = string.sub(node.text, 1, width).."…"
  end

  -- tail
  local text_len = vim.fn.strchars(node.text)
  local ext_space = self.width - text_len - 2
  local ext_off = #node.text + ext_space
  self:add_highlight(node, ext.hlns, ext.hlg, ext_off, ext_off + #ext.symbol)
  node.text = node.text..string.rep(" ", ext_space)..ext.symbol
end

---@param node       node to add highlight
---@param namespace  highlight namespace
---@param group      highlight group name
---@param first      first column
---@param last       last column
function View:add_highlight(node, namespace, group, first, last)
  table.insert(node.hl, {namespace = namespace, group = group, first = first, last = last})
end

---@returns Node metatable
function View:get_selected()
  if (#self.nodes == 0) then
    return nil
  end
  local line = vim.fn.line(".")
  local index = line + self.config.cursor_offset
  return self.nodes[index]
end

---@param node  Node metatable
function View:set_selected(node)
  self:set_cursor(node.index)
end

---@returns cursor position relative to nodes
function View:get_cursor()
  return vim.api.nvim_win_get_cursor(self.win)[1] - self.config.cursor_offset
end

---@param line  line number
function View:set_cursor(line)
  vim.api.nvim_win_set_cursor(self.win, {line + self.config.cursor_offset, 0})
end

---returns number of nodes in buffer
function View:get_node_count()
  return #self.nodes
end

---@returns table with nodes
function View:get_marked()
  return self.marked_nodes
end

---@param node  Node metatable
function View:add_marked(node)
  node:mark()
  self:render_node(node)
  table.insert(self.marked_nodes, node)
end

---@param node  Node metatable
function View:remove_marked(node)
  node:unmark()
  self:render_node(node)

  local pos = 0
  local index = 1
  for i, entry in ipairs(self.marked_nodes) do
    if (entry == node) then
      pos = index
      break
    end
    index = index + 1
  end

  if (not(pos == 0)) then
    table.remove(self.marked_nodes, pos)
  end
end

function View:clear_marked()
  for i, node in ipairs(self.marked_nodes) do
    node:unmark()
    self:render_node(node)
  end
  self.marked_nodes = {}
end


-- ### Getters and setters ### ---

---@param tree  Tree metatable
function View:set_tree(tree)
  self.tree = tree
end

---@returns true if window is open
function View:is_active()
  return self.win ~= nil
end

---@returns true if window width changed
function View:should_redraw()
  if (self.win == nil) then
    return false
  end

  if (self.width ~= vim.api.nvim_win_get_width(self.win)) then
    return true
  end
  return false
end

return View
