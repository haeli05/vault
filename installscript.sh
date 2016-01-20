#!/bin/sh

echo '===========================================updating packages==========================================='
apt-get update -y
apt-get upgrade -y

echo "===========================================installing python==========================================="

apt-get install python-pip python-m2crypto python-gevent fail2ban -y

echo '===========================================installing shadowsocks==========================================='

pip install shadowsocks 

echo "===========================================installing chacha20==========================================="

apt-get install build-essential -y

wget https://github.com/jedisct1/libsodium/releases/download/1.0.3/libsodium-1.0.3.tar.gz
tar xf libsodium-1.0.3.tar.gz && cd libsodium-1.0.3

 ./configure && sudo make && sudo make install

ldconfig

pip install superlance 

apt-get install supervisor -y
 
 
echo "===========================================finished installs, now configuring IPtables==========================================="
 
#non root
adduser ssuser
usermod -a -G sudo ssuser

#sssetings then IPTABLES
wget https://raw.githubusercontent.com/haeli05/vault/master/supervisor.conf -O /etc/supervisor/conf.d/shadowsocks.conf
wget https://raw.githubusercontent.com/haeli05/vault/master/shadowsocks.conf -O /etc/sysctl.d/local.conf

sysctl --system

modprobe tcp_hybla




service supervisor stop
echo 'ulimit -n 51200' >> /etc/default/supervisor
service supervisor start

echo "* soft nofile 51200" >> /etc/security/limits.conf
echo "* hard nofile 51200" >> /etc/security/limits.conf



#delete rules for eth0
/sbin/tc qdisc del dev eth0 root


#queuing discipline
/sbin/tc qdisc add dev eth0 root handle 1:0 htb 

#class w rate , ceil = max kilobytes not bits 
/sbin/tc class add dev eth0 parent 1: classid 1:1 htb rate 1048576kbps

#each sub branch, 22 high prio for ssh, NO SPACE FOR kbps
/sbin/tc class add dev eth0 parent 1:1 classid 1:5 htb rate 1024kbps ceil 2048kbps prio 0

#userports
/sbin/tc class add dev eth0 parent 1:1 classid 1:6 htb rate 10240kbps ceil 12288kbps prio 1

#limits each port to 32 simult connections
/sbin/iptables -A INPUT -p tcp --syn -match multiports --dport 8000:8020 -m connlimit --connlimit-above 32 -j REJECT --reject-with tcp-reset

#accept connections to ssh, 80, 443, userrange
iptables -t filter -m owner --uid-owner ssuser -A OUTPUT -p tcp -match multiport --dport 22,80,443 -j ACCEPT

iptables -t filter -m owner --uid-owner ssuser -A OUTPUT -p tcp -match multiport --dport 8000:8020 -j ACCEPT

#reject all other connections
iptables -t filter -m owner --uid-owner ssuser -A OUTPUT -p tcp -j REJECT --reject-with tcp-reset 
 
#assign to ports
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 22 -j MARK --set-mark 5

/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 443 -j MARK --set-mark 6

/sbin/iptables -A OUTPUT -t mangle -p tcp -match multiports --sport 8000:8020 -j MARK --set-mark 6


echo "===========================================IPtables set==========================================="

iptables-save > /etc/iptables/rules.v4

echo "===========================================IPTABLES SAVED==========================================="

apt-get install iptables-persistent -y

echo "===========================================IPtables persistent installed==========================================="

echo "===========================================Installing wondershaper==========================================="

apt-get install wondershaper -y

# limit bandwidth to 40000Mb/125Mb up(linode limite) on eth0

wondershaper eth0 40960000 125000

echo "===========================================nginx for blocking BitTorrent trackers==========================================="

apt-get install nginx denyhosts -y

#redirects torrent trackers to nginx

iptables -t nat -m owner --uid-owner ssuser -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 3128



