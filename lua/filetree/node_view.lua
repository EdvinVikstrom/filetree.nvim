local NodeView = {}

local Node = require("filetree.node")

---@param node  Node metatable
---@returns NodeView metatable
function NodeView:new(node)
  local self = setmetatable({}, { __index = NodeView })
  self.node = node
  return self
end

---@param conf  table with options {option = value, ...}. |filetree-config|
---@returns string
function NodeView:render(conf)
  local head = "- "
  if (self.node.rtype == "directory") then
    if (self.node.expanded) then
      head = conf.symbols.tree_expanded.." "
      self.text = head..self.node.name..'/'
    else
      head = conf.symbols.tree_closed.." "
      self.text = head..self.node.name..'/'
    end
  elseif (self.node.rtype == "link") then
    self.text = head..self.node.name.."@"
  elseif (self.node.rtype == "block") then
    self.text = head..self.node.name.."#"
  elseif (self.node.rtype == "char") then
    self.text = head..self.node.name.."%"
  elseif (self.node.rtype == "socket") then
    self.text = head..self.node.name.."="
  elseif (self.node.rtype == "fifo") then
    self.text = head..self.node.name.."|"
  else
    self.text = head..self.node.name
  end
  if (self.node.marked) then
    self.text = self.text.." *"
  end

  self.name_offset = #head
  return self.text
end

---@param namespace  highlight namespace
---@param group  highlight group name
---@param first  first column
---@param last  last column
function NodeView:add_highlight(namespace, group, first, last)
  table.insert(self.hl, {namespace = namespace, group = group, first = first, last = last})
end

function NodeView:clear()
  self.text = ""
  self.line = ""
  self.hl = {}
end

---@returns string
function NodeView:get_text()
  return self.text
end

return NodeView
