PROJECT = "gnss"
VERSION = "1.0.0"

-- sys库是标配
local lbsLoc = require("lbsLoc")
local lbsLoc2 = require("lbsLoc2")
local sys = require("sys")
require("sysplus")

-- GPS定位失败次数，超过10次就LBS定位
local Gps_Get_Num=0
local Gnss_HistoricalNum=0
local Wifi_Num=0
local Wifi_Num_Max=0
local gps_uart_id = 2     --780eg 

local mqttc = nil

local lla = {
    lat,
    lng
}

libgnss.clear()

uart.setup(gps_uart_id, 115200)


function exec_agnss()
    if http then
        -- AGNSS 已调通
        while 1 do
            local code, headers, body = http.request("GET", "http://download.openluat.com/9501-xingli/CASIC_data.dat").wait()

            if code == 200 and body and #body > 1024 then

                for offset=1,#body,512 do
                    uart.write(gps_uart_id, body:sub(offset, offset + 511))
                    sys.wait(100)
                end

                io.writeFile("/6228.bin", body)
                break
            end
            sys.wait(60*1000)
        end
    end
    sys.wait(20)


    local str = io.readFile("/gnssrmc")
    if str then

        local dt = os.date("!*t")
        lla = json.decode(str)
        -- 然后是辅助定位坐标
        -- 来源有很多方式:
        -- 1. 从历史定位数据得到, 例如之前定位成功后保存到本地文件系统了
        -- 2. 通过基站定位或者wifi定位获取到
        -- 3. 通过IP定位获取到大概坐标
        -- 坐标系是WGS84, 但鉴于是辅助定位,精度不是关键因素
        local aid = libgnss.casic_aid(dt, lla)
        uart.write(gps_uart_id, aid.."\r\n")
        str = nil
    else
        -- TODO 发起基站定位

        log.info("---------------->STR_nil")
    end
end


local function getLocCb(result, lat, lng, addr, time, locType)

    -- 获取经纬度成功
    if result == 0 then
        if locType == 0 then
            log.info("------------>基站定位成功",lat,lng)
            _G.data_from="LBS"
        elseif locType == 255 then
            log.info("------------>wifi定位成功",lat,lng)
            _G.data_from="Wifi"
        else
            _G.data_from="NoData"
            log.info("------------>wifi和基站定位失败",lat,lng)
        end
        _G.old_longitude=lng
        _G.old_latitude=lat

        if devicemodel ~= 'awake_normal' then
            sys.publish("GPS_GET_SUCCESS")
        end

    else
        log.info("------------>混合定位失败")
    end
end

sys.subscribe("WLAN_SCAN_DONE", function ()
    local results = wlan.scanResult()
    log.info("-----------------#results>",#results)
    log.info("scan", "results", #results)
    if #results > 0 then
        local reqWifi = {}
        for k,v in pairs(results) do
            log.info("scan", v["ssid"], v["rssi"], v["bssid"]:toHex())
            local bssid = v["bssid"]:toHex()
            bssid = string.format ("%s:%s:%s:%s:%s:%s", bssid:sub(1,2), bssid:sub(3,4), bssid:sub(5,6), bssid:sub(7,8), bssid:sub(9,10), bssid:sub(11,12))
            reqWifi[bssid]=v["rssi"]
        end

        lbsLoc.request(getLocCb,nil,nil,nil,nil,nil,nil,reqWifi)
    else
        Wifi_Num=Wifi_Num+1
        log.info("------------>Wifi_Num",Wifi_Num)
        if Wifi_Num>=Wifi_Num_Max then
            Wifi_Num=0
            log.info("------------>wifi扫描失败,改用基站定位")
            lbsLoc.request(getLocCb) -- 没有wifi数据,进行普通定位
        end
    end
end)


sys.taskInit(function()

    while true do
        if  not (devicemodel == "" and cmd_ext == '') then
            break;
        end
        sys.wait(100)
     end

    
    while true do
        if  not (devicemodel == "restdeep_platequery" and cmd_ext == 'no') then
            break;
        end
        sys.wait(100)
     end



    -- Air780EG工程样品的GPS的默认波特率是9600, 量产版是115200,以下是临时代码
    log.info("GPS", "start")

    --pm.power(pm.GPS, true)
    -- 绑定uart,底层自动处理GNSS数据
    -- 第二个参数是转发到虚拟UART, 方便上位机分析
    --uart.write(gps_uart_id, "$PCAS04,2*1B\r\n")
    --sys.wait(100)
    libgnss.bind(gps_uart_id, uart.VUART_0)
    libgnss.on("raw", function(data)

    end)
    sys.wait(200) -- GPNSS芯片启动需要时间
    -- 增加显示的语句
    sys.wait(200) -- GPNSS芯片启动需要时间,大概150ms
    uart.write(gps_uart_id,_G.PositioningMode)
    sys.wait(20)
    uart.write(gps_uart_id, "$PCAS03,1,1,1,1,1,1,1,1,0,0,1,1,1*33\r\n") -- 默认所有name语句都打开
    sys.wait(20)
    
    exec_agnss()
end)



sys.taskInit(function()
    while true do
        if  not (devicemodel == "" and cmd_ext == '') then
            break;
        end
        sys.wait(100)
     end

    
    while true do
        if  not (devicemodel == "restdeep_platequery" and cmd_ext == 'no') then
            break;
        end
        sys.wait(100)
     end


        pm.power(pm.GPS, true)   --780EG打开  EP注释掉


    
    while 1 do
        sys.wait(1000)
        
        ----------------------------------------------------------------------------
        local rsrp=mobile.rsrp()
        local RsrpGrade=rsrp+140 

        _G.Mobile_Ss=RsrpGrade
        -- log.info("------------>_G.Mobile_Ss",_G.Mobile_Ss)

        local Gsv=libgnss.getGsv()
        local Gsvv=json.encode(Gsv)
        local loc=libgnss.getRmc(1)
        locc=json.encode(loc)--其他文件要调用的量不要加local!!!

        libgnss.getIntLocation()
        local gga = libgnss.getGga(2)
        if gga then
            -- log.info("GGA------------------>", json.encode(gga, "11g"))
        end

        local gll = libgnss.getGll(2)
        if gll then
            -- log.info("GLL----------------->", json.encode(gll, "11g"))
        end



        if loc.valid==true then

            Gps_Get_Num = 0

            local lat=loc.lat
            local lng=loc.lng
            local latt=lat/10000000--除法，保留小数--//除法，只保留整数
            local lngg=lng/10000000

            _G.old_latitude=json.encode(latt)
            _G.old_longitude =json.encode(lngg)
            log.info("-------------------->> GPS定位成功！！！<<----------------------","lat------->",_G.old_latitude,"lng------->",_G.old_longitude)
            _G.data_from="GPS"
            sys.publish(_G.GPS_Ggt_Topic)


            local total_sats=Gsv.total_sats
            local sats=Gsv.sats
            local snr=nil
            local LsnrNum=0

            for i=1,total_sats do
                snr=sats[i].snr
                if snr>25 then 
                    LsnrNum=LsnrNum+1
                end
            end
            
            _G.Gnss_Ss=LsnrNum
            _G.SatsNum=total_sats
            

            
        elseif loc.valid==false then

            sys.publish(_G.GPS_Ggt_Topic_F)
            Gps_Get_Num=Gps_Get_Num+1
            log.info(Gps_Get_Num,"-------------------->>GPS定位失败<<----------------------原始数据:",locc) 

        end

        if Gps_Get_Num==10 then
            Gps_Get_Num=0

            log.info("-------------------->>10次 GPS定位失败,改用基站wifi混合定位!!!<<----------------------") 


            mobile.reqCellInfo(15)
            lbsLoc.request(getLocCb) -- 没有wifi数据,进行普通定位
            -- wlan.init()
            -- for i=1,Wifi_Num_Max do
            --     mobile.reqCellInfo(6)
            --     sys.waitUntil("CELL_INFO_UPDATE", 3000)
            --     wlan.scan()
            --     sys.wait(6000)
            -- end

        end


    end
end)

-- 订阅GNSS状态编码
sys.subscribe("GNSS_STATE", function(event, ticks)
    -- event取值有 
    -- FIXED 定位成功
    -- LOSE  定位丢失
    -- ticks是事件发生的时间,一般可以忽略
    log.info("gnss", "state", event, ticks)
    if event == "FIXED" then
        local rmc = libgnss.getRmc(2)
        local locStr = { lat ,lng }
        locStr.lat = rmc.lat
        locStr.lng = rmc.lng
        local str = json.encode(locStr, "7f")
        io.writeFile("/gnssrmc", str)
        log.info("gnss", "rmc", str)
    end
end)



sys.taskInit(function()
    while 1 do
        sys.wait(3600*1000) -- 一小时检查一次
        local fixed, time_fixed = libgnss.isFix()
        if not fixed then
            exec_agnss()
        end
    end
end)


