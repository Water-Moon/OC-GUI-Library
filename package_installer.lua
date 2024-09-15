---@diagnostic disable: unused-function
local internet = require("internet")
local component = require("component")
local serialization = require("serialization")
local term = require("term")
local computer = require("computer")

local target_disk = component.proxy(component.list("filesystem")())

if(not component.list("internet")()) then
    print("需要一张因特网卡才能从互联网下载程序！")
    os.exit(0)
end

if(not target_disk) then
    print("至少需要一个存储媒介才能安装程序！")
    os.exit(0)
end

local function sleepFor(time)
    local lastTime = computer.uptime()
    while(computer.uptime() - lastTime < time) do
        computer.pullSignal(0.1)
    end
end

local function do_get_package(url)
    local result, response = pcall(internet.request, url, nil, { ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36" })
    if(not result) then
        return false, response
    end
    local a = ""
    for chunk in response do 
        a = a..chunk 
        computer.pullSignal(0.01)
    end
    return a, ""
end

local function get_package(url)
    local result, response = pcall(do_get_package, url)
    if(not result) then
        return false, response
    end
    return response, ""
end

local function print_title()
    term.clear()
    term.write("====Simple Package Downloader by Water_Moon====\n")
    term.write("当前安装位置：" .. target_disk.getLabel() .. " [" .. string.sub(target_disk.address, 1, 3) .. "]")
    term.write("\n\n")
end

local function select_filesystem()
    print_title()
    local fsTable = component.list("filesystem", true)
    local fileSystems = {}

    for addr, _ in fsTable do
        fileSystems[#fileSystems+1] = addr
    end

    term.write("选择安装位置：\n")
    for i = 1, #fileSystems, 1 do
        local fs = component.proxy(fileSystems[i])
		if(fs and fs.getLabel() and fileSystems[i]) then
            term.write(i .. ": " .. fs.getLabel() .. " [" .. string.sub("" .. fileSystems[i], 1, 3) .. "]" .. "\n")
		else
			if(fileSystems[i]) then
            	term.write(i .. ": (未命名) [" .. string.sub("" .. fileSystems[i], 1, 3) .. "]" .. "\n")
			else
				term.write("(不可用)\n")
			end
		end
    end

    term.write("\n")
    term.write("选择一个安装位置（输入q取消）:")
    term.write("\n")
    local selection = nil
    repeat
        term.setCursorBlink(true)
        selection = string.sub(term.read({}, false),1, -2)
        if(selection == "q" or selection == "Q") then
            return
        end
        term.setCursorBlink(false)
        if(not tonumber(selection)) then
            term.write("输入无效，请重新输入（输入q取消）:\n")
        end
    until tonumber(selection)

    local index = tonumber(selection)
    term.write("\n\n已选择 #" .. index)
    target_disk = component.proxy(fileSystems[index])
    term.write(" (" .. target_disk.getLabel() .. " [" .. string.sub(target_disk.address, 1, 3) .. "] )")
    computer.beep(".-")
    sleepFor(0.25)
end

local function draw_progress_bar(title, install_logs, current, total)
    local w, h, xOffset, yOffset, relX, relY = term.getViewport()
    print_title()
    term.write(title .. "\n")

    local available_lines = h - 8
    local start_index = math.max(0, #install_logs - available_lines)
    for i = start_index, #install_logs, 1 do
        if(install_logs[i]) then
            term.write("" .. install_logs[i] .."\n", false)
        end
    end

    term.setCursor(1, h-1)
    term.write("" .. math.floor(10000*current/total)/100 .. "%\n")
    local fill_width = math.floor(w * current / total)
    local empty_width = w - fill_width
    term.write(string.rep("=", fill_width) .. string.rep("-" , empty_width))
end

local function write_file(path,strings)
    target_disk.remove(path)
    local handle = target_disk.open(path,"w")
    target_disk.write(handle,strings)
    target_disk.close(handle)
end

install_package = nil

local function install_package_lycoris_format(url, doConfirmation)
    print_title()
    term.write("[兼容模式] 下载安装 " .. url .. " ... \n")
    local file_list, failure = get_package(url .. "/file_paths.txt")
    local dir_list, failure = get_package(url .. "/file_dirs.txt")
    local dependencies, failure = get_package(url .. "/dependencies.txt")
    local name, failure = get_package(url .. "/name.txt")
    local readme, failure = get_package(url .. "/readme.txt")

    if not file_list then
        term.write("下载失败！\n")
        term.write("原因：" .. failure .. "\n")
        term.write("按Enter继续")
        term.read()
        return false
    end

    local lines = {}
    for line in string.gmatch(file_list, "[^\r\n]+") do
        lines[#lines+1] = line
    end

    local dirs = {}
    local actual_dirs = {}
    local parent_dir = "/"
    if dir_list then
        for line in string.gmatch(dir_list, "[^\r\n]+") do
            dirs[#dirs+1] = line
        end
        parent_dir = dirs[1]
        for i = 2, #dirs, 1 do
            actual_dirs[#actual_dirs+1] = parent_dir .. "/" .. dirs[i]
        end
    end

    local package_prereq = false
    if dependencies then
        package_prereq = {}
        for line in string.gmatch(dependencies, "[^\r\n]+") do
            package_prereq[#package_prereq+1] = line
        end
    end

    term.write("获取Lycoris格式包信息成功\n\n")
    sleepFor(0.1)
    term.write("名称：" .. name .. "\n") 
    term.write("包含 " .. #lines .. "个文件，" .. #dir_list .. "个目录\n")
    if(package_prereq) then
        term.write("还需要下载".. #package_prereq .."个前置：" .. "\n")
        for k,v in ipairs(package_prereq) do
            term.write("    " .. k .. " :" .. v)
        end
    end

    if readme then
        term.write("\n附加信息：\n")
        term.write(readme .. "\n\n")
    end

    if(doConfirmation) then
        term.write("确定要安装？")
        if(package_prereq) then
            term.write("还将安装" .. #package_prereq .. "个前置")
        end
        term.write("\n\n Y = 确认，N = 取消 \n 输入P更改安装路径:\n\n")
        local selection = ""
        term.setCursorBlink(true)
        selection = string.sub(term.read({}, false),1, -2)
        term.setCursorBlink(false)
        if(selection == "N" or selection == "n") then
            term.write("安装已取消。\n")
            term.write("按Enter继续")
            term.read()
            return false
        end
        if(selection == "P" or selection == "p") then
            select_filesystem()
            return "resume"
        end
        if(not(selection == "Y" or selection == "y")) then
            term.write("输入无效，安装已取消。\n")
            term.write("按Enter继续")
            term.read()
            return false
        end
    end

    term.write("正在开始安装..." .. name .. "\n")
    sleepFor(0.5)

    if(package_prereq) then
        for k, v in ipairs(package_prereq) do
            term.write("正在安装前置..." .. v)
            sleepFor(0.5)    
            install_package(v, false)
        end
    end

    local total_items = #lines + #actual_dirs
    local finished_items = 0
    local install_logs = {}
    for k, v in ipairs(actual_dirs) do
        install_logs[#install_logs+1] = ("创建目录 " .. v)
        draw_progress_bar("正在安装..." .. name .. "\n",
            install_logs, finished_items, total_items)
        target_disk.makeDirectory(v)
        finished_items = finished_items + 1
    end
    
    for k, v in ipairs(lines) do
        install_logs[#install_logs+1] = ("获取文件 " .. v)
        draw_progress_bar("正在安装..." .. name .. "\n",
            install_logs, finished_items, total_items)
        local content = get_package(url .. "/" .. v)
        write_file(parent_dir .. "/" .. v, content)
        finished_items = finished_items + 1
    end

    
    term.write("安装"..name .. "成功！\n")
    if(doConfirmation) then
        term.write("按Enter继续")
        term.read()
    end
    return "success"

end


local function install_package_normal(url, doConfirmation)
    print_title()
    term.write("下载安装 " .. url .. " ... \n")
    local downloaded, failure = get_package(url .. "/package.info")
    if(not downloaded) then
        local downloaded, failure = get_package(url .. "/file_paths.txt")
        if downloaded then
            install_package_lycoris_format(url, doConfirmation)
            return true
        else
            term.write("下载失败！\n")
            term.write("原因：" .. failure .. "\n")
            term.write("按Enter继续")
            term.read()
            return false
        end
    end

    local package_info = serialization.unserialize(downloaded)

    local package_name = package_info.name
    local package_ver = package_info.version
    local package_paths = package_info.paths
    local package_files = package_info.files
    local package_prereq = package_info.prereq
    local package_additional_info = package_info.info

    if(not package_name) then
        term.write("文件损坏！未找到名称信息\n")
        term.write("按Enter继续")
        term.read()
        return false
    end

    if(not package_name) then
        term.write("文件损坏！未找到名称信息\n")
        term.write("按Enter继续")
        term.read()
        return false
    end

    term.write("获取包信息成功\n\n")
    sleepFor(0.1)
    term.write("名称：" .. package_info.name .. "\n") 
    if(package_ver) then
        term.write("版本: " .. package_ver .. "\n")
    else
        term.write("版本：未知" .. "\n")
        package_ver = "未知"
    end

    term.write("包含 " .. #package_files .. "个文件，" .. #package_paths .. "个目录\n")

    if(package_prereq) then
        term.write("还需要下载".. #package_prereq .."个前置：" .. "\n")
        for k,v in ipairs(package_prereq) do
            term.write("    " .. k .. " :" .. v)
        end
    end

    if(package_info) then
        term.write("\n附加信息：\n")
        term.write(package_additional_info .. "\n\n")
    end
    

    if(doConfirmation) then
        term.write("确定要安装？")
        if(package_prereq) then
            term.write("还将安装" .. #package_prereq .. "个前置")
        end
        term.write("\n\n Y = 确认，N = 取消 \n 输入P更改安装路径:\n\n")
        local selection = ""
        term.setCursorBlink(true)
        selection = string.sub(term.read({}, false),1, -2)
        term.setCursorBlink(false)
        if(selection == "N" or selection == "n") then
            term.write("安装已取消。\n")
            term.write("按Enter继续")
            term.read()
            return false
        end
        if(selection == "P" or selection == "p") then
            select_filesystem()
            return "resume"
        end
        if(not(selection == "Y" or selection == "y")) then
            term.write("输入无效，安装已取消。\n")
            term.write("按Enter继续")
            term.read()
            return false
        end
    end

    term.write("正在开始安装..." .. package_name .."版本" .. package_ver .. "\n")
    sleepFor(0.5)

    if(package_prereq) then
        for k, v in ipairs(package_prereq) do
            term.write("正在安装前置..." .. v)
            sleepFor(0.5)    
            install_package(v, false)
        end
    end

    local total_items = #package_paths + #package_files
    local finished_items = 0
    local install_logs = {}
    for k, v in ipairs(package_paths) do
        install_logs[#install_logs+1] = ("创建目录 " .. v)
        draw_progress_bar("正在安装..." .. package_name .."版本" .. package_ver .. "\n",
            install_logs, finished_items, total_items)
        target_disk.makeDirectory(v)
        finished_items = finished_items + 1
    end
    
    for k, v in ipairs(package_files) do
        install_logs[#install_logs+1] = ("获取文件 " .. v)
        draw_progress_bar("正在安装..." .. package_name .."版本" .. package_ver .. "\n",
            install_logs, finished_items, total_items)
        local content = get_package(url .. v)
        write_file(v, content)
        finished_items = finished_items + 1
    end

    
    term.write("安装"..package_name .. "成功！\n")
    if(doConfirmation) then
        term.write("按Enter继续")
        term.read()
    end
    return "success"

end

install_package = function(url, doConfirmation)
    local downloaded, failure = get_package(url .. "/package.info")
    if(not downloaded) then
        local downloaded, failure = get_package(url .. "/file_paths.txt")
        if downloaded then
            return install_package_lycoris_format(url, doConfirmation)
        else
            term.write("下载失败！\n")
            term.write("原因：" .. failure .. "\n")
            term.write("按Enter继续")
            term.read()
            return false
        end
    else
        return install_package_normal(url, doConfirmation)
    end
end

local function run_install_program()
    print_title()
    term.write("请输入要下载的来源地址\n")
    term.write("（需为直链，指向包含package.info的文件夹）\n\n")
    term.setCursorBlink(true)
    local url = string.sub(term.read({}, false),1, -2)
    term.setCursorBlink(false)
    while(true) do
        local result = install_package(url, true)
        if(not result) then
            return
        end
        if(result == "resume") then
            term.write("路径已更改，重新开始安装...\n")
            sleepFor(1)
        end
        if(result == "success") then
            return
        end
    end
end

local running = true


local function handleInput()
	local waitTime = 0.5
	local beginTime = computer.uptime()
	while(computer.uptime() < (beginTime + waitTime)) do
		sig, val1, val2, val3, val4, val5 = computer.pullSignal(0.5);
		if(sig == "key_down") then
			if(string.char(val2) == "q" or string.char(val2) == "Q") then
				running = false
				computer.beep(".")
            elseif (string.char(val2) == "i" or string.char(val2) == "I") then
                run_install_program()
            elseif (string.char(val2) == "p" or string.char(val2) == "P") then
                select_filesystem()
            end
			return
		end
	end
end


local function run()
    print_title()
    term.write("按i来安装一个程序\n")
    term.write("按p来更改安装路径\n")
    term.write("按q退出\n")
    handleInput()
end

while(running) do
	result, err = pcall(run)
	if(not result) then
		term.clear()
		term.write("出现错误：" .. err)
		term.write("\n\n")
		term.write("按Enter继续")
		term.read()
	end
end
