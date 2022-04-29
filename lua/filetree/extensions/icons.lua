local Extension = require("filetree.extension")
local ExtIcons = Extension:inherit()

---@param conf  table with options {option = value, ...}. |filetree-config|
---@returns ExtIcons metatable
function ExtIcons:new(conf)
  local self = setmetatable(Extension:new("icons", conf), { __index = ExtIcons })
  return self
end

function ExtIcons:setup_highlight()
  for key, icon in pairs(ExtIcons.icons) do
    local name = "filetree_icons_"..key
    if (type(icon.hl) == "string") then
      vim.cmd("hi link "..name.." "..icon.hl)
    else
      vim.cmd("hi "..name.." ctermfg="..icon.hl.fg)
    end
    icon.hl_name = name
  end
end

function ExtIcons:setup_config()
end

---@param filetree  FileTree metatable
function ExtIcons:init(filetree)
  self.render_callback = self:setup_render_callback(filetree)
  filetree.view.config.render_callback = self.render_callback
end

---@param filetree  FileTree metatable
function ExtIcons:setup_render_callback(filetree)
  return function(view, node)
    view:render_callback(node)

    local len = vim.fn.strchars(node.text)
    local off = view.width - len - 2

    local icon = ExtIcons:get_icon(node)
    local icon_off = #node.text + off
    local icon_end = icon_off + #icon.symbol
    view:add_highlight(node, 0, icon.hl_name, icon_off, icon_end)
    node.text = node.text..string.rep(" ", off)..icon.symbol
  end
end


-- ### static functions ### --

---@param node  Node metatable
---@returns table {symbol: String, hl: Table}
function ExtIcons:get_icon(node)
  for i, item in ipairs(ExtIcons.match_tail) do
    if ((item.rtype == nil or item.rtype == node.rtype) and (item.type == nil or item.type == node.type) and item.tail == node.tail) then
      return item.icon
    end
  end

  for i, item in ipairs(ExtIcons.match_regex) do
    if ((item.rtype == nil or item.rtype == node.rtype) and (item.type == nil or item.type == node.type) and item.expr:match_str(node.name)) then
      return item.icon
    end
  end

  if (node.rtype == "directory") then
    if (node.type == "link") then
      if (node.expanded) then return self.icons.link_dir_open else return self.icons.link_dir end
    else
      if (node.expanded) then return self.icons.dir_open else return self.icons.dir end
    end
  end
  return self.icons.default
end

function ExtIcons:setup_icons()
  self.icons = {
    default = 			{symbol = "", hl = "filetree_file"},
    dir = 			{symbol = "", hl = "filetree_dir"},
    dir_open = 			{symbol = "", hl = "filetree_expanded_dir"},
    link_dir = 			{symbol = "", hl = "filetree_dir"},
    link_dir_open = 		{symbol = "", hl = "filetree_expanded_dir"},
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
    {tail = "c", 				icon = self.icons.c, rtype = "file"},
    {tail = "h", 				icon = self.icons.c, rtype = "file"},
    {tail = "cpp", 				icon = self.icons.cpp, rtype = "file"},
    {tail = "hpp", 				icon = self.icons.cpp, rtype = "file"},
    {tail = "cxx", 				icon = self.icons.cpp, rtype = "file"},
    {tail = "hxx", 				icon = self.icons.cpp, rtype = "file"},
    {tail = "cc", 				icon = self.icons.cpp, rtype = "file"},
    {tail = "hh", 				icon = self.icons.cpp, rtype = "file"},
    {tail = "vim", 				icon = self.icons.vim, rtype = "file"},
    {tail = "nvim", 				icon = self.icons.vim, rtype = "file"},
    {tail = "lua", 				icon = self.icons.lua, rtype = "file"},
    {tail = "html", 				icon = self.icons.html, rtype = "file"},
    {tail = "htm", 				icon = self.icons.html, rtype = "file"},
    {tail = "java", 				icon = self.icons.java, rtype = "file"},
    {tail = "class", 				icon = self.icons.java, rtype = "file"},
    {tail = "js", 				icon = self.icons.javascript, rtype = "file"},
    {tail = "md", 				icon = self.icons.markdown, rtype = "file"},
    {tail = "py", 				icon = self.icons.python, rtype = "file"},
    {tail = "rb", 				icon = self.icons.ruby, rtype = "file"},
    {tail = "rs", 				icon = self.icons.rust, rtype = "file"},
    {tail = "sh", 				icon = self.icons.terminal, rtype = "file"},
    {tail = "zsh", 				icon = self.icons.terminal, rtype = "file"},
    {tail = "bash", 				icon = self.icons.terminal, rtype = "file"},
    {tail = "conf", 				icon = self.icons.config, rtype = "file"},
    {tail = "ini", 				icon = self.icons.config, rtype = "file"},
  }

  self.match_regex = {
    {expr = vim.regex("^Makefile$"), 		icon = self.icons.config, rtype = "file"},
    {expr = vim.regex("^fstab$"), 		icon = self.icons.config, rtype = "file"},
    {expr = vim.regex("^.git$"), 		icon = self.icons.git_dir, type = "directory"},
    {expr = vim.regex("^.gitmodules$"), 	icon = self.icons.config, rtype = "file"},
    {expr = vim.regex("^.gitignore$"), 		icon = self.icons.config, rtype = "file"},
    {expr = vim.regex("^.gitattributes$"), 	icon = self.icons.config, rtype = "file"},
  }
end
ExtIcons:setup_icons()
ExtIcons:setup_matches()

return ExtIcons
