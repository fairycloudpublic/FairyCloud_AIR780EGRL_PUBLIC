-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "Locators"
_G.VERSION = "1.0.7"
--[[
本demo需要mqtt库, 大部分能联网的设备都具有这个库
mqtt也是内置库, 无需require
]]

-- sys库是标配
_G.sys = require("sys")
--[[特别注意, 使用mqtt库需要下列语句]]
_G.sysplus = require("sysplus")

require"projectConfig"
--加载MQTT功能测试模块
require "mqttTask"
require "gnss"
require "sleep"
require "vbat_adc"
require "fota"

sys.taskInit(function()
    while 1 do
        sys.wait(500)
        log.info("fota", "------------>VERSION", VERSION)
    end
end)

-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
