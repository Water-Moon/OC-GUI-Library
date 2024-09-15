-- widgetButton.lua
-- "按钮" 控件，显示文本并响应点击事件
----------
-- 该文件属于"RFUG工作室《OpenComputer开放式电脑图形驱动程序》"开发项目的一部分
-- 作者：Water_Moon、Ying_Lan、Mirror_Flower、n507 | Author: Water_Moon、Ying_Lan、Mirror_Flower、n507
-- 许可协议：GNU GPL v3 | License: GNU GPL v3

local widgetBase = require("widgetBase")
local stringutils = require("stringutils")

widgetButton = {
  text = "",
  callBack = nil
}

setmetatable(widgetButton, {__index = widgetBase})

-- 创建新的按钮
-- 按钮默认使用反色的背景色以便标识按钮区域
function widgetButton:new(o, text, callback, x, y, width, height, bg, fg)
  o = o or {}
  bg = bg or 0xffffff
  fg = fg or 0x000000
  o = widgetBase:new(o, x, y, width, height, bg, fg)
  setmetatable(o, {__index = self})

  o.text = text
  o.callBack = callback
  return o
end

function widgetButton:setCallback(cbfun)
  self.callBack = cbfun
  self:makeDirty()
  return self
end

function widgetButton:setText(new_text)
  self.text = new_text
  self:makeDirty()
  return self
end

function widgetButton:draw(draw_gpu, force)
  if not (self.active and self.visible) then return end
  if not (self.dirty or force) then return end
  if not (draw_gpu) then return end

  local oldForeground = draw_gpu.getForeground()
  local oldBackground = draw_gpu.getBackground()

	draw_gpu.setForeground(self.foreground)
	draw_gpu.setBackground(self.background)

  --填充背景
  draw_gpu.fill(self.x,self.y,self.width,self.height, " ")

  --绘制文字
  local tmpText = self.text
  if(string.len(tmpText) > self.width) then
    tmpText = string.sub(tmpText, 1, self.width) -- 如果字符串太长就裁剪它可以显示的部分
  end
  local textX = stringutils.getBeginX(self.text, self.width, self.x)
  local textY = self.y + math.floor(self.height / 2) -- 居中
  draw_gpu.set(textX, textY, tmpText)

  draw_gpu.setBackground(oldBackground)
  draw_gpu.setForeground(oldForeground)
  self.dirty = false
end

function widgetButton:onClick(screenAddr, xCoord, yCoord, mouseButton, playerName)
  if(not self.callBack) then return end
  if not(self.enabled and self.active) then return end
  if((xCoord < self.x) or (xCoord > (self.x + self.width - 1))) then return end
  if((yCoord < self.y) or (yCoord > (self.y + self.height - 1))) then return end
  self.callBack(screenAddr, xCoord, yCoord, mouseButton, playerName)
  self:makeDirty()
end

return widgetButton
