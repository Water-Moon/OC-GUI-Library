

local widgetButton = require("widgetButton")

widgetToggleButton = {
    callBackOff = nil
}

setmetatable(widgetToggleButton, {__index = widgetButton})