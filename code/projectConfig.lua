-------------------------------------- 项目全局配置文件--------------------------------------

-- 以下三选一，然后开始配置    【阿里云、自建服务器 代码需要定制化开发】
-- ①精灵云 		fairycloud
-- ②阿里云 		aliyuncs
-- ③自建服务器 	privatecloud

_G.server_select = "fairycloud"
-- _G.server_select = "aliyuncs"
--_G.server_select = "privatecloud"


-- ①精灵云(fairycloud)： 3个参数--必配--⭐️⭐️⭐️联系平台管理员获取⭐️⭐️⭐️
_G.server_api = ""
_G.appkey = ""
_G.secretkey = ""


-- ②阿里云(aliyuncs)： 7个参数--必配--自行在阿里云官网处理
_G.aliyuncs_clientId =  "k1q9smpdXQq.AIR780EGRL|securemode=2,signmethod=hmacsha256,timestamp=1725892899910|"
_G.aliyuncs_username =  "AIR780EGRL&k1q9smpdXQq"
_G.aliyuncs_mqttHostUrl =  "iot-06z00hq1bf8kxwr.mqtt.iothub.aliyuncs.com"
_G.aliyuncs_passwd = "954d9e6f642580b1584925fedfb7c469e0a7cf5a46506b51fcdddb0c4f1892e0"
_G.aliyuncs_port =  1883
_G.aliyuncs_pub_topic =  "/k1q9smpdXQq/AIR780EGRL/user/update"
_G.aliyuncs_sub_topic =  "/k1q9smpdXQq/AIR780EGRL/user/get"


-- ③自建服务器(privatecloud)： 1个参数--必配--POST请求的服务器地址，body传json数据
--_G.post_url = "https://petbus.cqchongbao.com/api/location/index"


------------------------------以上必配，到此结束--------------------------------------


-- 程序版本号--选配
_G.version = "1.0.0"


--GPS模组工作模式--选配
--_G.PositioningMode="$PCAS04,1*18\r\n"      --单GPS定位
--_G.PositioningMode="$PCAS04,2*1B\r\n"      --单北斗定位
_G.PositioningMode="$PCAS04,3*1A\r\n"      --GPS+北斗双模定位 

-- 日志开启状态，默认关闭
_G.logFlag = false;

------------------------------所有配置，到此结束--------------------------------------


-- 设备运行模式 ，默认正常： 正常awake_normal  深度休眠restdeep_deviceupdate  主动查询restdeep_platequery
_G.devicemodel = "";

-- 扩展命令 用于回复指令 platformquery
_G.cmd_ext = "";

-- 数据上报周期--默认的15S上报:15*1000ms
_G.update_time = 15*1000

-- 深度休眠唤醒周期 10分钟
_G.deeprest_time = 10*60*1000

-- 以下设置程序自动获取
_G.SRCCID = ""							
_G.mqtt_mqttClientId=""					
_G.mqtt_username=""						
_G.mqtt_passwd=""						
_G.mqtt_mqttHostUrl ="" 				
_G.mqtt_port = 0 


-- MQTT的TOPIC
_G.mqtt_sub_topic = ""
_G.mqtt_pub_topic = ""


-- 消息传输模板
_G.REPORT_DATA_TEMPLATE = "{\"cmdtype\":\"cmd_status\",\"reporttime\":\"\",\"version\":\"-\", \"electricity\":\"--\"}"
_G.REPORT_CONTROLLACK_TEMPLATE = "{\"status\":\"success\",\"cmdtype\":\"cmd_controllack\",\"did\":\"\",\"reporttime\":\"\"}"

-- 硬件IMEI
_G.aliyuncs_imei = ""

-- 默认的经纬度和数据源
_G.old_latitude=""
_G.old_longitude=""
_G.data_from="NoData"

-- 默认的温湿度
_G.temperature=0
_G.humidity=0
-- 电量
_G.electricity = "--";
_G.vbat = "--";
_G.vbat_max = 4100;
_G.vbat_min = 3100;

_G.mqttc = nil   
_G.uartid = 1

_G.GPS_Updata=false
_G.GPS_Get=false
--卫星信号强度和4G信号强度
_G.Gnss_Ss=0
_G.Mobile_Ss=0
_G.SatsNum=0
_G.GPS_Ggt_Topic="GPS_Get"
_G.GPS_Ggt_Topic_F="GPS_Get_F"
_G.Updata_OK="Updata_OK"
