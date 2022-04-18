local NodeView = {}

local Node = require("filetree.node")

-- params: {node: Node}
-- return: NodeView
function NodeView:new(node)
  local self = setmetatable({}, { __index = NodeView })
  self.node = node
  return self
end

-- params: {conf: Table}
-- return: String
function NodeView:render(conf)
  local head = "- "
  if (self.node.rtype == "dir") then
    if (self.node.expanded) then
      head = conf.symbols.tree_expanded.." "
      self.text = head..self.node.name..'/'
    else
      head = conf.symbols.tree_closed.." "
      self.text = head..self.node.name..'/'
    end
  elseif (self.node.rtype == "link") then
    self.text = head..self.node.name.."@"
  elseif (self.node.rtype == "bdev") then
    self.text = head..self.node.name.."#"
  elseif (self.node.rtype == "cdev") then
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

-- params: {namespace: Number, group: String, first: Number, last: Number}
function NodeView:add_highlight(namespace, group, first, last)
  table.insert(self.hl, {namespace = namespace, group = group, first = first, last = last})
end

function NodeView:clear()
  self.text = ""
  self.line = ""
  self.hl = {}
end

-- return: String
function NodeView:get_text()
  return self.text
end

return NodeView
