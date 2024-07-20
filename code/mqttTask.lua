-- sys库是标配
_G.sys = require("sys")
--[[特别注意, 使用mqtt库需要下列语句]]
_G.sysplus = require("sysplus")
require"projectConfig"
--require"ntp"

local mqttInMsg = require("mqttInMsg")

local ready = false

local function cbFnc(body)
  
    if  body then
        local data = body
        -- log.info("testHttp.cbFnc","bodyLen="..body)

        local tjsondata,result,errinfo = json.decode(body)
        if result and type(tjsondata)=="table" then
            -- log.info("status:", tjsondata["status"])
            -- log.info("msg:",  tjsondata["msg"])

            --开始数据解析
            local status = tjsondata["status"]
            local errorCode = tjsondata["errorCode"];
            local msg = tjsondata["msg"];

            if status then
                -- body
                local  data = tjsondata["data"]
                _G.SRCCID = data["cid"];
                _G.appkey = data["appkey"];
                _G.secretkey = data["secretkey"];

                _G.deviceid_auth = data["cid"];
                _G.username_auth = data["cid"];
                _G.password_auth = _G.projectkey ;


                log.info('SRCCID',SRCCID )

            else
                -- body
                log.info('msg:',msg )
    
            end

        end    

    end
end

--- MQTT连接是否处于激活状态
-- @return 激活状态返回true，非激活状态返回false
-- @usage mqttTask.isReady()
function isReady()
    return ready
end

if type(rtos.openSoftDog)=="function" then
    rtos.openSoftDog(600000)
end

function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c)
     return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end 


function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
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

    result = os.time({
        day = tonumber(tempTable[3]),
        month = tonumber(tempTable[2]),
        year = tonumber(tempTable[1]),
        hour = tonumber(tempTable[4]),
        min = tonumber(tempTable[5]),
        sec = tonumber(tempTable[6])
    })
    return result
end

--------------------------------------------------
-- socket.sntp()

-- sys.subscribe("NTP_UPDATE", function()
-- 	log.info("sntp", "time", os.date())
-- end)

-- sys.subscribe("NTP_ERROR", function()
-- 	log.info("socket", "sntp error")
-- 	socket.sntp()
-- end)

--------------------------------------------------

--启动MQTT客户端任务
-- function getDeviceInfo()
sys.taskInit(function()

    -- 默认都等到联网成功
    sys.waitUntil("IP_READY")
    sys.wait(1000)
	--uart.setup(1,115200,8,1,uart.None)
	
    local retryConnectCnt = 0
    while true do
       
        local imei = mobile.imei()
        log.info('imei',imei)
        local maxtar = string.upper(crypto.md5(imei,#imei))
        local  macstr =  string.sub(maxtar, 1, 12)
        local  mac = string.sub(macstr, 1, 2)
        for i=3,#macstr,2 do
            mac = mac .. ":" .. string.sub(macstr, i, i+1)

        end

        log.info("mac:",mac)

        while SRCCID =="" do
            -- body
            local did = "4ee1562359b5bb25d1095c21819d388a"
            local nonce="c0b0a3906c19dde0995abbd061168c0a"
            -- local signt=os.time() ..''
            local tm = rtc.get()
            --local tmm = os.date()

            -- log.info("------------>tm", json.encode(tm))
            -- log.info("------------>tmm", json.encode(tmm))

            --local reporttime=tmm
 
            local reporttime = string.format("%04d-%02d-%02d %02d:%02d:%02d", tm.year, tm.mon, tm.day, tm.hour, tm.min, tm.sec)
            --local reporttime=os.date("%Y-%m-%d %H:%M:%S")
            log.info("reporttime:",reporttime)

            local signt= dataToTimeStamp(reporttime) .. "000"

            local str5 = "api/getDeviceByMac_appkey=" .. appkey.."_did=".. did.. "_mac=" .. mac .."_nonce="..nonce.."_projectkey="..projectkey.. "_signt="..signt.."_version=".. version.."_".. secretkey;
            
            log.info("str5:",str5)

            local str6 = string.urlEncode(str5)
            log.info("str6:",str6)

            local sign =  string.lower (crypto.md5(str6,#str6))
            log.info("sign:",sign)

            local str = string.format('%s?appkey=%s&did=%s&mac=%s&nonce=%s&projectkey=%s&signt=%s&version=%s&sign=%s',server_api,appkey,did,mac,nonce,projectkey,signt,version,sign)
            log.info("str:",str)

            -- http.request("GET",str,nil,nil,nil,nil,cbFnc)

            local code, headers, body = http.request("GET",str,nil,nil,nil,nil,cbFnc).wait()
            log.info("http.get", code, headers, body)
            cbFnc(body)

            sys.wait(3000)

        end                 

        log.info('SRCCID',SRCCID)

        if  SRCCID ~= "" then
            local imei = mobile.imei()
            log.info('imeia',imei)

            --_G.mqttc = mqtt.create(nil, mqttserverip, mqttserverport, false, ca_file)
            _G.mqttc = mqtt.create(nil, mqttserverip, mqttserverport, false, ca_file)

         
            --mqttc:auth(SRC2C2WLB00000025,Gunter,qwerty123) -- client_id必填,其余选填
            mqttc:auth(deviceid_auth,username_auth,password_auth,true) --JSR1454DMY
            mqttc:keepalive(60) -- 默认值240s
            mqttc:autoreconn(true, 6000) -- 自动重连机制

            mqttc:on(function(mqtt_client, event, data, payload)
                -- 用户自定义代码
                log.info("mqtt", "event", event, mqtt_client, data, payload)
                if event == "conack" then
                    -- 联上了
                    mqttInMsg.init()

                    sys.publish("mqtt_conack")
                    mqtt_client:subscribe({[topic_server_home..SRCCID]=0, [topic_sys_message]=0})--单主题订阅

                    -- mqtt_client:subscribe({[topic1]=1,[topic2]=1,[topic3]=1})--多主题订阅
                elseif event == "recv" then
                    --sys.publish("mqtt_payload", data, payload)
                    sys.publish("SERVER_SEND_DATA", data, payload)

                elseif event == "sent" then
                    -- log.info("mqtt", "sent", "pkgid", data)
                elseif event == "disconnect" then
                    -- 非自动重连时,按需重启mqttc
                    mqtt_client:connect()
                end
            end)

            -- mqttc自动处理重连, 除非自行关闭
            mqttc:connect()
            sys.waitUntil("mqtt_conack")
--            while true do

                -- 演示等待其他task发送过来的上报信息
--                local ret, topic, data, qos = sys.waitUntil("APP_SOCKET_SEND_DATA", 300000)
--                if ret then
                    -- 提供关闭本while循环的途径, 不需要可以注释掉
--                    if topic == "close" then break end
--                   mqttc:publish(topic, data, qos)
--                end
                -- 如果没有其他task上报, 可以写个空等待
            sys.wait(60000000)
--            end
            mqttc:close()
            mqttc = nil

        end

    end

end)

--ntp.timeSync()