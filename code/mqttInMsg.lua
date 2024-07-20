--- 模块功能：MQTT客户端数据接收处理

_G.sys = require("sys")
_G.sysplus = require("sysplus")
_G.GPS_Updata=false
require"projectConfig"
require "gnss"
require "sleep"
require "vbat_adc"

-- 保存时间戳6位
local Timestamp = {0x17,0,0,0,0,0}

-----------------MQTT OUT---------------
 --数据发送的消息队列
local msgQueue = {} 

local function insertMsg(topic,payload,qos,user)
    sys.taskInit(function()
        if mqttc and mqttc:ready() then
            local pkgid = mqttc:publish(mqtt_pub_topicsss..SRCCID, payload, 0)
            sys.timerStart(autoDataStatus,10000)  
            sys.waitUntil(_G.GPS_Ggt_Topic,10*1000)  
            sys.publish(_G.Updata_OK)
        end
		
    end)

end

local function pubQos0TestCb(result)
    log.info("mqttOutMsg.pubQos0TestCb",result)
    if result then  sys.timerStart(autoDataStatus,1000) end
end

function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Lua equivalent of the random function in C

-- Check if randomSeed was called and use software PRNG if needed
local function random(howbig)
    if howbig == 0 then
        return 0
    end

    if howbig < 0 then
        return random(0, -howbig)
    end

    -- Generate random value using hardware or software PRNG
    local val = (s_useRandomHW) and esp_random() or math.random()
    
    return val % howbig
end

-- Function to generate random number within a range
local function random_range(howsmall, howbig)
    if howsmall >= howbig then
        return howsmall
    end

    local diff = howbig - howsmall
    return random(diff) + howsmall
end


-- 日期时间转时间戳 注意输出格式是xxxx-02-12 09:30:12
-- 参数可以是  “xxxx-02-12 09:30:12” 或者 表{2019,2,12,9,30,12}
function dataToTimeStamp(dataStr)
    local result = -1
    local tempTable = {}

    if dataStr == nil then
        error("传递进来的日期时间参数不合法")
    elseif type(dataStr) == "string" then
        dataStr = trim(dataStr)
        for v in string.gmatch(dataStr, "%d+") do
            tempTable[#tempTable + 1] = v
        end
    elseif type(dataStr) == "table" then
        tempTable = dataStr
    else
        error("传递进来的日期时间参数不合法")
    end
    tempTable[4] = tonumber(tempTable[4]) - 8;
    result = os.time({
        day = tonumber(tempTable[3]),
        mon = tonumber(tempTable[2]),
        year = tonumber(tempTable[1]),
        hour = tonumber(tempTable[4]),
        min = tonumber(tempTable[5]),
        sec = tonumber(tempTable[6])
    })
    return result
end

-- socket.sntp()

-- sys.subscribe("NTP_UPDATE", function()
-- 	log.info("sntp", "time", os.date())
-- end)

-- sys.subscribe("NTP_ERROR", function()
-- 	log.info("socket", "sntp error")
-- 	socket.sntp()
-- end)

-- 10s自动上报数据 默认
function autoDataStatus()

    
    local tmm1 = os.date()
    local tmm2 = os.date("%Y-%m-%d %H:%M:%S")
    local tmm3 = os.date("*t")

    local tm = rtc.get()
    local tjsondata,result,errinfo = json.decode(REPORT_DATA_TEMPLATE)
    if result and type(tjsondata)=="table" then
    
    
        tjsondata["deviceid"] = SRCCID;
        tjsondata["project"] = project;
		tjsondata["projectkey"] = projectkey;
        tjsondata["cid"] = SRCCID;
        tjsondata["password"] = projectkey;

        local reporttime=os.date("%Y-%m-%d %H:%M:%S")
        local times=os.date("%Y-%m-%d %H:%M:%S")
        --local times = string.format("%04d-%02d-%02d %02d:%02d:%02d", tm.year, tm.mon, tm.day, tm.hour, tm.min, tm.sec)
        --local reporttime = string.format("%04d-%02d-%02d %02d:%02d:%02d", tm.year, tm.mon, tm.day, tm.hour+8, tm.min, tm.sec)
        log.info("------------>reporttime",reporttime)
        -- log.info("------------>tmm1",tmm1)
        -- log.info("------------>tmm2",tmm2)
        -- log.info("------------>tmm3",tmm3)
        tjsondata["reporttime"] = reporttime;

        -- 新增签名算法
        local did = string.lower(crypto.md5(reporttime.."0"..random(1000)))
        local cid = SRCCID
        local nonce = string.lower(crypto.md5(reporttime.."0"..random(1000)))
        local signt= dataToTimeStamp(times) .. "000"
        local str6 =  did.."_"..cid.."_"..nonce.."_"..signt.."_"..appkey.."_"..secretkey
        local sign =  string.lower (crypto.md5(str6,#str6))
		
        tjsondata["appkey"] = appkey;
        tjsondata["did"] = did;
        tjsondata["nonce"] = nonce;
        tjsondata["signt"] = signt;
        tjsondata["sign"] = sign;
        tjsondata["version"] = version;


        tjsondata["temperature"] = "25.4";

        tjsondata["longitude"] = _G.sslng;
        tjsondata["latitude"] = _G.sslat;
        tjsondata["log"] = locc;
        tjsondata["data_from"]=data_from;
        tjsondata["electricity"]=svbat;
        tjsondata["version"]=_G.VERSION;
     
    else
        log.info("testJson error",errinfo)
    end
    -----------------------decode测试------------------------

    pubQos0Send(json.encode(tjsondata)) --发送数据

    wdt.init(25000) -- 初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 21000) -- 3s喂一次狗

end

--发送数据 传入数据
function pubQos0Send(sedData)

    log.info("sedData:",sedData)
    
    insertMsg(mqtt_pub_topicsss..SRCCID,sedData,0,{cb=pubQos0TestCb})
end

--- 初始化“MQTT客户端数据发送”
-- @return 无
-- @usage mqttOutMsg.init()
function init()
    autoDataStatus()
end

--- 去初始化“MQTT客户端数据发送”
-- @return 无
-- @usage mqttOutMsg.unInit()
function unInit()
    sys.timerStop(autoDataStatus)
end


--- MQTT客户端数据发送处理
-- @param mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttOutMsg.proc(mqttClient)
--function sedproc(mqttClient)
--    while #msgQueue>0 do
--        local outMsg = table.remove(msgQueue,1)
--        local result = mqttClient:publish(outMsg.t,outMsg.p,outMsg.q)
--        if outMsg.user and outMsg.user.cb then outMsg.user.cb(result,outMsg.user.para) end
--        if not result then return end
--    end
--    return true
--end

-----------------MQTT IN------------------------------------------
--[[
--- MQTT客户端数据接收处理
function SERVER_SEND_DATA(topic, payload)

    if topic == topic_server_home..SRCCID then

        local tjsondata,result,errinfo = json.decode(payload)
        if result and type(tjsondata)=="table" then

            --开始数据解析
            local cmdType = tjsondata["cmdtype"];
            local controll = "cmd_controll";
            local status = "cmd_status";
            local statusack = "cmd_statusack";
            local did = tjsondata["did"];
            local tm = rtc.get()
        
            if cmdType == controll then
            
                --log.info("cmd_controll");
                local cmddata = tjsondata["cmddata"];
                local sensorname = cmddata["sensorname"];
                local sensorcmd= cmddata["sensorcmd"];
                ----[
				if (sensorname == "curtain_1") then
				    log.info(sensorcmd);
                    if(sensorcmd == "open") then
					
                        uart.write(uartid,'1401')
						log.info('1401')
					elseif(sensorcmd == "close") then
					
						uart.write(uartid,'1400')
						log.info('1400')
					else
                        log.info(sensorcmd);
                    end
				elseif (sensorname == "curtain_2") then 
                    log.info(sensorcmd);
                    if(sensorcmd == "open") then
					
                        uart.write(uartid,'1501')
						log.info('1501')
					elseif(sensorcmd == "close") then
					
						uart.write(uartid,'1500')
						log.info('1500')
					else
                        log.info(sensorcmd);
                    end
					
				elseif (sensorname == "curtain_3") then 
                    log.info(sensorcmd);
                    if(sensorcmd == "open") then
					
                        uart.write(uartid,'1601')
						log.info('1601')
					elseif(sensorcmd == "close") then
					
						uart.write(uartid,'1600')
						log.info('1600')
					else
                        log.info(sensorcmd);
                    end
					
				elseif (sensorname == "status") then

                    if(sensorcmd == "open") then
                        
                        log.info("status");
                          -- 基础数据查询
                        autoDataStatus()
                    end
                else
                    log.info(sensorname);
                end	
                ----]
                ----进行远控数据返回操作
               local sdsondata,result,errinfo = json.decode(REPORT_CONTROLLACK_TEMPLATE)
                if result and type(sdsondata)=="table" then

                    local tm = rtc.get()

                    local reporttime = string.format("%04d-%02d-%02d %02d:%02d:%02d", tm.year, tm.mon, tm.day, tm.hour+8, tm.min, tm.sec)
                    
                    sdsondata["reporttime"] = reporttime;
                    sdsondata["cid"] = SRCCID;
                    sdsondata["did"] = did;
                    sdsondata["project"] = project;
					sdsondata["projectkey"] = projectkey;
                      -- 新增签名算法
                    -- local did = "4ee1562359b5bb25d1095c21819d388a"
                    local cid = SRCCID
                    local nonce="c0b0a3906c19dde0995abbd061168c0a"
                    local signt= dataToTimeStamp(reporttime) .. "000"
                    local str6 =  did.."_"..cid.."_"..nonce.."_"..signt.."_"..appkey.."_"..secretkey
                    local sign =  string.lower (crypto.md5(str6,#str6))
                    sdsondata["appkey"] = appkey;
                    sdsondata["nonce"] = nonce;
                    sdsondata["signt"] = signt;
                    sdsondata["sign"] = sign;
                    sdsondata["version"] = version;

                    

                    pubQos0Send(json.encode(sdsondata)) --发送数据

                else
                    log.info("testJson.decode error",errinfo)
                end
				
				autoDataStatus()
				
                --结束发送
            elseif cmdType == status then
                log.info("cmd_status");
                    -- 基础数据查询
                    autoDataStatus()
        
            elseif cmdType == statusack then
                log.info("cmd_statusack");
        
            else
                log.info(cmdType);
        
            end
        
            --数据解析结束 返回服务端信息

        else
            log.info("testJson.decode error",errinfo)
        end

    elseif data.topic == topic_sys_message then
        -- body

    end

end
--]]

-- 订阅 
--sys.subscribe("SERVER_SEND_DATA",SERVER_SEND_DATA)

--手动返回一个table，包含了上面的函数
return {
    init = init,
    unInit = unInit,
    procaa = procaa,
}
