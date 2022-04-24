local Help = {sl_stack = {}}

function Help:make_path(path, name)
  if (vim.endswith(path, "/")) then
    return path..name
  end
  return path.."/"..name
end

function Help:get_file_name(path)
  local index = #path - 1

  while (index > 0) do
    if (string.sub(path, index, index) == '/') then
      break
    end

    index = index - 1
  end

  return string.sub(path, index + 1)
end

function Help:get_file_extension(name)
  local index = #name - 1

  while (index > 1) do
    if (string.sub(name, index, index) == '.') then
      break
    end

    index = index - 1
  end

  if (index == 1) then
    return ""
  end

  return string.sub(name, index + 1)
end

function Help:get_file_parent(path)
  local index = #path - 1

  while (index > 0) do
    if (string.sub(path, index, index) == '/') then
      break
    end

    index = index - 1
  end

  if (index <= 1) then
    return "/"
  end
  return string.sub(path, 0, index - 1)
end

function Help:file_exists(path)
  return not(vim.fn.getftype(path) == "")
end

function Help:get_file_type(path)
  -- TODO
  local type = vim.fn.getftype(path)
  if (type == "dir") then
    return "directory"
  elseif (type == "bdev") then
    return "block"
  elseif (type == "cdev") then
    return "char"
  end
  return type
end

function Help:read_directory(path)
  local dir, err, err_name = vim.loop.fs_opendir(path, nil, 4000)
  if (err ~= nil) then
    print("failed to open directory:", err)
    return nil
  end

  local files, err, err_name = vim.loop.fs_readdir(dir)
  if (err ~= nil) then
    print("failed to read directory:", err)
    return nil
  end

  vim.loop.fs_closedir(dir)
  return files
end

-- NOTE: if def is true then default is 'yes', otherwise 'no'
function Help:get_user_yesno(msg, def)
  if (def) then
    msg = msg.." [Y/n] "
  else
    msg = msg.." [y/N] "
  end
  local str = vim.fn.input({prompt = msg, default = "", cancelreturn = ""})
  if (vim.stricmp(str, "y") == 0 or vim.stricmp(str, "yes") == 0) then
    return true
  elseif (vim.stricmp(str, "n") == 0 or vim.stricmp(str, "no") == 0) then
    return false
  end
  return def
end

function Help:get_user_input(msg, def)
  local str = vim.fn.input({prompt = msg..": ", default = (def or ""), cancelreturn = ""})
  return str
end

function Help:push_status_line(win, line)
  local self = Help
  local old_line = vim.api.nvim_win_get_option(win, "statusline")
  table.insert(self.sl_stack, {win = win, line = old_line})
  vim.api.nvim_win_set_option(win, "statusline", line)
end

function Help:pop_status_line(win)
  local self = Help
  local index = 0
  for i, item in ipairs(self.sl_stack) do
    if (item.win == win) then
      index = i
      break
    end
  end

  if (index == 0) then
    return
  end

  vim.api.nvim_win_set_option(win, "statusline", self.sl_stack[index].line)
  table.remove(self.sl_stack, index)
end

function Help:pop_status_lines()
  local self = Help
  for i, item in ipairs(self.sl_stack) do
    vim.api.nvim_win_set_option(item.win, "statusline", item.line)
  end
  self.sl_stack = {}
end

return Help
