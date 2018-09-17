#! /bin/bash
# tomyu的CentOS 一键设置脚本
# CentOS 7

# 时间相关
set_time(){
	# 设置上海时区
	cp -p /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	# 同步阿里云时间
	ntpdate times.aliyun.com
}

# 获取网卡的名字
get_wan(){
	wan=$(ls /sys/class/net | awk '{print $1}'|head -1)
}

# 安装ohmyzsh
ohmyzsh_install(){
	git clone https://github.com/robbyrussell/oh-my-zsh
	mv oh-my-zsh .oh-my-zsh
	cp .oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc
	sed -i 's/"robbyrussell"/"ys"/g' ~/.zshrc
	chsh -s /bin/zsh
}

# 安装vnstat
vnstat_install(){
	sed -i "s#"eth0"#${wan}#g" /etc/vnstat.conf
	vnstat --create -i $wan
	systemctl restart vnstat
	chown vnstat:vnstat /var/lib/vnstat/$wan
}

# 运行vnstat
vnstat_run(){
	vnstat -u -i $wan
}

# yum更新
yum_update(){
	yum install epel-release -y && yum install vnstat iftop net-tools git wget curl ntpdate zsh -y
}

# 关闭selinux
disable_selinux(){
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0
}

# 打开文件限制修改
set_ulimit(){
	ulimit -n 102400
	echo '* soft nofile 102400
* hard nofile 102400' >> /etc/security/limits.conf
}

set_sysctl(){
	echo 'fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla' >> /etc/sysctl.conf
	sysctl -p
}

set_time
yum_update
get_wan
vnstat_install
vnstat_run
ohmyzsh_install
disable_selinux
set_ulimit
set_sysctl
