-- window.lua
-- 定义了应用程序的窗口
-- 每个窗口都可以绑定独立的GPU
-- 窗口是所有显示控件的容器
----------
-- 该文件属于"RFUG工作室《OpenComputer开放式电脑图形驱动程序》"开发项目的一部分
-- 作者：Water_Moon、Ying_Lan、Mirror_Flower、n507 | Author: Water_Moon、Ying_Lan、Mirror_Flower、n507
-- 许可协议：GNU GPL v3 | License: GNU GPL v3

local windowUtil = require("windowUtil");

window = {
	id = 0,
	widget_id = 0,  -- 上一个控件的ID
	focused_widget_id = 0, -- 当前焦点控件的ID（文本tab输入之类的）
	background = 0x000000, -- 窗口默认背景色
	foreground = 0xffffff, -- 窗口默认前景色
	active = true, -- 窗口是否激活
	nextDrawForced = false,	-- 下一帧是否重绘所有内容
	err_out = nil, -- 错误处理函数
	screen_cleared = false,
	bind_gpu = nil -- 窗口绑定的GPU
}

-- 创建新的窗口
-- 参数：继承对象，绑定GPU，背景色，前景色，错误处理函数
function window:new(o, bind_gpu, bg, fg, err_handler)
	o = o or {}
	setmetatable(o, {__index = self})	-- 设置新创建的对象继承window

	-- 创建单独的控件表以避免冲突
	o.widgets = {}

	-- 背景色和前景色
	o.background = bg or 0x000000
	o.foreground = fg or 0xffffff

	-- 绑定GPU
	o.bind_gpu = bind_gpu

	-- 设置错误处理函数
	o.err_out = err_handler

	return o
end

-- 内部函数：错误处理
function window:errorHandler(err)
	if(self.err_out) then
		self.err_out(err)
	end
end

-- 添加一个窗口控件
-- 返回控件的ID
function window:addWidget(widget_to_add)
	self.widget_id = self.widget_id + 1
	self.widgets[self.widget_id] = widget_to_add
	widget_to_add:setID(self.widget_id, self)
	return self.widget_id
end

-- 根据ID移除对应的控件
-- 返回移除成功与否
function window:removeWidget(widget_id)
	local success = false
	if(self.widgets[widget_id]) then
		success = xpcall(function() self.widgets[widget_id]:destory() end, function(err) self:errorHandler(err) end)
		if(success) then
			self.widgets[widget_id] = nil
		end
	end
	return success
end

-- 设置窗口是否激活（不激活的窗口不会被绘制 - 这样允许一个屏幕有多个窗口）
function window:setActive(should_active)
	self.active = should_active
end

-- 给窗口绑定新的GPU
function window:reBind(new_gpu)
	self.bind_gpu = new_gpu
end

-- 设置下一帧强制重绘所有
function window:setNextDrawForced()
	self.nextDrawForced = true
	self.screen_cleared = false
end

-- 尝试聚焦一个控件，如果控件不存在则返回false
function window:focus(widget_id)
	-- 如果不存在或不能被聚焦返回false
	if not(self.widgets[widget_id]) then return false end
	if not(self.widgets[widget_id]:canBeFocused()) then return false end

	-- 如果之前有选中其他的，调用取消聚焦事件
	if(self.widgets[self.focused_widget_id]) then
		xpcall(function() self.widgets[self.focused_widget_id]:onNotFocused() end, function(err) self:errorHandler(err) end)
	end

	-- 设置新的选中并调用聚焦事件
	self.focused_widget_id = widget_id;
	xpcall(function() self.widgets[self.focused_widget_id]:onFocused() end, function(err) self:errorHandler(err) end)
	return true
end

-- 尝试聚焦下一个控件，如果存在的话 (类似Tab键的效果)
function window:focusNext()
	-- new_selection是将要选取的控件
	local new_selection = self.focused_widget_id + 1;

	while(1) do
		if(not self.widgets[new_selection]) then
			new_selection = new_selection + 1	-- 如果不存在，下一个
		elseif(not self.widgets[new_selection]:canBeFocused()) then
			new_selection = new_selection + 1 -- 如果不能被选中，下一个
		elseif(self.focused_widget_id == new_selection) then
			break -- 如果所有的都检查过了，那就退出循环
		elseif(new_selection > self.widget_id) then
			new_selection = 1 -- 如果超过最大ID，就从1重新开始
		else
			break -- 找到了下一个，退出循环
		end
	end

	-- 如果不是因为都检查过了而退出的循环的话，那么
	if not(new_selection == self.focused_widget_id) then
		-- 如果之前有选中其他的，调用取消聚焦事件
		if(self.widgets[self.focused_widget_id]) then
			xpcall(function() self.widgets[self.focused_widget_id]:onNotFocused() end, function(err) self:errorHandler(err) end)
		end

		-- 设置新的选中并调用聚焦事件
		self.focused_widget_id = new_selection;
		xpcall(function() self.widgets[self.focused_widget_id]:onFocused() end, function(err) self:errorHandler(err) end)
		return true
	end
end

-- 绘制窗口
function window:draw()

	-- 如果没有激活或者没有绑定GPU就直接返回
	if(not self.active) then return end
	if(not self.bind_gpu) then return end
	-- 设置默认颜色
	local oldBackground = self.bind_gpu.setBackground(self.background)
	local oldForeground = self.bind_gpu.setForeground(self.foreground)
	-- 如果还没清屏
	if(not self.screen_cleared) or (self.nextDrawForced) then
		local width, height = self.bind_gpu.getResolution()
		self.bind_gpu.fill(1, 1, width, height, " ")
		self.screen_cleared = true
	end

	-- 绘制所有组件(第一遍 - 常规组件)
	for _,comp in pairs(self.widgets) do
		if (comp) then
			if not (comp:always_on_top()) then
				xpcall(function(g, f) comp:draw(g, f) end, function(err) self:errorHandler(err) end, self.bind_gpu, self.nextDrawForced)
			end
		end
	end

	-- 绘制所有组件(第二遍 - 在最上面的)
	for _,comp in pairs(self.widgets) do
		if (comp) then
			if(comp:always_on_top()) then
				xpcall(function(g, f) comp:draw(g, f) end, function(err) self:errorHandler(err) end, self.bind_gpu, self.nextDrawForced)
			end
		end
	end
	-- 设置下次不重绘全部
		self.nextDrawForced = false

  -- 恢复原本的颜色
  self.bind_gpu.setBackground(oldBackground)
  self.bind_gpu.setForeground(oldForeground)
end

-- 响应触摸事件
function window:handleClickEvent(screenAddr, xCoord, yCoord, mouseButton, playerName)

		-- 如果没有激活或者没有绑定GPU就直接返回
		if(not self.active) then return end
		if(not self.bind_gpu) then return end

		if(not screenAddr == self.bind_gpu.getScreen()) then return end

		for _,comp in pairs(self.widgets) do
			if (comp) then
				xpcall(function(screenAddr, xCoord, yCoord, mouseButton, playerName) comp:onClick(screenAddr, xCoord, yCoord, mouseButton, playerName) end, function(err) self:errorHandler(err) end, screenAddr, xCoord, yCoord, mouseButton, playerName)
			end
		end
end

-- 响应拖动事件
function window:handleDragEvent(screenAddr, xCoord, yCoord, mouseButton, playerName)

		-- 如果没有激活或者没有绑定GPU就直接返回
		if(not self.active) then return end
		if(not self.bind_gpu) then return end

		if(not screenAddr == self.bind_gpu.getScreen()) then return end

		for _,comp in pairs(self.widgets) do
			if (comp) then
				xpcall(function(screenAddr, xCoord, yCoord, mouseButton, playerName) comp:onDrag(screenAddr, xCoord, yCoord, mouseButton, playerName) end, function(err) self:errorHandler(err) end, screenAddr, xCoord, yCoord, mouseButton, playerName)
			end
		end
end

-- 响应鼠标滚轮
function window:handleScrollEvent(screenAddr, xCoord, yCoord, direction, playerName)

		-- 如果没有激活或者没有绑定GPU就直接返回
		if(not self.active) then return end
		if(not self.bind_gpu) then return end

			if(not screenAddr == self.bind_gpu.getScreen()) then return end

		for _,comp in pairs(self.widgets) do
			if (comp) then
				xpcall(function(screenAddr, xCoord, yCoord, mouseButton, playerName) comp:onScroll(screenAddr, xCoord, yCoord, direction, playerName) end, function(err) self:errorHandler(err) end, screenAddr, xCoord, yCoord, direction, playerName)
			end
		end
end

-- 响应键盘
function window:handleKeyboardInput(screenAddr, char, code, playerName)

		-- 如果没有激活或者没有绑定GPU就直接返回
		if(not self.active) then return end
		if(not self.bind_gpu) then return end

		if(not screenAddr == self.bind_gpu.getScreen()) then return end

		for _,comp in pairs(self.widgets) do
			if (comp) then
				xpcall(function(screenAddr, char, code, playerName) comp:onKeyboardInput(screenAddr, char, code, playerName) end, function(err) self:errorHandler(err) end, screenAddr, char, code, playerName)
			end
		end
end

-- 响应剪贴板
function window:handleClipboard(screenAddr, content, playerName)

		-- 如果没有激活或者没有绑定GPU就直接返回
		if(not self.active) then return end
		if(not self.bind_gpu) then return end

		if(not screenAddr == self.bind_gpu.getScreen()) then return end

		for _,comp in pairs(self.widgets) do
			if (comp) then
				xpcall(function(screenAddr, content, playerName) comp:onClipboard(screenAddr, content, playerName) end, function(err) self:errorHandler(err) end, screenAddr, content, playerName)
			end
		end
end

-- 类声明结束
return window
