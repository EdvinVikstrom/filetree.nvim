local Extension = require("filetree.extension")
local ExtIcons = Extension:inherit()

-- params: {conf: Table}
-- return: ExtIcons
function ExtIcons:new(conf)
  local self = setmetatable(Extension:new("icons", conf), { __index = ExtIcons })
  return self
end

function ExtIcons:setup_highlight()
  self.hlns = vim.api.nvim_create_namespace("filetree_icons")

  vim.api.nvim__set_hl_ns(self.hlns)
  for key, icon in pairs(ExtIcons.icons) do
    local name = "i"..key
    vim.cmd("hi "..name.." ctermfg="..icon.hl.fg)
    icon.hl.name = name
  end
end

function ExtIcons:setup_config()
end

-- params: {filetree: FileTree}
function ExtIcons:init(filetree)
  self.render_callback = self:setup_render_callback(filetree)
  filetree.view.config.render_callback = self.render_callback
end

-- params: {filetree: FileTree}
function ExtIcons:setup_render_callback(filetree)
  return function(view, nview)
    view:render_callback(nview)

    local len = vim.fn.strchars(nview.line)
    local off = view.width - len - 2

    local icon = ExtIcons:get_icon(nview.node)
    local icon_off = #nview.line + off
    local icon_end = icon_off + #icon.symbol
    nview:add_highlight(self.hlns, icon.hl.name, icon_off, icon_end)
    nview.line = nview.line..string.rep(" ", off)..icon.symbol
  end
end


-- ### static functions ### --

-- params: {node: Node}
-- return: Table{symbol: String, hl: Table}
function ExtIcons:get_icon(node)
  if (node.rtype == "dir") then
    if (node.type == "link") then
      if (node.expanded) then return self.icons.link_dir_open else return self.icons.link_dir end
    else
      if (node.expanded) then return self.icons.dir_open else return self.icons.dir end
    end
  end

  for i, item in ipairs(ExtIcons.match_tail) do
    if ((item.rtype == nil or item.rtype == node.rtype) and (item.type == nil or item.type == node.type) and item.tail == node.cache.tail) then
      return item.icon
    end
  end

  for i, item in ipairs(ExtIcons.match_regex) do
    if ((item.rtype == nil or item.rtype == node.rtype) and (item.type == nil or item.type == node.type) and item.expr:match_str(node.name)) then
      return item.icon
    end
  end
  return self.icons.default
end

function ExtIcons:setup_icons()
  self.icons = {
    default = 			{symbol = "", hl = {fg = "white"}},
    dir = 			{symbol = "", hl = {fg = "blue"}},
    dir_open = 			{symbol = "", hl = {fg = "blue"}},
    link_dir = 			{symbol = "", hl = {fg = "blue"}},
    link_dir_open = 		{symbol = "", hl = {fg = "blue"}},
    c = 			{symbol = "", hl = {fg = 66}},
    cpp = 			{symbol = "", hl = {fg = 66}},
    vim = 			{symbol = "", hl = {fg = 106}},
    lua = 			{symbol = "", hl = {fg = 96}},
    html = 			{symbol = "", hl = {fg = 166}},
    java = 			{symbol = "", hl = {fg = 24}},
    javascript = 		{symbol = "", hl = {fg = 172}},
    markdown = 			{symbol = "", hl = {fg = "gray"}},
    python = 			{symbol = "", hl = {fg = 136}},
    ruby = 			{symbol = "", hl = {fg = 88}},
    rust = 			{symbol = "", hl = {fg = "white"}},
    terminal = 			{symbol = "", hl = {fg = "red"}},
    config = 			{symbol = "", hl = {fg = "white"}},
    git_dir = 			{symbol = "", hl = {fg = "white"}},
  }
end

function ExtIcons:setup_matches()
  self.match_tail = {
    {tail = "c", 				icon = self.icons.c},
    {tail = "h", 				icon = self.icons.c},
    {tail = "cpp", 				icon = self.icons.cpp},
    {tail = "hpp", 				icon = self.icons.cpp},
    {tail = "cxx", 				icon = self.icons.cpp},
    {tail = "hxx", 				icon = self.icons.cpp},
    {tail = "cc", 				icon = self.icons.cpp},
    {tail = "hh", 				icon = self.icons.cpp},
    {tail = "vim", 				icon = self.icons.vim},
    {tail = "nvim", 				icon = self.icons.vim},
    {tail = "lua", 				icon = self.icons.lua},
    {tail = "html", 				icon = self.icons.html},
    {tail = "htm", 				icon = self.icons.html},
    {tail = "java", 				icon = self.icons.java},
    {tail = "class", 				icon = self.icons.java},
    {tail = "js", 				icon = self.icons.javascript},
    {tail = "md", 				icon = self.icons.markdown},
    {tail = "py", 				icon = self.icons.python},
    {tail = "rb", 				icon = self.icons.ruby},
    {tail = "rs", 				icon = self.icons.rust},
    {tail = "sh", 				icon = self.icons.terminal},
    {tail = "zsh", 				icon = self.icons.terminal},
    {tail = "bash", 				icon = self.icons.terminal},
    {tail = "conf", 				icon = self.icons.config},
    {tail = "ini", 				icon = self.icons.config},
  }

  self.match_regex = {
    {expr = vim.regex("^Makefile$"), 		icon = self.icons.config},
    {expr = vim.regex("^fstab$"), 		icon = self.icons.config},
    {expr = vim.regex("^.git$"), 		icon = self.icons.git_dir, type = "dir"},
    {expr = vim.regex("^.gitmodules$"), 	icon = self.icons.config},
    {expr = vim.regex("^.gitignore$"), 		icon = self.icons.config},
    {expr = vim.regex("^.gitattributes$"), 	icon = self.icons.config},
  }
end
ExtIcons:setup_icons()
ExtIcons:setup_matches()

return ExtIcons
