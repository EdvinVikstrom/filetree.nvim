local View = {}

-- params: {conf: Table}
-- return: View
function View:new(conf)
  local self = setmetatable({}, { __index = View })
  self.config = (conf or {})

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
  conf.render_callback = (conf.render_callback or function(view, nview) view:render_callback(nview) end)
end

function View:setup_buffer()
  self.buf = vim.fn.bufadd("")
  self.bufnr = vim.fn.bufnr(self.buf)

  vim.api.nvim_buf_set_option(self.buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

function View:setup_window()
  vim.api.nvim_command("vsplit")
  self.win = vim.api.nvim_get_current_win()

  if (self.config.position == "right") then
    vim.api.nvim_command("wincmd r")
  end

  vim.api.nvim_win_set_option(self.win, "wrap", false)
  vim.api.nvim_win_set_option(self.win, "number", false)
  vim.api.nvim_win_set_option(self.win, "relativenumber", false)
  vim.api.nvim_win_set_width(self.win, self.config.width)
  vim.api.nvim_win_set_buf(self.win, self.buf)
end

function View:full_redraw()
  self:begin_render()
  for i, node in ipairs(self.tree.children) do
    self:render_node(node)
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

function View:draw_lines()
  vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, self.lines)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", false)
end

-- params: {node: NodeView}
function View:highlight_node(node)
  for i, hl in ipairs(node.hl) do
    vim.api.nvim_buf_add_highlight(self.buf, hl.namespace, hl.group, node.lnum, hl.first, hl.last)
  end
end

-- params: {tree: Tree}
function View:draw_tree(tree)
  for i, node in ipairs(tree.children) do
    self:draw_node(node)
  end
end

-- params: {node: Node}
function View:draw_node(node)
  if (node:is_hidden() and not(self.config.show_hidden)) then
    return
  end

  table.insert(self.nodes, node.view)
  node.view.index = #self.nodes
  node.view.lnum = #self.lines

  table.insert(self.lines, node.view.line)

  if (node.expanded) then
    self:draw_tree(node)
  end
end

function View:begin_render()
  self.width = vim.api.nvim_win_get_width(self.win)
end

-- params: {node: NodeView}
function View:render_node(node)
  node.view:clear()
  self.config.render_callback(self, node.view)

  if (node.expanded) then
    for i, child in ipairs(node.children) do
      self:render_node(child)
    end
  end
end

-- params: {nview: NodeView}
function View:render_callback(nview)
  nview:render(self.config)
  local width = self.width - self.config.line_width

  -- offset text
  nview.line = string.rep(" ", nview.node.depth)..nview:get_text()

  -- highlight
  local len = nview.node.depth + #nview:get_text()
  if (nview.node.rtype == "dir") then
    nview:add_highlight(self.config.hl.namespace, self.config.hl.directory, 0, len)
  else
    nview:add_highlight(self.config.hl.namespace, self.config.hl.file, 0, len)
  end

  if (#nview.line > width) then
    nview.line = string.sub(nview.line, 1, width).."…"
  end
end

-- return Node
function View:get_selected()
  if (#self.nodes == 0) then
    return nil
  end
  local line = vim.fn.line(".")
  local index = line + self.config.cursor_offset
  return self.nodes[index].node
end

-- params {node: Node}
function View:set_selected(node)
  vim.fn.cursor(node.view.index + self.config.cursor_offset, 0)
end

-- return array{Node ...}
function View:get_marked()
  return self.marked_nodes
end

-- params {node: Node}
function View:add_marked(node)
  node.marked = true
  self:render_node(node)
  table.insert(self.marked_nodes, node)
end

-- params {node: Node}
function View:remove_marked(node)
  node.marked = false
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
    node.marked = false
    self:render_node(node)
  end
  self.marked_nodes = {}
end


-- ### Getters and setters ### ---

-- params: {tree: Tree}
function View:set_tree(tree)
  self.tree = tree
end

return View
