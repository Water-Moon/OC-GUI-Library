-- widgetTextBox.lua
-- "文本框"控件，在选中时可以输入文本
----------
-- 该文件属于"RFUG工作室《OpenComputer开放式电脑图形驱动程序》"开发项目的一部分
-- 作者：Water_Moon、Ying_Lan、Mirror_Flower、n507 | Author: Water_Moon、Ying_Lan、Mirror_Flower、n507
-- 许可协议：GNU GPL v3 | License: GNU GPL v3

local widgetBase = require("widgetBase")
local stringutils = require("stringutils")

widgetTextBox = {
  text = "",  --文本
  hintText = "", --如果没有输入东西的话，显示的提示文本
  hintTextColor = 0x888888, --提示文本的颜色
  passwordField = false,  --这是否是一个密码区域
  passwordMask = "*", --如果是密码的话，用什么代替常规字符
  callbackOnChange = nil, --当文字改变时，做什么
  callbackOnSelect = nil,  --当框被选中时，做什么
  currentCursorPosition = 1, --光标位置
  cursorForeground = 0xffffff, --光标前景色
  cursorBackground = 0x000000, --光标背景色
  selectedForeground = 0x000000,  --选中时的前景色
  selectedBackground = 0xffffff,  --选中时的背景色
  border = "X",   --边框
  selectedBorder = "#",  --选中时的边框
  borderBackground = 0x000000, --边框颜色
  borderForeground = 0xffffff,
  borderBackgroundSelected = 0x000000, --选中时的边框颜色
  borderForegroundSelected = 0xffffff,
  useBorder = false, --是否使用边框
  selected = false --是否当前被选中（选中后接受输入）
}

setmetatable(widgetTextBox, {__index = widgetBase})

-- 创建新的文本框
-- 参数：继承对象，提示文本，x，y，宽度，高度，背景色，前景色，光标背景色，光标前景色，选中背景色，选中前景色
function widgetTextBox:new(o, hintText, x, y, width, height, bg, fg, cbg, cfg, sbg, sfg)
  o = o or {}
  o = widgetBase:new(o, x, y, width, height, bg, fg)
  setmetatable(o, {__index = self})

  o.hintText = hintText or ""
  o.cursorBackground = cbg or o.cursorBackground
  o.cursorForeground = cfg or o.cursorForeground
  o.selectedForeground = sfg or o.selectedForeground
  o.selectedBackground = sbg or o.selectedBackground

  return o
end

-- 添加当文本变更时的回调函数
-- 回调函数可以接受一个参数：当前内容
function widgetTextBox:setTextChangeCallback(cbfun)
  self.callbackOnChange = cbfun
  self:makeDirty()
  return self
end

-- 添加当文本框被选中时的回调函数
-- 回调函数可以接受一个参数：当前内容
function widgetTextBox:setSelectCallback(cbfun)
  self.callbackOnSelect = cbfun
  self:makeDirty()
  return self
end

--设置边框（是否启用，字符，选中字符）
function widgetTextBox:setBorder(useborder, text, text_selected)
  self.useBorder = useborder
  self.border = text or self.border
  self.selectedBorder = text_selected or self.selectedBorder
  self:makeDirty()
  return self
end

-- 设置颜色
-- 背景色，前景色，光标背景色，光标前景色，选中背景色，选中前景色，提示文本色，边框背景色，边框前景色，边框选中背景色，边框选中前景色
function widgetTextBox:setColor(bg, fg, cbg, cfg, sbg, sfg, htc, bbg, bfg, bbgs, bfgs)
  self.foreground = fg or self.foreground
  self.background = bg or self.background
  self.selectedBackground = sbg or self.selectedBackground
  self.selectedForeground = sfg or self.selectedForeground
  self.borderBackground = bbg or self.borderBackground
  self.borderForeground = bfg or self.borderForeground
  self.hintTextColor = htc or self.hintTextColor
  self.borderBackgroundSelected = bbgs or self.borderBackgroundSelected
  self.borderForegroundSelected = bfgs or self.borderForegroundSelected
  self.cursorBackground = cbg or self.cursorBackground
  self.cursorForeground = cfg or self.cursorForeground
  self.selectedForeground = sfg or self.selectedForeground
  self.selectedBackground = sbg or self.selectedBackground
end

-- 获取文本框里填写的内容
function widgetTextBox:getText()
  return self.text
end

-- 设置文本
function widgetTextBox:setText(newtext)
  self.text = newtext or ""
  self:makeDirty()
  return self
end

function widgetTextBox:draw(draw_gpu, force)
  if not (self.active and self.visible) then return end
  if not (self.dirty or force) then return end
  if not (draw_gpu) then return end

  local oldForeground = draw_gpu.getForeground()
  local oldBackground = draw_gpu.getBackground()

  local bg = self.background
  local fg = self.foreground
  local cbg = self.background
  local cfg = self.foreground
  local bbg = self.borderBackground
  local bfg = self.borderForeground
  local borderText = self.border
  if(self.selected) then
    bg = self.selectedBackground
    fg = self.selectedForeground
    cbg = self.cursorBackground
    cfg = self.cursorForeground
    bbg = self.borderBackgroundSelected
    bfg = self.borderForegroundSelected
    borderText = self.selectedBorder
  end
  --绘制边框（如有）
  if (self.useBorder) then
    draw_gpu.setForeground(bfg)
    draw_gpu.setBackground(bbg)
    draw_gpu.fill(self.x,self.y,self.width,self.height,borderText)

    draw_gpu.setForeground(fg)
    draw_gpu.setBackground(bg)
    draw_gpu.fill(self.x + 1, self.y + 1, self.width - 2, self.height - 2, " ")
  else
    draw_gpu.setForeground(fg)
    draw_gpu.setBackground(bg)
    draw_gpu.fill(self.x,self.y,self.width,self.height, " ")
  end

  local textYCoord = math.floor(self.height/2) + self.y --文字的Y坐标
  local textXAllowed = (self.useBorder and {self.width - 2} or {self.width})[1] --文字最大容许的长度
  local beginX = (self.useBorder and {self.x + 1} or {self.x})[1] --文字的起始X坐标

  local textToShow = self.text
  if(self.text == "" and (not self.selected)) then
    textToShow = self.hintText
    fg = self.hintTextColor
    cfg = self.hintTextColor
    draw_gpu.setForeground(fg)
  elseif(self.passwordField) then
    textToShow = string.rep(self.passwordMask, string.len(self.text))
  end

  local firstHalf, cursorChar, nextHalf = stringutils.getTextBoxDisplay(textToShow, self.currentCursorPosition, textXAllowed)  --获取显示信息

  draw_gpu.set(beginX, textYCoord, firstHalf) --前一半

  beginX = beginX + string.len(firstHalf)
  draw_gpu.setForeground(cfg)
  draw_gpu.setBackground(cbg)
  draw_gpu.set(beginX, textYCoord, cursorChar) --光标

  beginX = beginX + string.len(cursorChar)
  draw_gpu.setForeground(fg)
  draw_gpu.setBackground(bg)
  draw_gpu.set(beginX, textYCoord, nextHalf) --后一半

  draw_gpu.setBackground(oldBackground)
  draw_gpu.setForeground(oldForeground)
  self.dirty = false
end

function widgetTextBox:onClick(screenAddr, xCoord, yCoord, mouseButton, playerName)
  if not(self.enabled and self.active) then return end
  if((xCoord < self.x) or (xCoord > (self.x + self.width - 1))) then
    self.selected = false
  elseif((yCoord < self.y) or (yCoord > (self.y + self.height - 1))) then
    self.selected = false
  elseif(not self.selected) then
    self.selected = true
    if(self.callbackOnSelect) then self.callbackOnSelect(self:getText()) end
  else
    textPosClicked = xCoord - self.x
    self.currentCursorPosition = math.max(1, math.min(string.len(self.text) + 1, textPosClicked))
  end
  self:makeDirty()
end

function widgetTextBox:onKeyboardInput(screenAddr, char, code, playerName)
  if(not self.selected) then return end
  if not(self.enabled and self.active) then return end
  if(code == 199) then --home
    self.currentCursorPosition = 1
  elseif(code == 207) then --end
    self.currentCursorPosition = string.len(self.text) + 1
  elseif(code == 203) then --向左箭头
    self.currentCursorPosition = math.max(1, self.currentCursorPosition - 1)
  elseif(code == 205) then -- 向右箭头
    self.currentCursorPosition = math.min(string.len(self.text) + 1, self.currentCursorPosition + 1)
  else
    local beforeCursor = string.sub(self.text, 1, self.currentCursorPosition-1)
    local afterCursor = string.sub(self.text, self.currentCursorPosition, string.len(self.text))
    if(code == 14) then -- 退格
      beforeCursor = string.sub(beforeCursor, 1, string.len(beforeCursor) - 1)
      self.currentCursorPosition = math.max(1, self.currentCursorPosition - 1)
    elseif(code == 211) then -- delete
      afterCursor = string.sub(afterCursor, 2, string.len(afterCursor))
    else
      if(char >= 20 and char <= 126) then --必须是正常字符而非控制字符
        beforeCursor = beforeCursor .. string.char(char)
        self.currentCursorPosition = self.currentCursorPosition + 1
      end
    end
    self.text = beforeCursor .. afterCursor
  end
  if(self.callbackOnChange) then self.callbackOnChange(self:getText()) end
  self:makeDirty()
end

function widgetTextBox:onClipboard(screenAddr, content, playerName)
  if(not self.selected) then return end
  if not(self.enabled and self.active) then return end
  local beforeCursor = string.sub(self.text, 1, self.currentCursorPosition-1)
  local afterCursor = string.sub(self.text, self.currentCursorPosition, string.len(self.text))
  self.text = beforeCursor .. content .. afterCursor
  self.currentCursorPosition = self.currentCursorPosition + string.len(content)
  if(self.callbackOnChange) then self.callbackOnChange(self:getText()) end
  self:makeDirty()
end

return widgetTextBox
