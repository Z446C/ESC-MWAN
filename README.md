# ESC For Shell - MWAN
基于[ESC For Shell](https://github.com/Z446C/ESC-Z)在openwrt上多线带宽叠加的实现

---

## 脚本说明
> 注意：
> 1. 需要一个校园网账号可使用多个（两个以上）的终端上网，就可以进行带宽叠加。
> 2. 本项目只做两个wan口的登录/注销，两个以上可以自行修改源码。
> 3. 主要是针对openwrt系统，因为有mwan3插件。
- 这是 [ESC For Shell](https://github.com/Z446C/ESC-Z) 的多wan版本，可实现带宽叠加
- 使用shell轻量脚本
- 支持openwrt系统

### 基本功能
- 自动登录/注销账号（可指定wan口或默认全部wan口）
- 用户自定义函数体（可用于用户自由编写，通过参数调用。例如重启wan接口、注销等，加到计划任务cron可以实现定时执行的任务，不用再有冗余的执行文件了）
- 日志输出（拥有内存限制，只保留最新日志）


## 运行环境
### 系统
- OpenWrt

### 工具包
- curl: 用于http请求（必装）。
- base64: 用于密码编码（非必装），可以自行去工具网站用base64编码密码，再填写到程序对应位置上，使用base64这个工具包可以自动编码，base64包的名字可以自行搜索对应系统的，不同系统有所区别。
- mwan3：负载均衡（必装）。

**安装命令**
```shell
opkg updata #更新安装包
opkg install curl
opkg install coreutils-base64 # base64编码包
opkg install mwan3
opkg install luci-app-mwan3 #mwan3的openwrt界面
luci-i18n-mwan3-zh-cn #mwan3的openwrt界面中文包
```


## 如何使用
### 准备工作
1. 先在windows等系统填写信息（有些终端对中文显示不了）
```
# 必填数据：账号、密码、WAN设备名称
username="123456789"
passwd="123456"
# device通过`ifconfig`查看,名称就是最左侧，例如：
device1="wan"
device2="lan2"
################################
# 建议填写，一劳永逸
# base64编码过的密码（建议自行编码，节省内存，默认留空自动编码（需安装工具包）
pwd64=""
# 学校服务器，登录后查看日志，将nasip填入下面，否则会影响注销（wyu默认填119.146.175.80）例如：
nasip="119.146.175.80"
# 学校代号,建议手动填写，节省访问资源（wyu默认填1414）例如：
schoolid="1414"
# 日志路径、文件大小(kB)，注意路径
path="/root/ESC-MWAN/ESC-MWAN.log"
logmaxsize=256
```
2. 拷贝项目到/root，确认脚本所在位置为/root/ESC-MWAN/ESC-MWAN.sh
3. 配置两个wan口网络
4. 配置mwan3，进去op系统后台，找到**网络->负载均衡**进行配置


### 执行脚本
1. 给权限，直接运行，会在/root/ESC-MWAN生成一个日志文件ESC-MWAN.log
```sheel
chmod 755 /root/ESC-MWAN/ESC-MWAN.sh
/root/ESC-MWAN/ESC-MWAN.sh login
```
2. 查看ESC-MWAN.log（成功登录两个wan口的话可以进行下一步）
```shell
cat /root/ESC-MWAN/ESC-MWAN.log
```


### 使用的建议
- 由于mwan3会每隔一段事件对wan口进行跟踪检测在线情况，所以基本很稳定，不会出现经常掉线。
- 为了稳定性，可以在mwan3的通知（Motification）那里增加以下代码，目的是检测到有掉线的话，就会触发$Action然后执行重新登录
```shell
# 断线事件
case "$ACTION" in
	ifup)
	# 检测到有wan口被启动
	;;
	ifdown)
	# 检测到有wan口被禁用
	;;
	connected)
	# 跟踪wan口成功，在线
	;;
	disconnected)
	# 跟踪wan口失败，断线
		date "+%Y-%m-%d %H:%M:%S" >> /root/ESC-MWAN/ESC-MWAN.log
		echo "检测到设备接口掉线，正在重新登录..." >> /root/ESC-MWAN/ESC-MWAN.log
		sleep 2
		/root/ESC-MWAN/ESC-MWAN.sh login
	;;
esac
```

## 参考项目
https://github.com/Z446C/ESC-Z


## 开源协议
[GPL-3.0](https://github.com/Z446C/ESC-MWAN/blob/master/LICENSE)


## 声明

严格遵守GPL-3.0开源协议，禁止任何个人或者公司将本代码投入商业使用，由此造成的后果和法律责任均与本人无关。
本项目只适用于学习交流，请勿商用！
