-- windowUtil.lua
-- 包含杂项工具方法
----------
-- 该文件属于"RFUG工作室《OpenComputer开放式电脑图形驱动程序》"开发项目的一部分
-- 作者：Water_Moon、Ying_Lan、Mirror_Flower、n507 | Author: Water_Moon、Ying_Lan、Mirror_Flower、n507
-- 许可协议：GNU GPL v3 | License: GNU GPL v3

windowUtil = {}

function windowUtil:listLength(table)
  local count = 0
  for _ in pairs(table) do
    count = count + 1
  end
  return count
end
