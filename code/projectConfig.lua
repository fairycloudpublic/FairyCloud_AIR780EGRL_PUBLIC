-- 以下7个参数必须配置
_G.appkey = "XXX"					--用户的appkey，联系平台管理员获取
_G.secretkey = "XXX"				--用户的secretkey,联系平台管理员获取
_G.project = "XXX"					--项目编码，或者联系平台管理员获取
_G.projectkey = "XXX"				--项目key，或者联系平台管理员获取 


_G.server_api = "XXX" 				--服务器信息，联系平台管理员获取
_G.mqttserverip = "XXX"				--MQTT 地址,联系平台管理员获取
_G.mqttserverport = XXX				--MQTT 端口,联系平台管理员获取




-- 以下设置程序自动获取，可以手动设置
_G.SRCCID = ""			--设备CID，程序自动获取，或者进入平台点击编辑设备查看
_G.deviceid_auth=""		--与设备CID一致，程序自动获取，或者进入平台点击编辑设备查看
_G.username_auth=""		--与设备CID一致，程序自动获取，或者进入平台点击编辑设备查看
_G.password_auth=""		--与projectkey一致，程序自动获取，或者进入平台点击编辑设备查看



-- MQTT的TOPIC 不需要改动
_G.topic_server_home = "server/home/"
_G.topic_sys_message = "server/home/system/#"
_G.mqtt_pub_topicsss = "client/home/"


-- 消息传输模板 不需要改动
_G.REPORT_DATA_TEMPLATE = "{\"did\":\"\",\"cmdtype\":\"cmd_status\",\"project\":\"\",\"projectkey\":\"\",\"datatype\":\"dictionary\",\"reporttime\":\"\",\"version\":\"-\",\"cid\":\"\",\"longitude\":\"116.397477\",\"latitude\":\"39.908677\",\"temperature\":\"--\",\"electricity\":\"100\",\"log\":\"_\",\"data_from\":\"_\"}"
_G.REPORT_CONTROLLACK_TEMPLATE = "{\"status\":\"success\",\"cmdtype\":\"cmd_controllack\",\"did\":\"\",\"project\":\"\",\"projectkey\":\"\",\"reporttime\":\"\"}"



-- 默认的经纬度
_G.sslat="39.908677"
_G.sslng="116.397477"


_G.mqttc = nil   
_G.uartid = 1

_G.GPS_Updata=false
_G.GPS_Get=false

_G.GPS_Ggt_Topic="GPS_Get"
_G.GPS_Ggt_Topic_F="GPS_Get_F"
_G.Updata_OK="Updata_OK"
