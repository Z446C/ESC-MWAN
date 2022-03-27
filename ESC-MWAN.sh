#!/bin/sh
#####################################################################################################################
# 作者 @Otm-Z 创建于2022/03/22
# 实现环境：openwrt
# 必备工具包：curl、mwan3
# 非必备工具包：coreutils-base64 —— 用于密码编码，可以不安装，自行去编码，再把结果填入pwd64中，默认留空自动编码（需安装工具包）
#####################################################################################################################
# 必填数据：账号、密码、WAN设备名称
username=""
passwd=""
# device通过`ifconfig`查看,名称就是最左侧
device1=""
device2=""
################################
# 建议填写，一劳永逸
# base64编码过的密码（建议自行编码，节省内存，默认留空自动编码（需安装工具包）
pwd64=""
# 学校服务器，登录后查看日志，将nasip填入下面，否则会影响注销（wyu默认填119.146.175.80）
nasip=""
# 学校代号,建议手动填写，节省访问资源（wyu默认填1414）
schoolid=""
# 日志路径、文件大小(kB)，注意路径
path="/root/ESC-MWAN/ESC-MWAN.log"
logmaxsize=256
################################
# 全局数据（不用修改）
iswifi="4060"
secret="Eshore!@#"
version="214"
useragent="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36"
cookie=""
verifycode=""
time=`date "+%Y-%m-%d %H:%M:%S"`
interf=""
mac=""
clientip=""
redirecturl1="172.17.18.3:8080"
redirecturl2="enet.10000.gd.cn:10001"
#################################################################################################################
# 自定义函数体(用于用户自定义脚本，通过参数来调用)
myFunc(){
	echo "HELLO ESC-MWAN!"
	# # 注销
	# echo "$time - 执行myFunc注销中" >> /root/ESC-MWAN/ESC-MWAN.log
	# /root/ESC-MWAN/ESC-MWAN.sh logout
	# sleep 2
	# # 重启wan/wan2
	# echo "$time - 执行myFunc重启wan/wan2中" >> /root/ESC-MWAN/ESC-MWAN.log
	# # ifup使用的参数是逻辑名称wan/wan2(和代码的device是不一样的，要去/etc/config/network查看interface)
	# ifup wan  
	# ifup wan2
	# sleep 2
}

# 创建日志文件
# (createLog)
createLog(){
	if [[ "$path" == "" ]]; then
		path="/root/ESC-Z/ESC-Z.log"
	fi

	if [ -f "$path" ]; then
		local size=`ls -l $path | awk '{ print $5 }'`
		local maxsize=$((1024*$logmaxsize))
		if [ $size -ge $maxsize ]; then
			echo "$time - 状态:正在删除旧的记录..." >> $path
			#取后3000行内容重定向到另外一个临时文件中
			tail -n 3000 ESC-Z.log > ESC-Z.log.tmp
			rm -f ESC-Z.log
			mv ESC-Z.log.tmp ESC-Z.log
			# 清空
			# cat /dev/null > $path
			# echo "$time - 状态:正在清空日志..." >> $path
		else
			echo "$time - 状态:日志容量 $size/$maxsize" >> $path
		fi
	else
		echo "$time - 状态:创建日志中..." >> $path
	fi
}

# json数据解析
# (getJson)
getJson(){
    echo $1 | awk -F $2 '{print $2}' | awk -F '"' '{print $3}'
}

# post请求 
# (postReq url data cookie)
postReq(){
	local contenttype="Content-Type: application/json"
	local accept="Accept: */*"
	echo `curl $1 -H "$useragent" -H "$contenttype" -H "$accept" -d "$2" --cookie "$3" --interface "$interf" -s`
}

# 从重定向地址获取用户ip
# (getIP)
getIP(){
	# 从重定向网页中获取
	# "http://enet.10000.gd.cn:10001/?wlanuserip=100.2.49.240&wlanacip=119.146.175.80"
	# "http://enet.10000.gd.cn:10001/qs/main.jsp?wlanacip=119.146.175.80&wlanuserip=100.2.50.69"
	local tmp1=`echo -n $1 | cut -d '?' -f2 | cut -d '&' -f1`
	local tmp2=`echo -n $1 | cut -d '?' -f2 | cut -d '&' -f2`
	if [[ "$clientip" == "" ]]; then
	        clientip=`echo -n $tmp1 | grep "wlanuserip"`
	fi

	if [[ "$nasip" == "" ]]; then
	        nasip=`echo -n $tmp2 | grep "wlanacip"`
	fi

	if [[ "$clientip" == "" ]]; then
	        clientip=`echo -n $tmp2 | cut -d '=' -f2`
	else
	        clientip=`echo -n $tmp1 | cut -d '=' -f2`
	fi

	if [[ "$nasip" == "" ]]; then
	        nasip=`echo -n $tmp1 | cut -d '=' -f2`
	else
	        nasip=`echo -n $tmp2 | cut -d '=' -f2`
	fi
}

# 获取本地MAC地址
# (getMAC)
getMAC(){
	mac=`ifconfig |grep -B1 $clientip |awk '/HWaddr/ { print $5 }'`
}

# 获取本地IP地址
# (getIP2)
getIP2(){
	clientip=`ifconfig $interf |grep "inet addr" |awk '{print $2}' |tr -d "addr:"`
}

# 网站访问状态 
# (getUrlStatus url location/code)
getUrlStatus(){
	if [[ "$2" == "location" ]]; then
		#获取重定向地址
		echo `curl $1 -H "$useragent" --interface "$interf" -I -G -s | grep "Location" | awk '{print $2}'`
	elif [[ "$2" == "code" ]]; then
		#获取状态码
		echo `curl $1 -H "$useragent" --interface "$interf" -I -G -s | grep "HTTP" | awk '{print $2}'`
	fi
}

# 保活
# (keepAlive)
keepAlive(){
	local url1="http://qq.com"
	local url2="http://www.bing.com"
	Location=`getUrlStatus $url1 location`
	if [[ "$Location" != "https://www.qq.com/" ]]; then
		Location=`getUrlStatus $url2 location`
		if [[ "$Location" == "http://cn.bing.com/" ]]; then
			echo OK
		else
			echo NG
			return
		fi
	elif [[ "$Location" == "https://www.qq.com/" ]]; then
		echo OK
	fi
}

#######################################################################################################
# 内网检测，code=200 or 302
# (intranetCheck)
intranetCheck(){
	local code=`curl -H "$useragent" "http://172.17.18.3:8080/portal/" --interface "$interf" -s -I | grep HTTP/1.1 | awk '{print $2}'`
	if [[ "$code" == "200" ]]; then
		echo OK
	elif [[ "$code" == "302" ]]; then
		echo OK
	else 
		echo NG
	fi
}

# 内网登录
# (portalLogin)
portalLogin(){
	if [[ "$pwd64" == "" ]]; then
		# 密码用base64编码
		pwd64=`echo -n $passwd |base64`
	fi
	local url="http://172.17.18.3:8080/portal/pws?t=li&ifEmailAuth=false"
	local acceptlanguage="Accept-Language: zh-cn"
	local accept="Accept: application/signed-exchange"
	local body="userName=${username}&userPwd=${pwd64}%3D&userDynamicPwd=&userDynamicPwdd=&serviceType=&userurl=&userip=&basip=&language=Chinese&usermac=null&wlannasid=&wlanssid=&entrance=null&loginVerifyCode=&userDynamicPwddd=&customPageId=100&pwdMode=0&portalProxyIP=172.17.18.3&portalProxyPort=50200&dcPwdNeedEncrypt=1&assignIpType=0&appRootUrl=http%3A%2F%2F172.17.18.3%3A8080%2Fportal%2F&manualUrl=&manualUrlEncryptKey="
	local code=`curl $url -H "$accept" -H "$useragent" -H "$acceptlanguage" -d "$body" --interface $interf -i -s | grep "HTTP/1.1" | awk '{print $2}'`
	if [[ "$code" == 200 ]]; then
		echo OK
	else
		echo NG
	fi
}

# 获取学校ID，响应{"schoolid": "1414","domain": "WYDX","rescode": "0","resinfo": "success"}
# (getSchoolId)
getSchoolId(){
	local url="http://enet.10000.gd.cn:10001/client/queryschool"
	local cookie=""
	local timestamp=`date +%s`
	local buffer=$clientip$nasip$mac$timestamp$secret
	local md5=`echo -n "$buffer"|md5sum|cut -d ' ' -f1| tr '[a-z]' '[A-Z]'`
	local data="{\"clientip\":\"$clientip\",\"nasip\":\"$nasip\",\"mac\":\"$mac\",\"timestamp\":$timestamp,\"authenticator\":\"$md5\"}"
	local response=`postReq $url $data $cookie`
    echo `getJson $response schoolid`
}

# 获取cookie
# (getCookie)
getCookie(){
	local url="http://enet.10000.gd.cn:10001/advertisement.do"
	echo `curl "$url" -H "$useragent" -G -d "$schoolid" --interface "$interf" -s -i | grep Set-Cookie | awk '{print $2,$3,$4}'`
}

# 获取验证码，响应{"challenge": "MR71","resinfo": "success","rescode": "0"}
# (getVerifyCode)
getVerifyCode(){
	local url="http://enet.10000.gd.cn:10001/client/vchallenge"
	local timestamp=`date +%s`
	local buffer=$version$clientip$nasip$mac$timestamp$secret
	local md5=`echo -n "$buffer"|md5sum|cut -d ' ' -f1| tr '[a-z]' '[A-Z]'`
	local data="{\"version\":\"$version\",\"username\":\"$username\",\"clientip\":\"$clientip\",\"nasip\":\"$nasip\",\"mac\":\"$mac\",\"timestamp\":\"$timestamp\",\"authenticator\":\"$md5\"}"
	local response=`postReq $url $data $cookie`
	echo `getJson $response challenge`
}

#登录外网，响应{"resinfo":"login success","rescode":"0"}
# (loginTask)
loginTask(){
	local url="http://enet.10000.gd.cn:10001/client/login"
	local timestamp=`date +%s`
	local buffer=$clientip$nasip$mac$timestamp$verifycode$secret
	local md5=`echo -n "$buffer"|md5sum|cut -d ' ' -f1| tr '[a-z]' '[A-Z]'`
	local data="{\"username\":\"$username\",\"password\":\"$passwd\",\"clientip\":\"$clientip\",\"nasip\":\"$nasip\",\"mac\":\"$mac\",\"iswifi\":\"$iswifi\",\"timestamp\":\"$timestamp\",\"authenticator\":\"$md5\"}"
	local response=`postReq $url $data $cookie`
	echo $response >> $path
	local rescode=`echo $response | awk -F rescode '{print $2}' | awk -F '"' '{print $3}'`
	if [[ "$rescode" == 0 ]]; then
		echo "登录成功"
	else
		echo "登录失败"
	fi
}

# 注销外网，响应{"rescode":"0","resinfo":"logout success"}
# (logoutTask)
logoutTask(){
	local url="http://enet.10000.gd.cn:10001/client/logout"
	local timestamp=`date +%s`
	local buffer=$clientip$nasip$mac$timestamp$secret
	local md5=`echo -n "$buffer"|md5sum|cut -d ' ' -f1| tr '[a-z]' '[A-Z]'`
	local data="{\"clientip\":\"$clientip\",\"nasip\":\"$nasip\",\"mac\":\"$mac\",\"secret\":\"$secret\",\"timestamp\":$timestamp,\"authenticator\":\"$md5\"}"
	local response=`postReq $url $data $cookie`
	echo $response >> $path
	local rescode=`echo $response | awk -F rescode '{print $2}' | awk -F '"' '{print $3}'`
	if [[ "$rescode" == 0 ]]; then
		echo "注销成功"
	else
		echo "注销失败"
	fi
}

###################################################################################################
# 登录逻辑
# (login)
login(){
	echo "$time - 状态:登录函数" >> $path
	interf=$1
	echo "正在登录${interf}，请稍后..."

	# 保活检测
	local alivestatus=`keepAlive`
	if [[ "$alivestatus" == "OK" ]]; then
		echo "网络正常！"
		echo "网络正常！" >> $path
		return
	fi
	# 检查网络状态
	local url="http://www.qq.com/"
	local urlcode=`getUrlStatus $url code`
	local urllocation=`getUrlStatus $url location`
	if [[ "$urlcode" == "200" ]]; then
		echo "当前校园网环境为无线WiFi环境, 请切换到有线宽带登录" >> $path
		return
	elif [[ "$urlcode" == "302" ]]; then
		# 获取重定向地址
		echo "当前为有线网络" >> $path
		echo "获取到重定向地址为:$urllocation" >> $path
		if [[ $urllocation =~ $redirecturl1 ]]; then
			# 需要protal认证
			# http://172.17.18.3:8080/portal/templatePage/20200426133232935/login_custom.jsp
			echo "正在进行portal认证..." >> $path
			if [[ "`portalLogin`" == "OK" ]]; then
				echo "portal认证已完成, 请稍后..." >> $path
				sleep 1
				login
			else
				echo "portal认证失败, 请检查网络" >> $path
			fi
			return

		elif [[ $urllocation =~ $redirecturl2 ]]; then
			# "http://enet.10000.gd.cn:10001/?wlanuserip=100.2.49.240&wlanacip=119.146.175.80"
			# "http://enet.10000.gd.cn:10001/qs/main.jsp?wlanacip=119.146.175.80&wlanuserip=100.2.50.69"
			
			# 获取用户IP和服务器IP
			getIP $urllocation
			echo "nasip:${nasip}" >> $path
			echo "clientip:${clientip}" >> $path
			
			# 获取MAC地址
			if [ $clientip ]; then
				getMAC
			else
				getIP2
				getMAC
			fi
			echo "MAC:$mac" >> $path
			
			# 获取学校ID
			if [[ "$schoolid" == "" ]]; then
				schoolid=`getSchoolId`
				echo "schoolid:$schoolid" >> $path
			fi

			# 获取cookie
			if [ $schoolid ]; then
				cookie=`getCookie`
			else
				echo "获取学校号失败，请重试。（多次失败请手动填写）" >> $path
				return
			fi
			
			# 获取验证码
			verifycode=`getVerifyCode`

			# 登录
			if [ $verifycode ]; then
				echo "正在登录${interf}" >> $path
				loginTask
			else
				echo "验证码获取失败，请检查账号密码" >> $path
				return
			fi

		else
			echo "获取重定向地址失败，获取的重定向地址不是http://172.17.18.3:8080/和http://enet.10000.gd.cn:10001/" >> $path
		fi
	else
		echo "登录失败。（多次失败请重启wan口刷新ip）" >> $path
		return
	fi
}


# 注销逻辑
# (logout clientip)
logout(){
	echo "$time - 状态：注销函数" >> $path
	interf=$1
	getIP2
	# 注销
	echo "正在注销${interf}，请稍后..."
	echo "注销IP为:${clientip}" >> $path
	echo "注销的接口为:${interf}" >> $path
	logoutTask
}


# 帮助
# (help)
help(){
	echo "=================================== 帮助 ==================================="
	echo "usge: ESC-Z_mwan.sh <login|logout|myfunc> [Device]"
	echo "注意：可选参数[Device]表示设备接口名称（通过ifconfig查看），用于登录/注销指定的设备接口，不填写默认登录/注销两个设备接口。"
	echo "对于用户自定义函数，可以通过myFunc参数来调用"
}


#主逻辑
# (main login/logout)
main(){
	# 关闭mwan3
	echo "正在关闭mwan3"
	/etc/init.d/mwan3 stop
	sleep 1

	# 创建日志文件
	createLog

	# 检测用户名和密码
	if [[ "$username" == "" ]]; then
		echo "用户名为空" >> $path
		return
	fi
	if [[ "$passwd" == "" ]]; then
		echo "密码为空" >> $path
		return
	fi

	# 检测是否在内网
	if [[ "`intranetCheck`" == "NG" ]]; then
		echo "未连接校园网" >> $path
		return
	fi

	# 登录/注销
	if [[ "$1" == "login" ]]; then
		if [ $2 ]; then
			# $2不为空，登录指定设备接口
			login $2
		else
			# $2为空，登录两个设备接口
			login $device1
			sleep 1
			login $device2
		fi
	elif [[ "$1" == "logout" ]]; then
		if [ $2 ]; then
			# $2不为空，注销指定设备接口
			logout $2
		else
			# $2为空，注销两个设备接口
			logout $device1
			sleep 1
			logout $device2
		fi
		
	fi

	# 启动mwan3
	echo "正在启动mwan3"
	/etc/init.d/mwan3 start
}

# 运行入口
case $1 in
	login)
	    main login $2
	    ;;
  	logout)
	    main logout $2
	    ;;
	myFunc)
		myFunc
		;;
	*)
	    help
	    ;;
esac

echo "退出中..." >> $path
exit 1




