# A file tree plugin for Neovim written in Lua

### Example conifg file
```
-- 'init.lua'

local FileTree = require("filetree")
local filetree_conf = {
  view = {
    position = "right",
    width = 40,
    show_hidden = false,
    symbols = {
      tree_expanded = '',
      tree_closed = ''
    }
  },
  mapping = {
    wrap_cursor = true,
    close_children = true
  },
  extensions = {"icons"}
}
filetree = FileTree:new(filetree_conf)
```
