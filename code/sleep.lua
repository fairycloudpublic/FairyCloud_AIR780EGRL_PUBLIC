-- sys库是标配
sys = require("sys")

-- 启动时对rtc进行判断和初始化
local reason, slp_state = pm.lastReson()
log.info("wakeup state", pm.lastReson())

-- 正常开机判断  reason 0正常开机
sys.taskInit(function()

	if reason > 0 then
	    pm.request(pm.IDLE)
	    pm.power(pm.USB, true)
        mobile.flymode(0, false)--关闭飞行模式

	    log.info("-------------------已经从深度休眠唤醒-------------------") 
	else		   
	    log.info("-------------------普通复位，开始运行-------------------")
	end

end)




-- 自动休眠处理
function autoRestDeep()

	log.info("----------autoRestDeep，即将进入深度休眠-----------")
	sys.wait(500) --等待MQTT断开传输完毕


    -- 关闭GPS电源开关
    pm.power(pm.GPS, false)   --780EG打开  EP注释掉

    gpio.setup(23,nil)
	gpio.close(35)
    gpio.close(33) --如果功耗偏高，开始尝试关闭WAKEUPPAD1
	sys.wait(200)

	--打开飞行模式
	mobile.flymode(0, true)
	pm.power(pm.USB, false)
	sys.wait(200)
	
	pm.dtimerStart(3,_G.deeprest_time)
	pm.power(pm.WORK_MODE,3)
    
end


function REST_SEND_RESTDEEP()
    sys.taskInit(function()
        autoRestDeep()
    end)

end


-- 订阅 
sys.subscribe("REST_SEND_RESTDEEP",REST_SEND_RESTDEEP)