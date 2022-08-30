# ESC For Shell - MWAN
基于[ESC For Shell](https://github.com/Z446C/ESC-Z)在openwrt上多线带宽叠加的实现

---

## 更新 2022/08/30
1. 解决获取响应数据时结尾出现\r\n控制符导致字符串匹配失败的问题

## 脚本说明
- 这是 [ESC For Shell](https://github.com/Z446C/ESC-Z) 的多wan版本，可实现带宽叠加
- 需要一个校园网账号可使用多个（两个以上）的终端上网，就可以进行带宽叠加。
- 本项目只做两个wan口的登录/注销，两个以上可以自行修改源码，主要是针对openwrt系统，因为有mwan3插件。


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
4. 配置mwan3，进去op系统后台，找到**网络->负载均衡**进行配置，
>不会配置？[使用MWAN3进行多线叠加详细教程](https://www.right.com.cn/forum/thread-147109-1-1.html)


### 执行脚本
1. 给权限，直接运行，会在/root/ESC-MWAN生成一个日志文件ESC-MWAN.log
```sheel
chmod 755 /root/ESC-MWAN/ESC-MWAN.sh
/root/ESC-MWAN/ESC-MWAN.sh login
```
2. 查看ESC-MWAN.log（查看是否成功登录两个wan口）
```shell
cat /root/ESC-MWAN/ESC-MWAN.log
```
3. 对于用户自定义函数，可以通过myFunc参数来调用
```shell
# 先编写myFun函数
myFunc(){
	case $1 in
		test)
			echo "HELLO ESC-MWAN!"
			;;
		start)
			;;
		stop)
			;;
		restart)
			;;
	esac
}
```
```shell
# 执行
/root/ESC-MWAN/ESC-MWAN.sh myFunc test/start/stop/restart
```


### 使用的建议
- 由于mwan3会每隔一段事件对wan口进行跟踪检测在线情况，所以基本很稳定，基本不会出现经常掉线。
- 为了稳定性，可以在mwan3的通知（Motification）那里增加以下代码，检测到有掉线的话，就会触发$ACTION然后执行重新登录
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
- 在工作日早上恢复网络后，定时重启路由器或重启wan口, 以刷新网络状态
```shell
# 编辑源码的myFunc函数
myFunc(){
	case $1 in
		test)
			echo "HELLO ESC-MWAN!"
			;;
		login)
			echo "$time - 状态:执行myFunc登录中" >> /root/ESC-MWAN/ESC-MWAN.log
			/root/ESC-MWAN/ESC-MWAN.sh login
			sleep 1
			;;
		logout)
			echo "$time - 状态:执行myFunc注销中" >> /root/ESC-MWAN/ESC-MWAN.log
			/root/ESC-MWAN/ESC-MWAN.sh logout
			sleep 1
			;;
		start)
			echo "$time - 状态:执行myFunc启动mwan3中" >> /root/ESC-MWAN/ESC-MWAN.log
			/etc/init.d/mwan3 start
			sleep 1
			;;
		stop)
			echo "$time - 状态:执行myFunc关闭mwan3中" >> /root/ESC-MWAN/ESC-MWAN.log
			/etc/init.d/mwan3 stop
			sleep 1
			;;
		restart)
			echo "$time - 状态:执行myFunc重启wan/wan2中" >> /root/ESC-MWAN/ESC-MWAN.log
			# ifup使用的参数是逻辑名称wan/wan2(和代码的device是不一样的，要去/etc/config/network查看interface)
			ifup wan
			ifup wan2
			sleep 2
			echo "$time - 状态:执行myFunc登录中" >> /root/ESC-MWAN/ESC-MWAN.log
			/root/ESC-MWAN/ESC-MWAN.sh login
			sleep 1
			;;
	esac
}
```
```shell
# 编辑crontab文件内容
# 周一到周五，每天6:05执行一次
5 6 * * 1,2,3,4,5 /bin/sh /root/ESC-MWAN/ESC-MWAN.sh myFunc restart
# 周日到周四，每天23:28执行一次
28 23 * * 1,2,3,4,7 /bin/sh /root/ESC-MWAN/ESC-MWAN.sh myFunc stop
```

## 参考项目
https://github.com/Z446C/ESC-Z


## 开源协议
[GPL-3.0](https://github.com/Z446C/ESC-MWAN/blob/master/LICENSE)


## 声明

严格遵守GPL-3.0开源协议，禁止任何个人或者公司将本代码投入商业使用，由此造成的后果和法律责任均与本人无关。
本项目只适用于学习交流，请勿商用！

## 反馈
提issue或者Q群(729672645)