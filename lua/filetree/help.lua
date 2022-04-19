local Help = {}

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

function Help:copy_file(src, dst)
  -- TODO: better copy
  local content = vim.fn.readfile(src, "b")
  vim.fn.writefile(content, dst, "b")
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

return Help
