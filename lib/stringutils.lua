-- stringutils.lua
-- 字符串相关的工具方法
----------
-- 该文件属于"RFUG工作室《OpenComputer开放式电脑图形驱动程序》"开发项目的一部分
-- 作者：Water_Moon、Ying_Lan、Mirror_Flower、n507 | Author: Water_Moon、Ying_Lan、Mirror_Flower、n507
-- 许可协议：GNU GPL v3 | License: GNU GPL v3


stringutils = {}

-- 用于清除字符串前后的空格
function stringutils.trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--用来获取一行文本的起始位置
function stringutils.getBeginX(textIn, maxWidth, offsetX)
  if(not textIn) then return offsetX + math.floor(maxWidth/2) end
  if (string.len(textIn) > maxWidth) then
    return offsetX
  else
    return (offsetX + math.floor(0.5 + (maxWidth - string.len(textIn)) / 2))
  end
end

-- 获取一个table，其内容是字符串按最大长度换行
-- 另外会返回这个table有多少行
function stringutils.getSubStrings(text, maxWidth)
  result = {}

  -- 迭代器，每次访问一个词
  iter = string.gmatch(text, "%g+")

  currentWord = iter()
  tmpString = ""  -- 用来缓存当前的字符串部分
  nextArrayIndex = 1

  while (currentWord) do

    if(string.len(tmpString .. currentWord .. " ") > maxWidth) then -- 如果到这个词为止会超过长度限制
      -- 如果当前的词本身超过长度限制
      if ((string.len(currentWord) >= maxWidth)) then
        if not (tmpString == "") then
          result[nextArrayIndex] = stringutils.trim(tmpString) --把到现在为止的全部内容放进结果
          nextArrayIndex = nextArrayIndex + 1
          tmpString = ""  --重设缓存
        else
          tmp = string.sub(currentWord, 1, maxWidth - 1)   -- 截取长度限制之前的全部部分

          currentWord = string.sub(currentWord, string.len(tmp) + 1, string.len(currentWord)) --令当前词等于剩余部分

          result[nextArrayIndex] = tmp  --把截取的部分放进结果
          nextArrayIndex = nextArrayIndex + 1
          tmpString = ""
        end
      else  -- 如果词不超过限制
        result[nextArrayIndex] = stringutils.trim(tmpString) --把到现在为止的全部内容放进结果
        nextArrayIndex = nextArrayIndex + 1
        tmpString = ""  --重设缓存
      end

    else
      tmpString = tmpString .. stringutils.trim(currentWord) .. " "
      currentWord = ""
    end
    if ((not currentWord) or stringutils.trim(currentWord) == "") then currentWord = iter() end
  end

  if not(tmpString == "") then  --如果还没结束，就换行然后继续
    result[nextArrayIndex] = stringutils.trim(tmpString)
    nextArrayIndex = nextArrayIndex + 1
  end

  return result, (nextArrayIndex - 1)
end

function stringutils.getTextBoxDisplay(textToShow, cursorPosition, maxWidth)

  local lengthDiff = string.len(textToShow) - maxWidth --文字与容许长度的差距，负数将需要补足，正数则根据光标位置裁剪

  local firstHalf = ""  --光标前面的部分
  local cursorChar = "" --光标
  local nextHalf = ""   --光标后面的部分
  if(lengthDiff >= 0) then
    local halfSize = math.floor(maxWidth / 2) --一半的大小，用于决定显示哪一部分
    if(cursorPosition > halfSize) then  --如果前面至少有一半内容
      if(string.len(textToShow) - cursorPosition < halfSize) then --如果后面的内容能显示下，这意味着光标是在后半段
        nextHalf = string.sub(textToShow, cursorPosition + 1, string.len(textToShow))  --光标后面的部分
        cursorChar = string.sub(textToShow, cursorPosition, cursorPosition) -- 光标文字
        if(cursorChar == "") then cursorChar = " " end
        local remainingWidth = maxWidth - 1 - string.len(nextHalf)
        firstHalf = string.sub(textToShow, cursorPosition - remainingWidth, cursorPosition - 1) --光标前面的部分
      else  --如果后面内容显示不下，光标居中
        firstHalf = string.sub(textToShow, cursorPosition - 1 - halfSize, cursorPosition - 1)
        cursorChar = string.sub(textToShow, cursorPosition, cursorPosition)
        if(cursorChar == "") then cursorChar = " " end
        local remainingWidth = maxWidth - 1 - string.len(firstHalf)
        nextHalf = string.sub(textToShow, cursorPosition + 1, cursorPosition + remainingWidth)
      end
    else --如果前面内容不够
      firstHalf = string.sub(textToShow, 0, cursorPosition - 1)
      cursorChar = string.sub(textToShow, cursorPosition, cursorPosition)
      if(cursorChar == "") then cursorChar = " " end
      local remainingWidth = maxWidth - 1 - string.len(firstHalf)
      nextHalf = string.sub(textToShow, cursorPosition + 1, cursorPosition + remainingWidth)
    end
  else -- 如果文字比容许长度短
    firstHalf = string.sub(textToShow, 0, cursorPosition - 1)
    cursorChar = string.sub(textToShow, cursorPosition, cursorPosition)
    if(cursorChar == "") then cursorChar = " " end
    nextHalf = string.sub(textToShow, cursorPosition + 1, string.len(textToShow))
  end
  nextHalf = nextHalf .. string.rep(" ", math.min(0, maxWidth - string.len(firstHalf .. cursorChar .. nextHalf))) -- 补足任何空间
  return firstHalf, cursorChar, nextHalf
end

--字符串是否以特定词组开头
function stringutils.startswith(String, Start)
  return string.sub(String,1,string.len(Start))==Start
end


return stringutils
