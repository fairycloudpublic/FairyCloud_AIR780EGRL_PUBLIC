sys = require("sys")
require"projectConfig"

-- 添加硬狗防止程序卡死
if wdt then
    wdt.init(9000) -- 初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000) -- 3s喂一次狗
end

vbat_c=4100
vbatt=0
svbst="4100"

local vbat_adc=adc.CH_VBAT 

-- 10S更新一次电量数据
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



    if vbat_adc and vbat_adc ~= 255 then adc.open(vbat_adc) end

    -- ADC的精度都不会太高, 若需要高精度ADC, 建议额外添加adc芯片
    while true do
        -- log.debug("adc", "VBAT", adc.get(vbat_adc))
        vbat_c=adc.get(vbat_adc)
 
        if vbat_c >= _G.vbat_max then
            vbatt=100
        elseif(vbat_c <= _G.vbat_min ) then
            vbatt=1
        else
            local c_interval = (_G.vbat_max - _G.vbat_min)/100;
            vbatt = (vbat_c - _G.vbat_min)/c_interval;

            if vbatt <1 then
                vbatt = 1
            end

        end

        vbatt = math.floor(vbatt)

        _G.electricity=tostring(vbatt)
        _G.vbat = vbat_c

        sys.wait(_G.update_time)
    end

    -- 若不再读取, 可关掉adc, 降低功耗, 非必须
    if vbat_adc and vbat_adc ~= 255 then adc.close(vbat_adc) end

end)

