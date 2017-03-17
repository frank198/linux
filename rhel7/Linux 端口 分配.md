## 知识点

总端口： 65535 2^16 = 65536 范围： 0 ~ 65535

## 常用

### tcp

21 ftp
22 ssh
23 telnet
25 smtp
53 DNS



## 查看端口监听状态
 
### netstat

-a
-n
-p
-t
-u

#### 常用
```sh
netstat -antpu
```

## 配置网络 IP

### nmtui-edit eno16777736

### vim /etc/sysconfig/network-scripts/ifcfg-eno16777736

### NetworkManager 服务

### 重启网络服务器 network


## 修改主机名
```sh
vim /etc/hostname
```

## 配置域名

``` sh
vim /etc/hosts
```

## 查看默认网关
route -n 

## ping 查看网络状态

-c 数目
-i 秒数
