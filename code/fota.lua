--[[
本demo 适用于 Air780E/Air780EG/Air600E
1. 需要 V1103及以上的固件
2. 需要 LuaTools 2.1.89 及以上的升级文件生成
]]

-- 使用合宙iot平台时需要这个参数
PRODUCT_KEY = "7ZMjnOzEGsYGJ1bVgavwdeKD28lqjgC0" -- 到 iot.openluat.com 创建项目,获取正确的项目id  官方教程https://doc.openluat.com/wiki/37?wiki_page_id=4578

sys = require "sys"
libfota = require "libfota"

-- 统一联网函数
sys.taskInit(function()
    -----------------------------
    -- 统一联网函数, 可自行删减
    if mobile then
        log.info("-------------------mobile联网成功!!!------------------------")
    elseif socket then
        -- 适配了socket库也OK, 就当1秒联网吧
        sys.timerStart(sys.publish, 1000, "IP_READY")
        log.info("-------------------socket联网成功!!!------------------------")
    else
        -- 其他不认识的bsp, 循环提示一下吧
        while 1 do
            sys.wait(1000)
            log.info("bsp", "本bsp可能未适配网络层, 请查证")
        end
    end
    -- 默认都等到联网成功
    sys.waitUntil("IP_READY")
    sys.publish("net_ready")
end)


function fota_cb(ret)
    log.info("fota", ret)
    if ret == 0 then
        rtos.reboot()--设备重启
    end
end

-- 使用合宙iot平台进行升级
sys.taskInit(function()
    sys.waitUntil("net_ready")
    libfota.request(fota_cb)
end)
sys.timerLoopStart(libfota.request, 3600000, fota_cb)

