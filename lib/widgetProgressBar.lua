-- widgetProgressBar.lua
-- "进度条"控件，显示一个进度条
----------
-- 该文件属于"RFUG工作室《OpenComputer开放式电脑图形驱动程序》"开发项目的一部分
-- 作者：Water_Moon、Ying_Lan、Mirror_Flower、n507 | Author: Water_Moon、Ying_Lan、Mirror_Flower、n507
-- 许可协议：GNU GPL v3 | License: GNU GPL v3

local widgetBase = require("widgetBase")

widgetProgressBar = {
  progress = 0,   --当前值
  maxProgress = 0,--最大值
  mode = 0,       --模式，0 = 常规，1 = “加载”动画（并不填满进度条）
  filledBackground = 0x000000,
  filledForeground = 0xffffff, --填满部分的颜色
  filledText = "X",
  isVertical = false, --是否是垂直的
  loadingModeWidth = 3, -- 加载动画的宽度
  emptyText = "-"
}

setmetatable(widgetProgressBar, {__index = widgetBase})

-- 创建新的进度条
-- 参数：继承对象，最大进度，x, y, 宽度，高度，空部分背景，空部分前景，满部分背景，满部分前景，模式，满部分字符，空部分字符
function widgetProgressBar:new(o, maxProgress, x, y, width, height, bge, fge, bgf, fgf, mode, ftext, etext, isVertical)
  o = o or {}
  o = widgetBase:new(o, x, y, width, height, bge, fge)
  setmetatable(o, {__index = self})

  o.maxProgress = maxProgress or 100
  o.filledBackground = bgf or 0x000000
  o.filledForeground = fgf or 0xffffff
  o.mode = mode or 0
  o.filledText = ftext or "X"
  o.emptyText = etext or "-"
  o.isVertical = isVertical or false
  o.loadingModeWidth = 3
  return o
end

function widgetProgressBar:setProgress(progress, maxProgress)
  self.maxProgress = maxProgress or self.maxProgress  -- maxProgress是可选参数，如果没有保持不变
  progress = progress or self.progress  --Progress同理
  if(progress > self.maxProgress) then
    if(self.mode == 0) then
      self.progress = self.maxProgress
    else
      self.progress = progress % self.maxProgress
    end
  else
    self.progress = progress
  end
  self:makeDirty()
  return self
end

function widgetProgressBar:setLoadingModeWidth(w)
  self.loadingModeWidth = w or self.loadingModeWidth
  self:makeDirty()
  return self
end

function widgetProgressBar:setColor(bge, fge, bgf, fgf)
  self.background = bge or self.background
  self.foreground = fge or self.foreground
  self.filledBackground = bgf or self.filledBackground
  self.filledForeground = fgf or self.filledForeground
  self:makeDirty()
  return self
end

function widgetProgressBar:setText(ftext, etext)
  self.filledText = ftext or self.filledText
  self.emptyText = etext or self.emptyText
  self:makeDirty()
  return self
end

function widgetProgressBar:setIsVertical(is_vertical)
  self.isVertical = is_vertical
  self:makeDirty()
  return self
end

function widgetProgressBar:setMode(mode)
  if not(mode == 0 or mode == 1) then
    error("Invalid progress mode: must be 0 or 1", 2) --如果模式不是可用的模式之一就报错
  else
    self.mode = mode
  end
  self:makeDirty()
  return self
end

function widgetProgressBar:draw(draw_gpu, force)
  if not (self.active and self.visible) then return end
  if not (self.dirty or force) then return end
  if not (draw_gpu) then return end

  local oldForeground = draw_gpu.getForeground()
  local oldBackground = draw_gpu.getBackground()

  if(self.mode == 0) then -- 常规模式

    --填充部分的大小
    local filledSize = math.floor(0.5+(self.isVertical and {self.progress * self.height / self.maxProgress} or {self.progress * self.width / self.maxProgress})[1])

    -- 绘制满的部分
    draw_gpu.setBackground(self.filledBackground)
    draw_gpu.setForeground(self.filledForeground)
    if(self.isVertical) then
      draw_gpu.fill(self.x, self.y, self.width, filledSize, self.filledText)
    else
      draw_gpu.fill(self.x, self.y, filledSize, self.height, self.filledText)
    end

    -- 绘制空的部分
    draw_gpu.setBackground(self.background)
    draw_gpu.setForeground(self.foreground)
    if(self.isVertical) then
      draw_gpu.fill(self.x, self.y + filledSize, self.width, self.height - filledSize, self.emptyText)
    else
      draw_gpu.fill(self.x + filledSize, self.y, self.width - filledSize, self.height, self.emptyText)
    end
  else -- 动画模式
    local barWidth = self.loadingModeWidth
    local position = math.floor(0.5+(self.isVertical and {self.progress * (self.height + barWidth) / self.maxProgress} or {self.progress * (self.width + barWidth) / self.maxProgress})[1])

    if(position < barWidth) then
      barWidth = position  --最左端
      position = 0
    else
      position = position - barWidth
    end

    if(self.isVertical and ((position + barWidth) > self.height)) then
      barWidth = self.height - position
    elseif((not self.isVertical) and (position + barWidth) > self.width) then
      barWidth = self.width - position
    end

    --绘制进度条本身（空的部分）
    draw_gpu.setBackground(self.background)
    draw_gpu.setForeground(self.foreground)
    draw_gpu.fill(self.x, self.y, self.width, self.height, self.emptyText)

    --绘制动画
    draw_gpu.setBackground(self.filledBackground)
    draw_gpu.setForeground(self.filledForeground)
    if(self.isVertical) then
      draw_gpu.fill(self.x, self.y + position, self.width, barWidth, self.filledText)
    else
      draw_gpu.fill(self.x + position, self.y, barWidth, self.height, self.filledText)
    end
  end

  draw_gpu.setBackground(oldBackground)
  draw_gpu.setForeground(oldForeground)
  self.dirty = false
end

return widgetProgressBar
