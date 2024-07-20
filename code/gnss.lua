-- LuaTools需要PROJECT和VERSION这两个信息
-- PROJECT = "gnsstest"
-- VERSION = "1.0.1"

-- sys库是标配
local sys = require("sys")
local lbsLoc2 = require("lbsLoc2")
require("sysplus")
require("sleep")
--require("mqttInMsg")
-- Air780E的AT固件默认会为开机键防抖,  导致部分用户刷机很麻烦
if rtos.bsp() == "EC618" and pm and pm.PWK_MODE then
    pm.power(pm.PWK_MODE, false)
end

local Gps_Get_Num=0
local gps_uart_id = 2
local mqttc = nil






-- libgnss库初始化
libgnss.clear() -- 清空数据,兼初始化

-- 串口初始化
uart.setup(gps_uart_id, 115200)

-- TODO 做成agnss.lua  处理星历文件
function exec_agnss()
    --mobile.flymode(0, false)--关闭飞行模式
    --log.info("-------------------->>关闭飞行模式<<----------------------") 
    local url = "http://download.openluat.com/9501-xingli/HXXT_GPS_BDS_AGNSS_DATA.dat"
    local dat_done = false
    sys.waitUntil("NTP_UPDATE", 1000)
    if io.fileSize("/6228.bin") > 1024 then  --判断星历文件
        log.info("------------------使用已有的星历文件-----------------")
        local date = os.date("!*t")
        log.info("当前系统时间", os.date())
        if date.year < 2025 then  --2023     --判断时间戳 
            date = os.date("!*t")
        end
        if date.year > 2023 then  --2022
            local tm = io.readFile("/6226_tm")
            if tm then
                local t = tonumber(tm)
                if t and (os.time() - t < 3600*2) then  --判断星历是否过期
                    log.info("agnss", "重用星历文件")
                    local body = io.readFile("/6228.bin") --将读取的 AGNSS 数据文件 /6228.bin 分段发送到 GPS 模块
                    for offset = 1, #body, 512 do
                        uart.write(gps_uart_id, body:sub(offset, offset + 511))
                        sys.wait(100)
                    end
                    dat_done = true                       --gps模块获取到了星历数据
                else
                    log.info("星历过期了")
                end
            else
                log.info("星历时间有问题")
            end
        else
            log.info("时间有问题")
        end
    end
    if http and not dat_done then     --gps模块无星历数据，需下载
        -- AGNSS 已调通
        while 1 do
            log.info("---------------重新下载星历文件-----------------")
            local code, headers, body = http.request("GET", url).wait()
            log.info("gnss", "AGNSS", code, body and #body or 0)
            if code == 200 and body and #body > 1024 then 
                for offset = 1, #body, 512 do  --将下载的星历数据发送给GPS模块
                    log.info("gnss", "AGNSS", "write >>>", #body:sub(offset, offset + 511)) 
                    uart.write(gps_uart_id, body:sub(offset, offset + 511))
                    sys.wait(100) -- 等100ms反而更成功
                end
                -- sys.waitUntil("UART2_SEND", 1000)
                io.writeFile("/6228.bin", body) --保存星历文件  
                local date = os.date("!*t")
                if date.year > 2023 then
                    io.writeFile("/6226_tm", tostring(os.time()))
                end
                break
            end
            sys.wait(60 * 1000)
        end
    end
    sys.wait(20)
    -- "$AIDTIME,year,month,day,hour,minute,second,millisecond"
    local date = os.date("!*t")
    if date.year > 2022 then
        local str = string.format("$AIDTIME,%d,%d,%d,%d,%d,%d,000", date["year"], date["month"], date["day"],
            date["hour"], date["min"], date["sec"])
        log.info("gnss!!!", str)
        uart.write(gps_uart_id, str .. "\r\n")
        sys.wait(20)
    end
    -- 读取之前的位置信息
    local gnssloc = io.readFile("/gnssloc")  --读取之前的GPS数据,写给GPS模块以快速定位
    if gnssloc then
        str = "$AIDPOS," .. gnssloc
        log.info("POS", str) 
        uart.write(gps_uart_id, str .. "\r\n")
        str = nil
        gnssloc = nil
    else
        -- TODO 发起基站定位
        uart.write(gps_uart_id, "$AIDPOS,3432.70,N,10885.25,E,1.0\r\n")
        log.info("------------------发起基站定位----------------------")
        
    end
    --mobile.flymode(0, true)--飞行模式
    --log.info("-------------------->>飞行模式<<----------------------") 
end

function lbsLoc()
    sys.waitUntil("IP_READY", 30000)
    -- mobile.reqCellInfo(60)
    -- sys.wait(1000)
    --while mobile do -- 没有mobile库就没有基站定位
        mobile.reqCellInfo(15)
        sys.waitUntil("CELL_INFO_UPDATE", 3000)
        local lbs_lat, lbs_lng, t = lbsLoc2.request(5000)
        -- local lat, lng, t = lbsLoc2.request(5000, "bs.openluat.com")
        if lbs_lat == nil then
            data_from="No data"
            sys.publish(_G.GPS_Ggt_Topic)
            sys.waitUntil(_G.Updata_OK,10*1000)
            log.info("-------------------->>基站定位失败,放弃上传数据!!!<<----------------------") 
        else     
            data_from="LBS"
            _G.sslat=lbs_lat 
            _G.sslng=lbs_lng
            sys.publish(_G.GPS_Ggt_Topic)
            sys.waitUntil(_G.Updata_OK,10*1000)
            log.info("------------>lbsLoc2", lbs_lat, lbs_lat, (json.encode(t or {})))
            log.info("-------------------->>基站定位成功!!!<<----------------------") 
            sys.wait(6000)
        end
    --end
end


sys.taskInit(function()
    --sys.waitUntil("IP_READY")------------------------------------------------------------------------->>>
    -- Air780EG默认波特率是115200
    while true do
        local nmea_topic = "/gnss/" .. mobile.imei() .. "/up/nmea"  --简单的字符串拼接
        log.info("GPS", "start")
        pm.power(pm.GPS, true)
        -- 本函数一般用于调试, 用于获取底层实际收到的数据  例
        -- libgnss.on("raw", function(data)
        --     log.info("GNSS", data)
        -- end)
        libgnss.on("raw", function(data)                             
            sys.publish("uplink", nmea_topic, data, 1)
        end)
        -- 调试日志,可选,开启调试, 会输出GNSS原始数据到日志中-------------------------------------------------
        --libgnss.debug(true)
        sys.wait(200) -- GPNSS芯片启动需要时间,大概150ms
        
        -- 绑定uart,底层自动处理GNSS数据
        -- 这里延后到设置命令发送完成后才开始处理数据,之前的数据就不上传了
        libgnss.bind(gps_uart_id)
        log.debug("提醒", "室内无GNSS信号,定位不会成功, 要到空旷的室外,起码要看得到天空")
        exec_agnss()
        sys.wait(100)
    end
end)

sys.taskInit(function()
    while 1 do
        sys.wait(200)

        
        local loc=libgnss.getRmc(1)
        locc=json.encode(loc)--其他文件要调用的量不要加local!!!
        




        log.info("-------------------->>以下打印的是原始数据<<----------------------")
        log.info("locc------->",locc)

        -- log.info("slat1------->",slat1)
        -- log.info("slng1------->",slng1)
        -- log.info("slat2------->",slat2) 
        -- log.info("slng2------->",slng2)
        

        if loc.valid==true then

            log.info("-------------------->>获取到了有效的数据,以下打印的是原始数据和解析后的经纬度<<----------------------")
            log.info("locc------->",locc)
            log.info("lat------->",lat)
            log.info("lng------->",lng)
            log.info("latt------------>",latt)
            log.info("lngg------------>",lngg)
            log.info("type of lat----->",type(lat))

            local lat=loc.lat
            local lng=loc.lng
            local latt=lat/10000000--除法，保留小数--//除法，只保留整数
            local lngg=lng/10000000

            _G.sslat=json.encode(latt)
            _G.sslng=json.encode(lngg)
            
            -- local slat1=lat//10000000
            -- local slng1=lng//10000000
            -- local slat2=lat-slat1*10000000
            -- local slng2=lng-slng1*10000000

            -- local sslat1=tostring(slat1)
            -- local sslat2=tostring(slat2)
        
            -- local sslng1=tostring(slng1)
            -- local sslng2=tostring(slng2)
            
            -- -- sslat=sslat1.."."..sslat2
            -- -- sslng=sslng1.."."..sslng2
           

            -- sslat=json.encode(latt)
            -- sslng=json.encode(lngg)

            log.info("-------------------->>以下打印的是经纬度的字符串形式<<----------------------") 
            log.info("sslat------->",_G.sslat)
            log.info("sslng------->",_G.sslng)

            log.info("-------------------->>GPS定位成功！！！<<----------------------") 
            data_from="GPS"
            sys.publish(_G.GPS_Ggt_Topic)
            

        elseif loc.valid==false then
            
            sys.publish(_G.GPS_Ggt_Topic_F)
            Gps_Get_Num=Gps_Get_Num+1
        end

        if Gps_Get_Num==300 then
            Gps_Get_Num=0
            log.info("-------------------->>GPS定位失败，改用基站定位！！！<<----------------------") 
            mobile.flymode(0, false)--关闭飞行模式
            log.info("-------------------->>关闭飞行模式<<----------------------") 
            lbsLoc()
        end

        log.info("------------------->>调试信息<<-----------------------") 
        log.info("GPS_Updata--------->",_G.GPS_Updata)
        log.info("Gps_Get_Num--------->",Gps_Get_Num)
        log.info("------------------->>调试信息打印完毕<<-----------------------") 

  
        -- log.info("------------------------------------------") 
        -- log.info("sys", rtos.meminfo("sys"))
        -- log.info("lua", rtos.meminfo("lua"))
        --sys.wait(1000)
    end
end)

-- 订阅GNSS状态编码
sys.subscribe("GNSS_STATE", function(event, ticks)
    -- event取值有 
    -- FIXED 定位成功
    -- LOSE  定位丢失
    -- ticks是事件发生的时间,一般可以忽略
    local onoff = libgnss.isFix() and 1 or 0
    --log.info("GNSS", "LED", onoff)
    --gpio.set(LED_GNSS, onoff)
    log.info("gnss", "state", event, ticks)
    if event == "FIXED" then
        local locStr = libgnss.locStr()
        log.info("gnss", "locStr", locStr)

        if locStr then
            io.writeFile("/gnssloc", locStr)
        end
    end
end)

sys.taskInit(function()
    while 1 do
        sys.wait(3600 * 1000) -- 一小时检查一次
        local fixed, time_fixed = libgnss.isFix()
        if not fixed then
            exec_agnss()
        end
    end
end)


