local Config = {}

local Mapping = require("filetree.mapping")

function Config:new(conf)
  local self = setmetatable({}, { __index = Config })
  self.config = conf
  return self
end

function Config:setup()
  local conf = self.config

  conf.directory = (conf.directory or vim.fn.getcwd())

  -- Highlight
  conf.highlight = (conf.highlight or {})
  do
    local highlight = conf.highlight
    highlight.dir = (highlight.dir or {ctermfg = 223})
    highlight.dir_expanded = (highlight.dir_expanded or {ctermfg = 208})
    highlight.file = (highlight.file or {ctermfg = 246})
    highlight.indent = (highlight.indent or {ctermfg = "white"})
    highlight.fi_key_path = (highlight.fi_key_path or {ctermfg = "white"})
    highlight.fi_key_name = (highlight.fi_key_name or highlight.fi_key_path)
    highlight.fi_key_type = (highlight.fi_key_type or highlight.fi_key_path)
    highlight.fi_key_size = (highlight.fi_key_size or highlight.fi_key_path)
    highlight.fi_key_perm = (highlight.fi_key_perm or highlight.fi_key_path)
    highlight.fi_key_created = (highlight.fi_key_created or highlight.fi_key_path)
    highlight.fi_key_modified = (highlight.fi_key_modified or highlight.fi_key_path)
    highlight.fi_key_readable = (highlight.fi_key_readable or highlight.fi_key_path)
    highlight.fi_key_writable = (highlight.fi_key_writable or highlight.fi_key_path)
    highlight.fi_key_link = (highlight.fi_key_link or highlight.fi_key_path)
    highlight.fi_path = (highlight.fi_path or {ctermfg = "white"})
    highlight.fi_name = (highlight.fi_name or highlight.fi_path)
    highlight.fi_type = (highlight.fi_type or highlight.fi_path)
    highlight.fi_size = (highlight.fi_size or highlight.fi_path)
    highlight.fi_perm = (highlight.fi_perm or highlight.fi_path)
    highlight.fi_created = (highlight.fi_created or highlight.fi_path)
    highlight.fi_modified = (highlight.fi_modified or highlight.fi_path)
    highlight.fi_readable = (highlight.fi_readable or highlight.fi_path)
    highlight.fi_writable = (highlight.fi_writable or highlight.fi_path)
    highlight.fi_link = (highlight.fi_link or highlight.fi_path)
  end

  -- View
  conf.view = (conf.view or {})
  do
    local view = conf.view
    view.cursor_offset = (view.cursor_offset or 0) -- don't touch
    view.position = (view.position or "left")
    view.width = (view.width or 30)
    view.height = (view.height or 30)
    view.indent = (view.indent or 2)
    view.line_width = (view.line_width or 6)
    if (view.show_dot_files == nil) then view.show_dot_files = false end
    if (view.debug == nil) then view.debug = false end
    view.render_callback = (view.render_callback or nil)

    view.indent_markers = (view.indent_markers or {})
    if (view.indent_markers.enable == nil) then view.indent_markers.enable = false end
    view.indent_markers.hl = (view.indent_markers.hl or "filetree_indent")
    view.indent_markers.symbols = (view.indent_markers.symbols or {})
    view.indent_markers.symbols.edge = (view.indent_markers.symbols.edge or "│")
    view.indent_markers.symbols.corner = (view.indent_markers.symbols.corner or "└")

    -- File symbols
    view.file_symbols = (view.file_symbols or {})
    do
      local symbols = view.file_symbols
      symbols.__default = {symbol = "", hlns = 0, hlg = ""}
      symbols.dir = (symbols.dir or {symbol = "", hlg = "filetree_dir"})
      symbols.dir_expanded = (symbols.dire or {symbol = "", hlg = "filetree_dir_expanded"})
      symbols.link_dir = (symbols.link_dir or symbols.dir)
      symbols.link_dir_expanded = (symbols.link_dir_expanded or symbols.dir_expanded)
      symbols.file = (symbols.file or {symbol = "", hlg = "filetree_file"})
      symbols.link = (symbols.link or symbols.file)
      symbols.block = (symbols.block or symbols.file)
      symbols.char = (symbols.char or symbols.file)
      symbols.socket = (symbols.socket or symbols.file)
      symbols.fifo = (symbols.fifo or symbols.file)
    end

    -- File names
    view.file_names = (view.file_names or {})
    do
      local names = view.file_names
      names.__default = {suffix = "", hlg = ""}
      names.dir = (names.dir or {suffix = "/", hlg = "filetree_dir"})
      names.dir_expanded = (names.dire or {suffix = "/", hlg = "filetree_dir_expanded"})
      names.link_dir = (names.link_dir or names.dir)
      names.link_dir_expanded = (names.link_dir_expanded or names.dir_expanded)
      names.file = (names.file or {suffix = "", hlg = "filetree_file"})
      names.link = (names.link or {suffix = "@", hlg = "filetree_file"})
      names.block = (names.block or {suffix = "#", hlg = "filetree_file"})
      names.char = (names.char or {suffix = "%", hlg = "filetree_file"})
      names.socket = (names.socket or {suffix = "=", hlg = "filetree_file"})
      names.fifo = (names.fifo or {suffix = "|", hlg = "filetree_file"})
    end

    -- File exts
    view.file_exts = (view.file_exts or {})
    do
      local exts = view.file_exts
      exts.__default = {symbol = "", hlns = 0, hlg = ""}
      exts.dir = (exts.dir or nil)
      exts.dir_expanded = (exts.dir_expanded or nil)
      exts.link_dir = (exts.link_dir or exts.dir)
      exts.link_dir_expanded = (exts.link_dir_expanded or exts.dir_expanded)
      exts.file = (exts.file or nil)
      exts.link = (exts.link or exts.file)
      exts.block = (exts.block or exts.file)
      exts.char = (exts.char or exts.file)
      exts.socket = (exts.socket or exts.file)
      exts.fifo = (exts.fifo or exts.file)
    end
  end

  -- Mapping
  conf.mapping = (conf.mapping or {})
  do
    local mapping = conf.mapping
    if (mapping.wrap_cursor == nil) then mapping.wrap_cursor = false end
    if (mapping.close_children == nil) then mapping.close_children = true end
    mapping.yank_file_names = (mapping.yank_file_names or "path")
    mapping.keymaps = (mapping.keymaps or Mapping.default_keymaps)
  end

  conf.file_info_view = (conf.file_info_view or {})
  do
    local file_info_view = conf.file_info_view
    --file_info_view.position = (file_info_view.position or "vertical")
    file_info_view.content = (file_info_view.content or {
      {
	key = "path",
	prefix = {text = "Path", hlg = "filetree_fi_key_path"},
	hlg = "filetree_fi_path",
	resolved = true
      }, {
	key = "name",
	prefix = {text = "Name", hlg = "filetree_fi_key_name"},
	hlg = "filetree_fi_name"
      }, {
	key = "type",
	prefix = {text = "Type", hlg = "filetree_fi_key_type"},
	types = {
	  ["file"] = "File",
	  ["directory"] = "Directory",
	  ["link"] = "Symbolic link",
	  ["block"] = "Block device",
	  ["char"] = "Char device",
	  ["socket"] = "Socket",
	  ["fifo"] = "FIFO"
	},
	hlg = "filetree_fi_type"
      }, {
	key = "size",
	prefix = {text = "Size", hlg = "filetree_fi_key_size"},
	fmt = "%.1f %s",
	hlg = "filetree_fi_size",
	resolved = true
      }, {
	key = "perm",
	prefix = {text = "Permissions", hlg = "filetree_fi_key_perm"},
	hlg = "filetree_fi_perm"
      }, {
	key = "created",
	prefix = {text = "Created", hlg = "filetree_fi_key_created"},
	fmt = "%Y %b %d %X",
	hlg = "filetree_fi_created"
      }, {
	key = "modified",
	prefix = {text = "Modified", hlg = "filetree_fi_key_modified"},
	fmt = "%Y %b %d %X",
	hlg = "filetree_fi_modified"
      }, {
	key = "readable",
	prefix = {text = "Readable", hlg = "filetree_fi_key_readable"},
	hlg = "filetree_fi_readable"
      }, {
	key = "writable",
	prefix = {text = "Writable", hlg = "filetree_fi_key_writable"},
	hlg = "filetree_fi_writable"
      }, {
	key = "link",
	prefix = {text = "Link", hlg = "filetree_fi_key_link"},
	hlg = "filetree_fi_link"
      }
    })
  end

  -- File preview
  conf.file_preview = (conf.file_preview or {})
  do
    local file_preview = conf.file_preview
    if (file_preview.quit_on_esc == nil) then file_preview.quit_on_esc = true end
    file_preview.type = (file_preview.type or "float")
    file_preview.relative = (file_preview.relative or "editor")
    if (file_preview.absolute == nil) then file_preview.absolute = false end
    if (file_preview.absolute) then
      file_preview.width = (file_preview.width or 100)
      file_preview.height = (file_preview.height or 40)
      file_preview.row = (file_preview.row or 20)
      file_preview.col = (file_preview.col or 20)
    else
      file_preview.width = (file_preview.width or 0.9)
      file_preview.height = (file_preview.height or 0.7)
      file_preview.row = (file_preview.row or 0.5)
      file_preview.col = (file_preview.col or 0.5)
    end
    file_preview.border = (file_preview.border or "single")
    if (file_preview.number == nil) then file_preview.number = true end
    if (file_preview.relativenumber == nil) then file_preview.relativenumber = true end
  end

  -- Filters
  conf.filters = (conf.filters or {})
  do
    local filters = conf.filters
    filters.callback = (filters.callback or nil)
    filters.exclude = (filters.exclude or {})
    if (filters.exclude.dot_files == nil) then filters.exclude.dot_files = false end
    filters.exclude.pattern = (filters.exclude.pattern or "")
  end

  conf.actions = (conf.actions or {})
  local actions = conf.actions

  -- Action sort nodes
  actions.sort_nodes = (actions.sort_nodes or {})
  do
    local sort_nodes = actions.sort_nodes
    sort_nodes.callback = (sort_nodes.callback or nil)
    sort_nodes.method = (sort_nodes.method or "name")
    sort_nodes.directories = (sort_nodes.directories or "top")
    if (sort_nodes.reverse == nil) then sort_nodes.reverse = false end
  end

  -- Action root changed
  actions.root_changed = (actions.root_changed or {})
  do
    local root_changed = actions.root_changed
    root_changed.callback = (root_changed.callback or nil)
    if (root_changed.change_cwd == nil) then root_changed.change_cwd = false end
  end

  -- Action open file
  actions.open_file = (actions.open_file or {})
  do
    local open_file = actions.open_file
    open_file.callback = (open_file.callback or nil)
    if (open_file.quit_tree == nil) then open_file.quit_tree = false end
    open_file.window_picker = (open_file.window_picker or {})

    local wp = open_file.window_picker
    if (wp.enable == nil) then wp.enable = true end
    wp.ids = (wp.ids or "aoeuhtns")
    wp.exclude = (wp.exclude or {})
    if (wp.exclude.self == nil) then wp.exclude.self = true end
    wp.exclude.buftypes = (wp.exclude.buftypes or {"nofile", "help"})
    wp.exclude.bufnames = (wp.exclude.bufnames or {})
    wp.suitable_callback = (wp.suitable_callback or nil)
  end

  -- Action read file
  actions.read_file = (actions.read_file or {})
  do
    local read_file = actions.read_file
    read_file.callback = (read_file.callback or nil)
  end

  -- Action read directory
  actions.read_directory = (actions.read_directory or {})
  do
    local read_directory = actions.read_directory
    read_directory.callback = (read_directory.callback or nil)
  end

  -- Action make file
  actions.make_file = (actions.make_file or {})
  do
    local make_file = actions.make_file
    make_file.callback = (make_file.callback or nil)
  end

  -- Action make directory
  actions.make_directory = (actions.make_directory or {})
  do
    local make_directory = actions.make_directory
    make_directory.callback = (make_directory.callback or nil)
  end

  -- Action copy file
  actions.copy_file = (actions.copy_file or {})
  do
    local copy_file = actions.copy_file
    copy_file.callback = (copy_file.callback or nil)
  end

  -- Action move file
  actions.move_file = (actions.move_file or {})
  do
    local move_file = actions.move_file
    move_file.callback = (move_file.callback or nil)
  end
  
  -- Action remove file
  actions.remove_file = (actions.remove_file or {})
  do
    local remove_file = actions.remove_file
    remove_file.callback = (remove_file.callback or nil)
  end
end

function Config:validate()
  local conf = self.config

  local tassert = function(val, val_type, name)
    assert(type(val) == val_type, "'"..name.."' must be a "..val_type.." ("..type(val)..")")
  end

  local ttassert = function(val, val_type1, val_type2, name)
    assert(type(val) == val_type1 or type(val) == val_type2, "'"..name.."' must be a "..val_type1.." or a "..val_type2.." ("..type(val)..")")
  end

  local tnassert = function(val, val_type, name)
    assert(type(val) == val_type or val == nil, "'"..name.."' must be nil or a "..val_type.." ("..type(val)..")")
  end

  local sassert = function(val, strs, name)
    local valid = false
    for i, str in ipairs(strs) do
      if (str == val) then
	valid = true
	break
      end
    end

    assert(valid, "'"..name.."' invalid option \""..val.."\". See |filetree-config."..name.."|")
  end

  local nassert = function(val, min, max, name)
    assert(val >= min and val <= max, "'"..name.."' value out of range (min: "..min..", max: "..max..")")
  end

  tassert(conf.directory, "string", "directory")

  -- View
  do
    local view = conf.view
    tassert(view, "table", "view")

    tassert(view.cursor_offset, "number", "view.cursor_offset")
    tassert(view.position, "string", "view.position")
    sassert(view.position, {"left", "right"}, "view.position")
    tassert(view.width, "number", "view.width")
    nassert(view.width, 1, 99999, "view.width")
    tassert(view.height, "number", "view.height")
    nassert(view.height, 1, 99999, "view.height")
    tassert(view.line_width, "number", "view.line_width")
    nassert(view.line_width, 0, 99999, "view.line_width")
    tassert(view.indent, "number", "view.indent")
    nassert(view.indent, 0, 99999, "view.indent")
    tassert(view.show_dot_files, "boolean", "view.show_dot_files")
    tassert(view.debug, "boolean", "view.debug")
    tnassert(view.render_callback, "function", "view.render_callback")

    tassert(view.indent_markers, "table", "view.indent_markers")
    tassert(view.indent_markers.enable, "boolean", "view.indent_markers.enable")
    ttassert(view.indent_markers.hl, "table", "string", "view.indent_markers.hl")
    if (type(view.indent_markers.hl) == "string") then
      view.indent_markers.hl = {group = view.indent_markers.hl}
    end
    view.indent_markers.hl.ns = (view.indent_markers.hl.ns or 0)
    tassert(view.indent_markers.hl.ns, "number", "view.indent_markers.hl.ns")
    tassert(view.indent_markers.hl.group, "string", "view.indent_markers.hl.group")
    tassert(view.indent_markers.symbols, "table", "view.indent_markers.symbols")
    tassert(view.indent_markers.symbols.edge, "string", "view.indent_markers.symbols.edge")
    tassert(view.indent_markers.symbols.corner, "string", "view.indent_markers.symbols.corner")

    tassert(view.file_symbols, "table", "view.file_symbols")
    for key, sym in pairs(view.file_symbols) do
      ttassert(sym, "table", "string", "view.file_symbols."..key)
      if (type(sym) == "string") then
	sym = {symbol = sym}
	view.file_symbols[key] = sym
      end
      sym.symbol = (sym.symbol or "")
      sym.hlns = (sym.hlns or 0)
      sym.hlg = (sym.hlg or "")
      tassert(sym.symbol, "string", "view.file_symbols."..key..".symbol")
      tassert(sym.hlns, "number", "view.file_symbols."..key..".hlns")
      tassert(sym.hlg, "string", "view.file_symbols."..key..".hlg")
    end

    tassert(view.file_names, "table", "view.file_names")
    for key, name in pairs(view.file_names) do
      tassert(name, "table", "view.file_names."..key)
      name.prefix = (name.prefix or "")
      name.suffix = (name.suffix or "")
      name.hlns = (name.hlns or 0)
      name.hlg = (name.hlg or "")
      tassert(name.prefix, "string", "view.file_names."..key..".prefix")
      tassert(name.suffix, "string", "view.file_names."..key..".suffix")
      tassert(name.hlns, "number", "view.file_names."..key..".hlns")
      tassert(name.hlg, "string", "view.file_names."..key..".hlg")
    end

    tassert(view.file_exts, "table", "view.file_exts")
    for key, ext in pairs(view.file_exts) do
      ttassert(ext, "table", "string", "view.file_exts."..key)
      if (type(ext) == "string") then
	ext = {symbol = ext}
	view.file_exts[key] = key
      end
      ext.symbol = (ext.symbol or "")
      ext.hlns = (ext.hlns or 0)
      ext.hlg = (ext.hlg or "")
      tassert(ext.symbol, "string", "view.file_exts."..key..".symbol")
      tassert(ext.hlns, "number", "view.file_exts."..key..".hlns")
      tassert(ext.hlg, "string", "view.file_exts."..key..".hlg")
    end
  end

  -- Mapping
  do
    local mapping = conf.mapping
    tassert(mapping, "table", "mapping")

    tassert(mapping.wrap_cursor, "boolean", "mapping.wrap_cursor")
    tassert(mapping.close_children, "boolean", "mapping.close_children")
    tassert(mapping.yank_file_names, "string", "mapping.yank_file_names")
    sassert(mapping.yank_file_names, {"none", "path", "name"}, "mapping.yank_file_names")
  end

  -- File info
  do
    local file_info_view = conf.file_info_view
    tassert(file_info_view, "table", "file_info_view")

    --tassert(file_info_view.position, "string")

    for i, info in ipairs(file_info_view.content) do
      tnassert(info.callback, "function", "file_info_view.content["..i.."].callback")
      if (info.callback ~= nil) then
	tassert(info.key, "string", "file_info_view.content["..i.."].key")
	info.prefix = (info.prefix or {})
	info.prefix.text = (info.prefix.text or "")
	info.prefix.hlns = (info.prefix.hlns or 0)
	info.prefix.hlg = (info.prefix.hlg or "")
	tassert(info.prefix, "table", "file_info_view.content["..i.."].prefix")
	tassert(info.prefix.text, "string", "file_info_view.content["..i.."].prefix.text")
	tassert(info.prefix.hlns, "number", "file_info_view.content["..i.."].prefix.hlns")
	tassert(info.prefix.hlg, "string", "file_info_view.content["..i.."].prefix.hlg")
	info.fmt = (info.fmt or "")
	info.hlns = (info.hlns or 0)
	info.hlg = (info.hlg or "")
	if (info.resolved == nil) then info.resolved = false end
	tassert(info.fmt, "string", "file_info_view.content["..i.."].fmt")
	tassert(info.hlns, "number", "file_info_view.content["..i.."].hlns")
	tassert(info.hlg, "string", "file_info_view.content["..i.."].hlg")
	tassert(info.resolved, "boolean", "file_info_view.content["..i.."].resolved")
      end
    end
  end

  -- File preview
  do
    local file_preview = conf.file_preview
    tassert(file_preview, "table", "file_preview")

    tassert(file_preview.quit_on_esc, "boolean", "file_preview.quit_on_esc")
    tassert(file_preview.type, "string", "file_preview.type")
    sassert(file_preview.type, {"float", "normal"}, "file_preview.type")
    tassert(file_preview.relative, "string", "file_preview.relative")
    tassert(file_preview.absolute, "boolean", "file_preview.absolute")
    tassert(file_preview.width, "number", "file_preview.width")
    tassert(file_preview.height, "number", "file_preview.height")
    tassert(file_preview.row, "number", "file_preview.row")
    tassert(file_preview.col, "number", "file_preview.col")
    if (file_preview.absolute) then
      nassert(file_preview.width, 1, 99999, "file_preview.width")
      nassert(file_preview.height, 1, 99999, "file_preview.height")
      nassert(file_preview.row, 0, 99999, "file_preview.row")
      nassert(file_preview.col, 0, 99999, "file_preview.col")
    else
      nassert(file_preview.width, 0, 1, "file_preview.width")
      nassert(file_preview.height, 0, 1, "file_preview.height")
      nassert(file_preview.row, 0, 1, "file_preview.row")
      nassert(file_preview.col, 0, 1, "file_preview.col")
    end

    ttassert(file_preview.border, "string", "table", "file_preview.border")
    tassert(file_preview.number, "boolean", "file_preview.number")
    tassert(file_preview.relativenumber, "boolean", "file_preview.relativenumber")
  end

  -- Filters
  do
    local filters = conf.filters
    tassert(filters, "table", "filters")

    tnassert(filters.callback, "function", "filters.callback")
    tassert(filters.exclude, "table", "filters.exclude")
    tassert(filters.exclude.dot_files, "boolean", "filters.exclude.dot_files")
    tassert(filters.exclude.pattern, "string", "filters.exclude.pattern")
    if (filters.exclude.pattern == "") then
      filters.exclude.pattern = nil
    else
      filters.exclude.pattern = vim.regex(filters.exclude.pattern)
    end
  end

  tassert(conf.actions, "table", "actions")

  -- Action sort files
  do
    local sort_nodes = conf.actions.sort_nodes
    tassert(sort_nodes, "table", "actions.sort_nodes")

    tnassert(sort_nodes.callback, "function", "actions.sort_nodes.callback")
    tassert(sort_nodes.method, "string", "actions.sort_nodes.method")
    sassert(sort_nodes.method, {"none", "name", "name_cs", "type", "rtype", "size", "rsize", "modified"}, "actions.sort_nodes.method")
    tassert(sort_nodes.directories, "string", "actions.sort_nodes.directories")
    sassert(sort_nodes.directories, {"none", "top", "bottom"}, "actions.sort_nodes.directories")
    tassert(sort_nodes.reverse, "boolean", "actions.sort_nodes.reverse")
  end

  -- Action root changed
  do
    local root_changed = conf.actions.root_changed
    tassert(root_changed, "table", "actions.root_changed")

    tnassert(root_changed.callback, "function", "actions.root_changed.callback")
    tassert(root_changed.change_cwd, "boolean", "actions.root_changed.change_cwd")
  end

  -- Action open file
  do
    local open_file = conf.actions.open_file
    tassert(open_file, "table", "actions.open_file")

    tnassert(open_file.callback, "function", "actions.open_file.callback")
    tassert(open_file.quit_tree, "boolean", "actions.open_file.quit_tree")
    tassert(open_file.window_picker, "table", "actions.open_file.window_picker")
    tassert(open_file.window_picker.enable, "boolean", "actions.open_file.window_picker.enable")
    tassert(open_file.window_picker.ids, "string", "actions.open_file.window_picker.ids")
    tassert(open_file.window_picker.exclude, "table", "actions.open_file.window_picker.exclude")
    tassert(open_file.window_picker.exclude.self, "boolean", "actions.open_file.window_picker.exclude.self")
    tassert(open_file.window_picker.exclude.buftypes, "table", "actions.open_file.window_picker.exclude.buftypes")
    tassert(open_file.window_picker.exclude.bufnames, "table", "actions.open_file.window_picker.exclude.bufnames")
    tnassert(open_file.window_picker.suitable_callback, "function", "actions.open_file.window_picker.suitable_callback")
  end

  -- Action read file
  do
    local read_file = conf.actions.read_file
    tassert(read_file, "table", "actions.read_file")

    tnassert(read_file.callback, "function", "actions.read_file.callback")
  end

  -- Action read directory
  do
    local read_directory = conf.actions.read_directory
    tassert(read_directory, "table", "actions.read_directory")

    tnassert(read_directory.callback, "function", "actions.read_directory.callback")
  end

  -- Action make file
  do
    local make_file = conf.actions.make_file
    tassert(make_file, "table", "actions.make_file")

    tnassert(make_file.callback, "function", "actions.make_file.callback")
  end

  -- Action make directory
  do
    local make_directory = conf.actions.make_directory
    tassert(make_directory, "table", "actions.make_directory")

    tnassert(make_directory.callback, "function", "actions.make_directory.callback")
  end

  -- Action copy file
  do
    local copy_file = conf.actions.copy_file
    tassert(copy_file, "table", "actions.copy_file")

    tnassert(copy_file.callback, "function", "actions.copy_file.callback")
  end

  -- Action move file
  do
    local move_file = conf.actions.move_file
    tassert(move_file, "table", "actions.move_file")

    tnassert(move_file.callback, "function", "actions.move_file.callback")
  end

  -- Action remove file
  do
    local remove_file = conf.actions.remove_file
    tassert(remove_file, "table", "actions.remove_file")

    tnassert(remove_file.callback, "function", "actions.remove_file.callback")
  end
end

return Config
