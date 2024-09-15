-- widgetLabel.lua
-- "标签"控件，用来显示文本
----------
-- 该文件属于"RFUG工作室《OpenComputer开放式电脑图形驱动程序》"开发项目的一部分
-- 作者：Water_Moon、Ying_Lan、Mirror_Flower、n507 | Author: Water_Moon、Ying_Lan、Mirror_Flower、n507
-- 许可协议：GNU GPL v3 | License: GNU GPL v3

local widgetBase = require("widgetBase")
local stringutils = require("stringutils")

widgetLabel = {
  text = "", -- 要显示的文本
  lineWrapping = false, -- 是否自动换行
  border = "X", -- 边框所用的字符
  useBorder = false, -- 是否使用边框
  borderBackground = 0x000000,
  borderForeground = 0xffffff -- 边框颜色
}

setmetatable(widgetLabel, {__index = widgetBase})

-- 创建新的标签
-- 参数：继承对象，文本，x，y，宽度，高度，文字背景，文字前景，边框背景，边框前景，是否自动换行，边框字符，是否使用边框
function widgetLabel:new(o, text, x, y, width, height, bg, fg, bbg, bfg, lineWrapping, border, useBorder)
  o = o or {}
  o = widgetBase:new(o, x, y, width, height, bg, fg)
  setmetatable(o, {__index = self})

  o.text = text
  o.borderBackground = bbg or 0x000000
  o.borderForeground = bfg or 0xffffff
  o.border = border or "X"
  o.useBorder = useBorder or false
  o.lineWrapping = lineWrapping or false

  return o
end

function widgetLabel:setText(new_text)
  self.text = new_text
  self:makeDirty()
  return self
end

function widgetLabel:setLineWarpping(lineWrapping)
  self.lineWrapping = lineWrapping
  self:makeDirty()
  return self
end

function widgetLabel:setBorder(new_border)
  self.border = new_border
  self:makeDirty()
  return self
end

function widgetLabel:setUseBorder(useBorder)
  self.useBorder = useBorder
  self:makeDirty()
  return self
end

function widgetLabel:setBorderColor(bbg, bfg)
  self.bbg = bbg or self.bbg
  self.bfg = bfg or self.bfg
  self:makeDirty()
  return self
end

-- 绘制
function widgetLabel:draw(draw_gpu, force)
  if not (self.active and self.visible) then return end
  if not (self.dirty or force) then return end
  if not (draw_gpu) then return end

  local oldForeground = draw_gpu.getForeground()
  local oldBackground = draw_gpu.getBackground()

  --如果使用边框，则绘制边框
  if (self.useBorder) then
		draw_gpu.setForeground(self.borderForeground)
		draw_gpu.setBackground(self.borderBackground)
		draw_gpu.fill(self.x,self.y,self.width,self.height,self.border)

		draw_gpu.setForeground(self.foreground)
		draw_gpu.setBackground(self.background)
		draw_gpu.fill(self.x + 1, self.y + 1, self.width - 2, self.height - 2, " ")
	else
		draw_gpu.setForeground(self.foreground)
		draw_gpu.setBackground(self.background)
		draw_gpu.fill(self.x,self.y,self.width,self.height, " ")
	end

  local maxWidth = (self.useBorder and {self.width - 4} or {self.width})[1] --最大可以绘制文字的宽度
  local offsetX = (self.useBorder and {self.x + 1} or {self.x})[1] -- 文字区域最左边的X坐标

  --如果使用自动换行
  if(self.lineWrapping) then
    --最多能容纳几行文字
    local maxLines = (self.useBorder and {self.height - 2} or {self.height})[1]

    --获取每一行文本和总共的行数
    local subStrings, textLines = stringutils.getSubStrings(self.text, maxWidth)
    --判断要在哪一行开始绘制文本才能居中
    local lineToBegin = math.max(0, math.ceil((maxLines - textLines)/2))
    local borderOffset = (self.useBorder and {self.y + 1} or {self.y})[1] --考虑边框需要的一行
    local beginY = lineToBegin + borderOffset -- 开始写入文字的Y坐标

    for index, content in pairs(subStrings) do
      if(index > maxLines) then break end -- 如果写不下了就停止
      local textX = stringutils.getBeginX(content, maxWidth, offsetX)
      local textY = beginY + index - 1
      draw_gpu.set(textX, textY, content)
    end
  else -- 如果是单行文本
    local tmpText = self.text
    if(string.len(tmpText) > maxWidth) then
      tmpText = string.sub(tmpText, 1, maxWidth) -- 如果字符串太长就裁剪它可以显示的部分
    end
    local textX = stringutils.getBeginX(self.text, maxWidth, offsetX)
    local textY = self.y + math.floor(self.height / 2) -- 居中

    draw_gpu.set(textX, textY, tmpText)
  end

  draw_gpu.setBackground(oldBackground)
  draw_gpu.setForeground(oldForeground)
  self.dirty = false
end

return widgetLabel
