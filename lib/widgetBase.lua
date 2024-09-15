-- widgetBase.lua
-- 定义了抽象的"控件"
-- 这个类不该被直接使用，而应该被子类继承
----------
-- 该文件属于"RFUG工作室《OpenComputer开放式电脑图形驱动程序》"开发项目的一部分
-- 作者：Water_Moon、Ying_Lan、Mirror_Flower、n507 | Author: Water_Moon、Ying_Lan、Mirror_Flower、n507
-- 许可协议：GNU GPL v3 | License: GNU GPL v3

widgetBase = {
  id = 0,     -- 这个控件的ID
  window = nil,
  x = 0,
  y = 0,      -- 控件在窗口上的位置
  relativeX = 0,  -- 控件相对其上一层的位置
  relativeY = 0,
  parentX = 0,  -- 上一层控件的坐标
  parentY = 0,
  width = 0,
  height = 0, -- 控件的大小
  dirty = true, -- 是否需要重绘
  enabled = true, -- 是否启用（对于响应事件的控件来说有用）
  visible = true, -- 是否可见（不可见则不被绘制，但仍然响应事件）
  always_on_top = false,
  background = 0x000000,
  foreground = 0xffffff,  -- 背景色和前景色
  active = true, -- 是否激活（不激活=不可见且不响应事件）
  --当发生更新(self.dirty = true)时要调用什么
  --用于在组合对象中调用上一级对象的makeDirty或者类似的方法
  onUpdate = nil,
  parent = nil
}

-- 创建控件
-- 参数：继承对象，x位置，y位置，宽度，高度, 背景色，前景色
function widgetBase:new(o, x, y, width, height, bg, fg)
  o = o or {}
  setmetatable(o, {__index = self})  -- 设置对象继承widgetBase

  -- 位置和大小
  o.relativeX = x or 0
  o.relativeY = y or 0
  o.width = width or 0
  o.height = height or 0
  o.background = bg or 0x000000
  o.foreground = fg or 0xffffff


  o.x = o.parentX + o.relativeX
  o.y = o.parentY + o.relativeY

  return o
end

-- 设置该组件需要重绘
function widgetBase:makeDirty()
  self.dirty = true
  if(self.onUpdate) then
    self.onUpdate()
  end
end

function widgetBase:addParent(_parent, updateMethod)
  self.parent = _parent
  self.onUpdate = updateMethod
end

-- 该组件被销毁时执行的东西
function widgetBase:destory()
  -- 默认什么也不做
end

-- 这个组件需要被最后绘制吗（也就是在最上面）
function widgetBase:always_on_top()
  return false  --默认不是
end

-- 这个组件能被聚焦吗（也就是tab选中之类的）
function widgetBase:canBeFocused()
  return false
end

-- 设置该组件的ID - 必须存在，窗口会调用这个来分配组件ID
function widgetBase:setID(id, window)
  self.id = id
  self.window = window
end

-- 设置组件的坐标
function widgetBase:setPos(newX, newY)
  self.relativeX = newX or self.relativeX
  self.relativeY = newY or self.relativeY

  self.x = self.parentX + self.relativeX
  self.y = self.parentY + self.relativeY
  self:makeDirty()
  return self
end

-- 设置组件的上一层组件的坐标
function widgetBase:setParentPos(newX, newY)
  self.parentX = newX or self.parentX
  self.parentY = newY or self.parentY

  self.x = self.parentX + self.relativeX
  self.y = self.parentY + self.relativeY
  self:makeDirty()
  return self
end

-- 设置颜色
function widgetBase:setColor(bg, fg)
  self.background = bg or self.background
  self.foreground = fg or self.foreground
  self:makeDirty()
  return self
end

-- 设置新的大小
function widgetBase:resize(newWidth, newHeight)
  self.width = newWidth or self.width
  self.height = newHeight or self.height
  self:makeDirty()
  return self
end

function widgetBase:setEnabled(enabled)
  self.enabled = enabled
  self:makeDirty()
end

function widgetBase:setActive(active)
  self.active = active
  self:makeDirty()
end

function widgetBase:setVisible(visible)
  self.visible = visible
  self:makeDirty()
end



-- 当这个控件被点击时要做什么
function widgetBase:onClick(screenAddr, xCoord, yCoord, mouseButton, playerName)
  -- 默认什么也不做
end

-- 当这个控件被拖动时要做什么
function widgetBase:onDrag(screenAddr, xCoord, yCoord, mouseButton, playerName)
  -- 默认什么也不做
end

-- 当这个控件被鼠标滚轮滚动时要做什么
function widgetBase:onScroll(screenAddr, xCoord, yCoord, direction, playerName)
  -- 默认什么也不做
end

-- 当这个控件被聚焦时要做什么
function widgetBase:onFocused()
  -- 默认什么也不做
end

-- 当这个控件不再被聚焦时要做什么
function widgetBase:onNotFocused()
  -- 默认什么也不做
end

-- 当按键输入时要做什么
function widgetBase:onKeyboardInput(screenAddr, char, code, playerName)
  -- 默认什么也不做
end

-- 当粘贴时要做什么
function widgetBase:onClipboard(screenAddr, content, playerName)
  -- 默认什么也不做
end

-- 绘制
function widgetBase:draw(draw_gpu, force)
  if not (self.active and self.visible) then return end
  if not (self.dirty or force) then return end
  if not (draw_gpu) then return end

  draw_gpu.fill(self.x, self.y, self.width, self.height, " ")

  self.dirty = false
end

return widgetBase
