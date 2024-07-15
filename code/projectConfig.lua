_G.SRCCID = ""                   --根据自己账号分配到的实际内容填写
_G.appkey = "XXXXXXXX"           --根据自己账号分配到的实际内容填写
_G.secretkey = "XXXXXXXX"        --根据自己账号分配到的实际内容填写



_G.topic_server_home = "server/home/"
_G.topic_sys_message = "server/home/system/#"
_G.mqtt_pub_topicsss = "client/home/"

_G.project = "XXXXXXXX"         --根据自己账号分配到的实际内容填写
_G.projectkey = "XXXXXXXX"      --根据自己账号分配到的实际内容填写    


_G.REPORT_DATA_TEMPLATE = "{\"did\":\"\",\"cmdtype\":\"cmd_status\",\"project\":\"\",\"projectkey\":\"\",\"password\":\"\",\"datatype\":\"dictionary\",\"reporttime\":\"\",\"version\":\"\",\"cid\":\"\",\"longitude\":\"120.7777\",\"latitude\":\"35.7777\",\"temperature\":\"25.5\",\"electricity\":\"5000\",\"loc\":\"_\",\"data_from\":\"_\",\"version\":\"_\"}"
_G.REPORT_CONTROLLACK_TEMPLATE = "{\"status\":\"success\",\"cmdtype\":\"cmd_controllack\",\"did\":\"\",\"project\":\"\",\"projectkey\":\"\",\"reporttime\":\"\"}"

_G.mqttserverip = "XXXXXXXX"     --MQTT服务器地址
_G.mqttserverport = XXXXXXXX     --MQTT服务器端口

_G.mqttc = nil   
_G.uartid = 1

_G.GPS_Updata=false
_G.GPS_Get=false

_G.GPS_Ggt_Topic="GPS_Get"
_G.GPS_Ggt_Topic_F="GPS_Get_F"
_G.Updata_OK="Updata_OK"

_G.sslat="35.7777777"            --默认的纬度
_G.sslng="120.7777777"           --默认的经度