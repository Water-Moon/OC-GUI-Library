-- widgetImage.lua
-- "图像"控件，通过定义特定字符和对应的颜色来绘制图像
----------
-- 该文件属于"RFUG工作室《OpenComputer开放式电脑图形驱动程序》"开发项目的一部分
-- 作者：Water_Moon、Ying_Lan、Mirror_Flower、n507 | Author: Water_Moon、Ying_Lan、Mirror_Flower、n507
-- 许可协议：GNU GPL v3 | License: GNU GPL v3

local widgetBase = require("widgetBase")
widgetImage = {
  image = {}, --图像本身
  imageKeys = {}, --每个字符对应的颜色和值
  linesUpdated = {},  --是否某行需要更新
  imageLines = 0
}

setmetatable(widgetImage, {__index = widgetBase})

--创建新的图像
function widgetImage:new(o, x, y, width, height, bg, fg)
  o = o or {}
  bg = bg or 0x000000
  fg = fg or 0xffffff

  o = widgetBase:new(o, x, y, width, height, bg, fg)
  setmetatable(o, {__index = self})

  o.image = {}
  o.imageKeys = {}
  
  o.imageKeys[" "] = {key = " ", bg = o.background, fg = o.foreground, text = " "} --设置空格对应的数据
  o.linesUpdated = {}
  o.imageLines = 0

  return o
end

--设置对应行
function widgetImage:setImageLine(line, lineNumber)
  if not lineNumber then
    self.imageLines = self.imageLines + 1
    lineNumber = self.imageLines
  end
  if(lineNumber > self.imageLines) then
    error("不能编辑还不存在的行！", 2)
  end
  self.image[lineNumber] = line
  self.linesUpdated[lineNumber] = true
  self:makeDirty()
  return self
end

--添加行
function widgetImage:addImageLine(line)
  self.imageLines = self.imageLines + 1
  self.image[self.imageLines] = line
  self.linesUpdated[self.imageLines] = true
  self:makeDirty()
  return self
end

--设置图像每个字符对应的颜色和文本
--参数：键值，背景色，前景色，替换文本
function widgetImage:setKey(key, kbg, kfg, replaceText)
  local tmp = {}
  tmp.key = key
  tmp.bg = kbg or self.background
  tmp.fg = kfg or self.foreground
  tmp.text = replaceText or " "
  self.imageKeys[key] = tmp
  self:makeDirty()
  for i = 1, self.imageLines, 1 do
    if(string.find(self.image[i], key)) then
      self.linesUpdated[i] = true --如果某行包含这个key那么那一行需要更新
    end
  end
  return self
end

function widgetImage:drawLine(draw_gpu, lineNumber)
  local line = self.image[lineNumber]
  local size = math.min(self.width, string.len(line)) + 1
  local yCoord = self.y + lineNumber - 1
  for j = 1, size, 1 do --对于一行中的每一个字符
    local currentChar = string.sub(line, j, j) --当前字符
    local vals = self.imageKeys[currentChar] --当前字符对应的数据
    if not vals then
      vals = {key = currentChar, bg = self.background, fg = self.foreground, text = currentChar} --如果没有则设置默认数据
    end
    draw_gpu.setBackground(vals.bg)
    draw_gpu.setForeground(vals.fg)
    local xCoord = self.x + j - 1
    draw_gpu.set(xCoord, yCoord, vals.text)
  end
  if(size < self.width) then --填满剩下的部分
    draw_gpu.setBackground(self.background)
    draw_gpu.setForeground(self.foreground)
    draw_gpu.fill(self.x + size - 1, yCoord, self.width - size, 1, " ")
  end
end

function widgetImage:draw(draw_gpu, force)
  if not (self.active and self.visible) then return end
  if not (self.dirty or force) then return end
  if not (draw_gpu) then return end

  local oldForeground = draw_gpu.getForeground()
  local oldBackground = draw_gpu.getBackground()

  local lines = math.min(self.imageLines, self.height) + 1
  for i = 1, lines, 1 do
    if (self.linesUpdated[i] or force) then
      self:drawLine(draw_gpu, i)
    end
  end
  if(lines < self.height) then
    draw_gpu.setBackground(self.background)
    draw_gpu.setForeground(self.foreground)
    draw_gpu.fill(self.x, self.y + lines - 1, self.width, self.height - lines, " ")
  end

  self.linesUpdated = {}

  draw_gpu.setBackground(oldBackground)
  draw_gpu.setForeground(oldForeground)
  self.dirty = false
end

return widgetImage