--- 模块功能：MQTT客户端数据接收处理

_G.sys = require("sys")
_G.sysplus = require("sysplus")
require"projectConfig"
require "gnss"
require "sleep"
require "vbat_adc"


local nodata_Count = 0
local lbs_Count = 0
local gps_Count = 0

-----------------MQTT OUT---------------
 --数据发送的消息队列
local msgQueue = {} 

local function insertMsg(topic,payload,qos,user)
    sys.taskInit(function()
        if mqttc and mqttc:ready() then
            local pkgid 
            
            if server_select == "fairycloud" then
                pkgid = mqttc:publish(mqtt_pub_topic, payload, 0)
            else
                pkgid = mqttc:publish(aliyuncs_pub_topic, payload, 0)
            end

            -- TBD S定时上报数据
            sys.timerStart(autoDataStatus,_G.update_time)  
            sys.waitUntil(_G.GPS_Ggt_Topic,1*1000)  
            sys.publish(_G.Updata_OK)
        end
		
    end)

end

local function pubQos0TestCb(result)
    log.info("mqttOutMsg.pubQos0TestCbXXXXXXXXXXXXXXXXXXXXXXXXX",result)
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


-- 10s自动上报数据 默认
function autoDataStatus()

    local tmm1 = os.date()
    local tmm2 = os.date("%Y-%m-%d %H:%M:%S")
    local tmm3 = os.date("*t")

    local tm = rtc.get()
    local tjsondata,result,errinfo = json.decode(REPORT_DATA_TEMPLATE)
    if result and type(tjsondata)=="table" then
    
        local reporttime=os.date("%Y-%m-%d %H:%M:%S")
        local times=os.date("%Y-%m-%d %H:%M:%S")
        tjsondata["reporttime"] = reporttime;

        if server_select == "fairycloud" then
            if logFlag then
                tjsondata["cid"] = SRCCID;
            end
        else
            tjsondata["imei"] = aliyuncs_imei;
        end

        if ((_G.data_from == "LBS") or (_G.data_from == "GPS")) then
            tjsondata["longitude"] = _G.old_longitude;
            tjsondata["latitude"] = _G.old_latitude;

            -- 上报指令带上扩展命令回复
            if _G.cmd_ext == "platformquery" then
                tjsondata["cmd_ext"] = _G.cmd_ext;
                _G.cmd_ext = "no";
            end
        end


        -- tjsondata["temperature"] = _G.temperature;
        -- tjsondata["humidity"] = _G.humidity;

        tjsondata["vbat"]=  _G.vbat;
        tjsondata["electricity"]=  _G.electricity;
        tjsondata["version"]= _G.version;
        tjsondata["data_from"] = _G.data_from;

        tjsondata["gprs"] = _G.Mobile_Ss;
        tjsondata["satellite"] = _G.Gnss_Ss;
        
        if logFlag then
            local did = string.lower(crypto.md5(reporttime.."0"..random(1000)))
            tjsondata["did"] = did;
            tjsondata["log"] = locc;
            tjsondata["totalsatellite"] = _G.SatsNum;
            tjsondata["imei"] = aliyuncs_imei;

        end


    else
        log.info("testJson error",errinfo)
    end
    -----------------------decode测试------------------------

    pubQos0Send(json.encode(tjsondata)) --发送数据

    wdt.init(65000) -- 初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 60000) -- 21s喂一次狗


    -- 休眠模式和次数判断
    if devicemodel =="restdeep_deviceupdate" or devicemodel =="restdeep_platequery"  then
        
        -- 获取到了定位的数据
        if ( _G.data_from == "GPS") then
            gps_Count = gps_Count+1;
            log.info('GPS上报次数：gps_Count:',gps_Count )

        elseif ((_G.data_from == "LBS") ) then
            lbs_Count = lbs_Count+1;
            log.info('LBS上报次数：lbs_Count:',lbs_Count )

        else
            lbs_Count = 0
            gps_Count = 0
            nodata_Count = nodata_Count + 1;
            log.info('无数据上报次数：nodata_Count:',nodata_Count )

        end

        -- LBS:1分40S左右获取 GPS：30S  无信号：90S
        -- if gps_Count >=3 or lbs_Count >=5 or nodata_Count >=9 then
        if gps_Count >=1 or lbs_Count >=1 or nodata_Count >=9 then
            gps_Count = 0
            lbs_Count = 0
            nodata_Count = 0
            -- 断开MQTT
            mqttc:close()
            sys.publish("REST_SEND_RESTDEEP")
        end
        log.info("------------> MSGdevicemodel",devicemodel)



    end

end

--发送数据 传入数据
function pubQos0Send(sedData)

    log.info("sedData:",sedData)
    if server_select == "fairycloud" then
        insertMsg(mqtt_pub_topic,sedData,0,{cb=pubQos0TestCb})
    else
        insertMsg(aliyuncs_pub_topic,sedData,0,{cb=pubQos0TestCb})
    end


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


function CLIEND_SEND_DATA()
    sys.taskInit(function()
        
        autoDataStatus()
       
    end)

end
-----------------MQTT IN------------------------------------------

--- MQTT客户端数据接收处理
function SERVER_SEND_DATA(topic, payload)

    if topic == mqtt_sub_topic then

        local tjsondata,result,errinfo = json.decode(payload)
        if result and type(tjsondata)=="table" then

            --开始数据解析
            local cmdType = tjsondata["cmdtype"];
            local cmdcontroll = "cmd_controll";
            local cmdstatus = "cmd_status";
            local cmdstatusack = "cmd_statusack";
            local did = tjsondata["did"];
            local tm = rtc.get()
        


            if cmdType == cmdcontroll then
            
                local cmddata = tjsondata["cmddata"];
                local sensorname = cmddata["sensorname"];
                local sensorcmd= cmddata["sensorcmd"];
                local extdata= cmddata["extdata"];
          
                if (sensorname == "status") then
                    if(sensorcmd == "open") then
                        log.info("status");
                        -- 基础数据查询 底部默认会上报数据，不用在这里单独设置
                        -- autoDataStatus()
                    end
                elseif (sensorname == "restart") then
                    if(sensorcmd == "open") then
                        log.info("restart");
                        pm.reboot()
                    end
                elseif (sensorname == "poweroff") then
                    if(sensorcmd == "open") then
                        log.info("------------>poweroff");
                        pm.shutdown()
                    end
                elseif (sensorname == "deviceconfig") then
                    if(sensorcmd == "open") then
                        log.info("get deviceconfig");
                        _G.devicemodel = extdata["devicemodel"];
                        _G.update_time = extdata["update_time"];
                        _G.deeprest_time = extdata["deeprest_time"];

                        if devicemodel ~= 'awake_normal' then
                            sys.publish("REST_SEND_RESTDEEP")
                        end

                    end
                else
                    log.info(sensorname);
                end	
       
                ----进行远控数据返回操作
               local sdsondata,result,errinfo = json.decode(REPORT_CONTROLLACK_TEMPLATE)
                if result and type(sdsondata)=="table" then

                    local tm = rtc.get()
                    local reporttime = string.format("%04d-%02d-%02d %02d:%02d:%02d", tm.year, tm.mon, tm.day, tm.hour+8, tm.min, tm.sec)
                    
                    sdsondata["reporttime"] = reporttime;
                    sdsondata["cid"] = SRCCID;
                    sdsondata["did"] = did;

                    pubQos0Send(json.encode(sdsondata)) --发送数据

                else
                    log.info("testJson.decode error",errinfo)
                end
				
				autoDataStatus()
				
                --结束发送
            elseif cmdType == cmdstatus then
                log.info("cmd_status");
                    -- 基础数据查询
                    autoDataStatus()

            elseif cmdType == cmdstatusack then
                log.info("cmd_statusack");
        
            else
                log.info(cmdType);
        
            end
        
            --数据解析结束 返回服务端信息

        else
            log.info("testJson.decode error",errinfo)
        end

    end

end

-- 自动发送数据到服务器
sys.subscribe("CLIEND_SEND_DATA",CLIEND_SEND_DATA)

-- 订阅GPS获取成功的消息
sys.subscribe("GPS_GET_SUCCESS",CLIEND_SEND_DATA)


-- 订阅 
sys.subscribe("SERVER_SEND_DATA",SERVER_SEND_DATA)

--手动返回一个table，包含了上面的函数
return {
    init = init,
    unInit = unInit,
    procaa = procaa,
}
