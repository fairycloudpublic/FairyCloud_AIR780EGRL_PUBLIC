sys = require("sys")

-- 添加硬狗防止程序卡死
if wdt then
    wdt.init(9000) -- 初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000) -- 3s喂一次狗
end

vbat=5000
vbatt=0
svbst="5000"

local vbat_adc=adc.CH_VBAT 

sys.taskInit(function()
    if vbat_adc and vbat_adc ~= 255 then adc.open(vbat_adc) end

    -- 下面是循环打印, 接地不打印0也是正常现象
    -- ADC的精度都不会太高, 若需要高精度ADC, 建议额外添加adc芯片
    while true do
        log.debug("adc", "VBAT", adc.get(vbat_adc))
        vbat=adc.get(vbat_adc)
 
        if vbat>=4000 then
            vbatt=100
        elseif(vbat>=3900 and vbat<4000) then
            vbatt=90
        elseif(vbat>=3800 and vbat<3900) then
            vbatt=80
        elseif(vbat>=3700 and vbat<3800) then
            vbatt=70
        elseif(vbat>=3600 and vbat<3700) then
            vbatt=60
        elseif(vbat>=3500 and vbat<3600) then
            vbatt=50
        elseif(vbat>=3400 and vbat<3500) then
            vbatt=40
        elseif(vbat>=3300 and vbat<3400) then
            vbatt=30
        elseif(vbat>=3200 and vbat<3300) then
            vbatt=20
        elseif(vbat>=3100 and vbat<3200) then
            vbatt=10
        elseif(vbat<3100) then
            vbatt=1
        end
        svbat=tostring(vbatt)
        sys.wait(1000)
    end

    -- 若不再读取, 可关掉adc, 降低功耗, 非必须
    if vbat_adc and vbat_adc ~= 255 then adc.close(vbat_adc) end

end)

