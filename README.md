# FairyCloud_AIR780EGRL_PUBLIC
AIR780EG定位器-硬件代码;欢迎交流：QQ群：630017549，个人微信：fairycloud2035

## 代码说明
### 代码目录
FairyCloud_AIR780EGRL_PUBLIC/code/


### 配置文件说明

#### 1.appkey、secretkey
说明：通信使用的秘钥，用于连接到物联网平台，直接问管理员获取即可；

目录：FairyCloud_AIR780EGRL_PUBLIC/code/projectConfig.lua

-- 以下3个参数必须配置
_G.server_api = "" 	--服务器信息，联系平台管理员获取

_G.appkey = ""			--用户的appkey，联系平台管理员获取

_G.secretkey = ""		--用户的secretkey,联系平台管理员获取


#### 2.VERSION
说明：当前软件的版本号，自行设置/修改；

目录：FairyCloud_AIR780EGRL_PUBLIC/code/main.lua

_G.VERSION = "1.0.5"


#### 3.PRODUCT_KEY
说明：用于硬件FOTA升级，不用合宙的FOTA可以不做设置；自行到 iot.openluat.com 创建项目,获取正确的项目id；

目录：FairyCloud_AIR780EGRL_PUBLIC/code/fota.lua

PRODUCT_KEY = "XXXXXXXXXXXXXXXXXXXXXX"




## 示例教程

### 实物演示
[【AIR780EG定位器，小程序/web远程查看-哔哩哔哩】](https://b23.tv/LC0sZ2T)

### 说明文档
[【外部】精灵物联网各项目汇总](https://gv9jqt8gpcb.feishu.cn/docx/DAJGdExvZoZBA3xuAogc53ohnxg?from=from_copylink)

### 实物图片
![image](https://github.com/fairycloudpublic/FairyCloud_AIR780EGRL_PUBLIC/blob/main/photo1.png)

![image](https://github.com/fairycloudpublic/FairyCloud_AIR780EGRL_PUBLIC/blob/main/photo2.png)

![image](https://github.com/fairycloudpublic/FairyCloud_AIR780EGRL_PUBLIC/blob/main/photo3.png)


## 版权说明
仅供大家学习与参考，请勿用于非法用途，未经版权所有权人书面许可，不能自行用于商业用途。如需作商业用途，请与原作者联系。

### 许可协议
许可协议 AGPL3.0协议

### 软著证书
![image](https://github.com/fairycloudpublic/FairyCloud_AIR780EGRL_PUBLIC/blob/main/%E7%B2%BE%E7%81%B5%E7%89%A9%E8%81%94%E7%BD%91%E5%B9%B3%E5%8F%B0%E7%89%88%E6%9D%83.png)
