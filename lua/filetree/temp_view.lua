local TempView = {}

function TempView:new(conf)
  local self = setmetatable({}, { __index = TempView })
  self.config = conf
  return self
end

function TempView:destroy()
  for i, map in ipairs(self.keymaps) do
    vim.keymap.del(map.modes, map.lhs, map.opts)
  end
  for i, cmd in ipairs(self.autocmds) do
    vim.api.nvim_del_autocmd(cmd.id)
  end
  self:close_window()
  vim.api.nvim_buf_delete(self.buf, {force = true})
end

function TempView:setup_buffer(lines, hls)
  self.buf = vim.api.nvim_create_buf(false, true)
  if (lines ~= nil) then
    vim.api.nvim_buf_set_lines(self.buf, 0, #lines, false, lines)
  end
  vim.api.nvim_buf_set_option(self.buf, "modifiable", false)

  if (hls ~= nil) then
    for i, hl in ipairs(hls) do
      vim.api.nvim_buf_add_highlight(self.buf, hl.ns_id, hl.hl_group, hl.line, hl.col_start, hl.col_end)
    end
  end
end

function TempView:setup_autocmds(autocmds)
  self.autocmds = {
    {
      event = "WinLeave", callback = function()
	if (vim.api.nvim_get_current_win() == self.win) then
	  self:destroy()
	end
      end 
    },
    {
      event = "QuitPre", callback = function()
	if (vim.api.nvim_get_current_win() == self.win) then
	  self:destroy()
	end
      end
    }
  }
  if (autocmds ~= nil) then
    vim.list_extend(self.autocmds, autocmds)
  end

  self.augroup = vim.api.nvim_create_augroup("filetree_preview", { clear = true })
  for i, cmd in ipairs(self.autocmds) do
    local opts = {
      group = self.augroup,
      pattern = cmd.pattern,
      callback = cmd.callback
    }
    cmd.id = vim.api.nvim_create_autocmd(cmd.event, opts)
  end
end

function TempView:setup_keymaps(keymaps)
  self.keymaps = {}
  if (self.config.quit_on_esc) then
    table.insert(self.keymaps, {
      modes = "n",
      lhs = "<Esc>",
      rhs = function() self:destroy() end,
      opts = {buffer = self.buf}})
  end
  if (keymaps ~= nil) then
    vim.list_extend(self.keymaps, keymaps)
  end

  for i, map in ipairs(self.keymaps) do
    vim.keymap.set(map.modes, map.lhs, map.rhs, map.opts)
  end
end

function TempView:open_window()
  if (self.config.type == "float") then

    local height = self.config.height
    local width = self.config.width
    local row = self.config.row
    local col = self.config.col

    if (not self.config.absolute) then
      local lines = vim.api.nvim_get_option("lines")
      local columns = vim.api.nvim_get_option("columns")
      height = math.ceil(lines * height)
      width = math.ceil(columns * width)
      row = self.config.row * (lines - height)
      col = self.config.col * (columns - width)
    end

    local opts = {
      relative = self.config.relative,
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = self.config.border
    }
    self.win = vim.api.nvim_open_win(self.buf, self.config.enter, opts)
  else
  end

  vim.api.nvim_win_set_option(self.win, "number", self.config.number)
  vim.api.nvim_win_set_option(self.win, "relativenumber", self.config.relativenumber)
end

function TempView:close_window()
  if (self.win ~= nil) then
    vim.api.nvim_win_close(self.win, true)
    self.win = nil
  end
end

return TempView
