# A file tree plugin for Neovim written in Lua
Requires Neovim 0.7+

### Example conifg file
```
local FileTree = require("filetree")
local Mapping = FileTree.Mapping
FileTree:setup({

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
    close_children = true,
    keymaps = {
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
      ["<Esc>"] = Mapping:clear()
    }
  },

  extensions = {"icons"}

})
vim.cmd("FTreeOpen")
```
