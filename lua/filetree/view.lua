local View = {}

---@param conf  table with options {option = value, ...}. |filetree-config|
---@returns View metatable
function View:new(conf)
  local self = setmetatable({}, { __index = View })
  self.config = (conf or {})

  self.nodes = {}
  self.marked_nodes = {}
  return self
end

function View:setup_highlight()
  self.hlns = vim.api.nvim_create_namespace("filetree")

  vim.api.nvim__set_hl_ns(self.hlns)
  vim.cmd("hi dir ctermfg=blue")
  vim.cmd("hi file ctermfg=white")
end

function View:setup_config()
  local conf = self.config
  conf.cursor_offset = 0
  conf.position = (conf.position or "left")
  conf.width = (conf.width or 40)
  conf.line_width = (conf.line_width or 6)
  conf.show_hidden = (conf.show_hidden or false)
  conf.symbols = (conf.symbols or {})
  conf.symbols.tree_expanded = (conf.symbols.tree_expanded or "v")
  conf.symbols.tree_closed = (conf.symbols.tree_closed or ">")
  conf.hl = (conf.hl or {})
  conf.hl.namespace = (conf.hl.namespace or self.hlns)
  conf.hl.directory = (conf.hl.directory or "dir")
  conf.hl.file = (conf.hl.file or "file")
  conf.render_callback = (conf.render_callback or function(view, node) view:render_callback(node) end)
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
  if (node:is_hidden() and not(self.config.show_hidden)) then
    return
  end

  self:render_node(node)
  table.insert(self.nodes, node)
  node.index = #self.nodes
  node.lnum = #self.lines

  table.insert(self.lines, node.text)

  if (node.expanded) then
    self:draw_tree(node)
  end
end

---@param node  Node metatable
function View:render_node(node)
  if (node.changed) then
    node.text = ""
    node.hl = {}
    self.config.render_callback(self, node)
    node.changed = false
  end
end

---@param node  Node metatable
function View:render_callback(node)
  local head = "- "
  if (node.rtype == "directory") then
    if (node.expanded) then
      head = self.config.symbols.tree_expanded.." "
      node.text = head..node.name..'/'
    else
      head = self.config.symbols.tree_closed.." "
      node.text = head..node.name..'/'
    end
  elseif (node.rtype == "link") then
    node.text = head..node.name.."@"
  elseif (node.rtype == "block") then
    node.text = head..node.name.."#"
  elseif (node.rtype == "char") then
    node.text = head..node.name.."%"
  elseif (node.rtype == "socket") then
    node.text = head..node.name.."="
  elseif (node.rtype == "fifo") then
    node.text = head..node.name.."|"
  else
    node.text = head..node.name
  end
  if (node.marked) then
    node.text = node.text.." *"
  end
  node.name_offset = #head

  local width = self.width - self.config.line_width

  -- offset text
  node.text = string.rep(" ", node.depth)..node.text

  -- highlight
  local len = node.depth + #node.text
  if (node.rtype == "directory") then
    self:add_highlight(node, self.config.hl.namespace, self.config.hl.directory, 0, len)
  else
    self:add_highlight(node, self.config.hl.namespace, self.config.hl.file, 0, len)
  end

  if (#node.text > width) then
    node.text = string.sub(node.text, 1, width).."…"
  end
end

---@param namespace  highlight namespace
---@param group  highlight group name
---@param first  first column
---@param last  last column
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
