# IoTSecurityNAT
IoT security testing environment.

IoT安全测试系统，方便快速接入各种设备，进行安全测试。

## 功能特点

- 快速搭建测试环境
- 实时查看设备状态（是否在线、IP地址、MAC、用户等信息）
- 随时添加新设备进行测试（固定IP配置、设备标识）
- 快速配置代理规则（添加、删除）


## 初始化

配置使用kali作为代理路由器。我们需要一个无线网卡，作为嵌入式设备或手机等终端的接入点。

- 安装必须的组件（建议使用最新版的kali，只需要安装hostapd）
```shell
$ apt-get install dnsmasq hostapd
```
- 不使用Networkmanager接管wlan接口，添加接口MAC地址（或者设备名）到/etc/NetworkManager/NetworkManager.conf文件，然后重启网络服务。
```shell
[keyfile]
unmanaged-devices=mac:d8:eb:97:b6:ce:12;mac:56:6b:a2:90:c4:b9
```
```shell
[keyfile]
unmanaged-devices=interface-name:wlan0
```
重启网络服务
```shell
$ /etc/init.d/networking restart
```

## 使用方法

-   启动基础环境（启动wifi热点、启动dhcp等）
```   
$ ./monitor.sh
input  1  : Show Monitor Status
input  2  : Start Monitor
input  3  : Stop Monitor
input  4  : Debug
input  0  : Exit
```
-   配置代理规则（添加设备、添加修改规则等）
```   
$ ./proxy.sh
input  1  : Show proxy status
input  2  : Add proxy rules
input  3  : Clear proxy rules
input  4  : Add new device
input  0  : Exit
```
-   dns（添加设备、添加修改规则等）
```   
$ ./dns.sh（dns日志查询、本地dns解析功能）
input  Device IP  : Dns search
input      1      : Reload dns file
input      0      : Exit
```

## 配置基础环境（可选），系统初始化完毕即可正常使用。如果需要修改网络参数、wifi、dhcp等配置信息，可以参考以下部分。

- 配置wifi（ssid、密码等），修改配置文件./CONF/hostapd.conf。(```ssid```)为提供的接入点名称，(```wpa_passphrase```)为密码。
```shell
# create a wireless network with this interface; change it if your wireless card is not wlan1
interface=wlan0
# change this if a different bridge interface was chosen
#bridge=br0
ssid=Seclabiot
# Change the passphrase to something you like
driver=nl80211
auth_algs=3
channel=7
hw_mode=g

logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2

wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=Seclabiot
wpa_pairwise=TKIP
rsn_pairwise=CCMP
max_num_sta=50
wpa_group_rekey=86400
wpa_strict_rekey=1
```

- 配置dnsmasq配置，修改配置文件./CONF/dnsmasq.conf
```shell
no-hosts
# listen to this interface; change it if a different bridge name was chosen in the overall script file
interface=wlan0
# except this interface
except-interface=lo
# listen address
listen-address=10.42.0.1
# give ip addresses in 10-100, lease is valid for 8 hours
dhcp-range=10.42.0.100,10.42.0.254,8h 
# dhcp hostsfile
dhcp-hostsfile=/opt/IoTSecurityNAT/CONF/dhcphosts
# dhcp optsfile
dhcp-optsfile=/opt/IoTSecurityNAT/CONF/optsfile
# router
dhcp-option=3,10.42.0.1 
# dns server
dhcp-option=6,10.42.0.1 
# upstream DNS server
server=8.8.8.8
log-queries=extra
log-dhcp
log-facility=/var/log/dnsmasq.log
# include addresses
address=/attacker.com/10.42.0.1
```


- 配置网络（默认配置使用网段10.42.0.0/24，wifi网关地址10.42.0.1）。如需修改IP地址信息，需同时修改文件monitor.sh和./CONF/dnsmasq.conf相关配置。

    修改monitor.sh文件中的相关配置
```shell
# Network address range we use for our monitor network (please change IP address in file dnsmasq.conf and dhsphostfile in dir ./CONF/)
MONITOR_NETWORK=10.42.0.0/24
# The address we assign to our router, dhcp, and dns server.
MONITOR_MAIN=10.42.0.1/24
```
修改./CONF/dnsmasq.conf文件中的相关配置
```shell
# listen address
listen-address=10.42.0.1
# give ip addresses in 10-100, lease is valid for 8 hours
dhcp-range=10.42.0.100,10.42.0.254,8h 
# dhcp hostsfile
dhcp-hostsfile=/opt/IoTSecurityNAT/CONF/dhcphosts
# dhcp optsfile
dhcp-optsfile=/opt/IoTSecurityNAT/CONF/optsfile
# router
dhcp-option=3,10.42.0.1 
# dns server
dhcp-option=6,10.42.0.1 
```


## 源码结构
```
├── ArpList  // 存储arp信息
├── CONF  // 配置文件目录
│   ├── dhcphosts  // dhcphosts配置
│   ├── dnsfile // dns本地解析配置
│   ├── dnsmasq.conf  // dnsmasq配置文件
│   ├── hostapd.conf // hostapd配置文件（ssid、密码等）
│   └── optsfile // dnsmasq option配置文件
├── DeviceInfo // 标识设备信息（MAC、设备名、用户、备注等）
├── dns.sh // dns记录查看
├── monitor.sh // 环境配置（启动、停止、监控、调试）
├── proxy.sh // 代理规则配置（设备、规则修改查看）
└── README.md
```

## TODO
- 


## 参考

https://github.com/koenbuyens/kalirouter




