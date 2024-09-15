-- windowEventHandler.lua
-- 提供将事件分发给window对象的方法
----------
-- 该文件属于"RFUG工作室《OpenComputer开放式电脑图形驱动程序》"开发项目的一部分
-- 作者：Water_Moon、Ying_Lan、Mirror_Flower、n507 | Author: Water_Moon、Ying_Lan、Mirror_Flower、n507
-- 许可协议：GNU GPL v3 | License: GNU GPL v3

windowEventHandler = {
  window = nil
}

-- 创建事件管理器
function windowEventHandler:new(o, _window)
  o = o or {}
  setmetatable(o, {__index = self})
  o.window = _window
  return o
end

function windowEventHandler:processEvent(...)
  if(not self.window) then return end


  local type = select(1,...)  --事件类型
  local val1 = select(2,...)  --组件地址
  local val2 = select(3,...)  --x坐标或输入字符或剪贴板
  local val3 = select(4,...)  --y坐标或输入字符代码或玩家ID
  local val4 = select(5,...)  --鼠标按键，滚轮方向或玩家ID
  local val5 = select(6,...)  --玩家ID

  if(type == "touch") then
    self.window:handleClickEvent(val1, val2, val3, val4, val5)
  elseif(type == "drag") then
    self.window:handleDragEvent(val1, val2, val3, val4, val5)
  elseif(type == "scroll") then
    self.window:handleScrollEvent(val1, val2, val3, val4, val5)
  elseif(type == "key_down") then
    self.window:handleKeyboardInput(val1, val2, val3, val4)
  elseif(type == "clipboard") then
    self.window:handleClipboard(val1, val2, val3)
  elseif(type == "component_added" or type == "component_removed") then
    self.window:setNextDrawForced()
    self.window:draw()
  end
end

return windowEventHandler
