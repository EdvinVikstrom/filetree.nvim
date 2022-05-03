local Help = {
  pkg_formats = {
    ["tar"] = {
      default_opts = "-cf <path> <files>",
      pack_fn = function(opts)
	print("packing", opts)
      end,
      valid_fn = function()
	return true
      end
    }
  }
}

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

function Help:remove_file_extension(name, ext)
  ext = (ext or Help:get_file_extension(name))
  if (ext == "") then
    return name
  end
  return string.sub(name, 1, #name - #ext - 1)
end

-- Replaces '"' with '\"' and stuff
function Help:make_path_cl_suitable(path)
  -- TODO
  return path
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

function Help:get_prefixed_size(size)
  local prefix = "B"

  -- PiB
  if (size > (2^50)) then
    prefix = "PiB"
    size = size / (2^50)
  -- TiB
  elseif (size > (2^40)) then
    prefix = "TiB"
    size = size / (2^40)
  -- GiB
  elseif (size > (2^30)) then
    prefix = "GiB"
    size = size / (2^30)
  -- MiB
  elseif (size > (2^20)) then
    prefix = "MiB"
    size = size / (2^20)
  -- KiB
  elseif (size > (2^10)) then
    prefix = "KiB"
    size = size / (2^10)
  end
  return prefix, size
end

function Help:make_string_from_list(items, callback, split)
  local str = ""
  for i, item in ipairs(items) do
    if (i ~= #items) then
      str = str..callback(item)..split
    else
      str = str..callback(item)
    end
  end
  return str
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

function Help:get_user_continue(msg)
  vim.fn.input({prompt = msg, default = "", cancelreturn = ""})
end

function Help:get_user_input(msg, def)
  local str = vim.fn.input({prompt = msg..": ", default = (def or ""), cancelreturn = ""})
  return str
end

function Help:list_available_pkg_formats()
  local formats = {}
  for key, val in pairs(Help.pkg_formats) do
    if (val.valid_fn()) then
      table.insert(formats, {key, val})
    end
  end
  return formats
end

return Help
