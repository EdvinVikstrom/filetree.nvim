local FileTree = {}

local View = require("filetree.view")
local NodeView = require("filetree.view.node")
local Mapping = require("filetree.mapping")
local Tree = require("filetree.tree")

-- params: {conf: Table}
-- return: FileTree
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
  self.view:setup_window()

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

  _G.filetree = self
  return self
end

function FileTree:setup_config()
  local conf = self.config
  conf.directory = (conf.directory or vim.fn.getcwd())
  conf.node = (conf.node or {})
  conf.node.init = (conf.node.init or function(node) self:node_init_callback(node) end)
end

function FileTree:load_tree()
  vim.fn.cursor(1, 0)
  self.view:begin_render()
  self.tree = Tree:new(self.config.node, self.config.directory, nil, 0)
  self.view:set_tree(self.tree)
  self.tree:reload()
  self.view:redraw()
end

-- params: {node: Node}
function FileTree:node_init_callback(node)
  node.open = function(node)
    self:open_file(node.path)
  end

  node.delete = function(node)
    node.parent:remove_node(node)
  end

  node:update_cache()
  node.view = NodeView:new(node)
  self.view:render_node(node)
end

-- params: {file: String}
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

function FileTree:load_extensions()
  for i, ext in ipairs(self.extensions) do
    ext:setup_highlight()
    ext:setup_config()
    ext:setup_autocmds()
    ext:setup_keymaps()
    ext:init(self)
  end
end

-- params: {name: String, conf: Table}
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

-- return: String
function FileTree:get_directory()
  return self.config.directory
end

-- params: {path: String}
function FileTree:set_directory(path)
  self.config.directory = path
  vim.cmd("augroup filetree | doautocmd User dir_changed | augroup END")
end

return FileTree
