local Help = {}

-- params: {path: String, name: String}
-- return: String
function Help:make_path(path, name)
  if (vim.endswith(path, "/")) then
    return path..name
  end
  return path.."/"..name
end

-- params: {path: String}
-- return: String
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

-- params: {path: String}
-- return: String
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

-- params: {path: String}
-- return: Boolean
function Help:file_exists(path)
  return not(vim.fn.getftype(path) == "")
end

-- params: {msg: String, def: Boolean}
-- return: Boolean
-- NOTE: if def is true then default is 'yes', otherwise 'no'
function Help:get_user_yesno(msg, def)
  if (def) then
    msg = msg.." [Y/n]"
  else
    msg = msg.." [y/N]"
  end
  local str = vim.fn.input({prompt = msg, default = "", cancelreturn = ""})
  if (vim.stricmp(str, "y") == 0 or vim.stricmp(str, "yes") == 0) then
    return true
  elseif (vim.stricmp(str, "n") == 0 or vim.stricmp(str, "no") == 0) then
    return false
  end
  return def
end

-- params: {msg: String, def: String}
function Help:get_user_input(msg, def)
  local str = vim.fn.input({prompt = msg..": ", default = (def or ""), cancelreturn = ""})
  return str
end

return Help
