#!/bin/sh
echo 'updating packages'
sudo apt-get update -y
sudo apt-get upgrade -y

echo "installing python"

sudo apt-get install python-pip python-m2crypto python-gevent fail2ban -y

echo 'installing shadowsocks'

sudo pip install shadowsocks 

echo "installing chacha20"

sudo apt-get install build-essential -y

wget https://github.com/jedisct1/libsodium/releases/download/1.0.3/libsodium-1.0.3.tar.gz
tar xf libsodium-1.0.3.tar.gz && cd libsodium-1.0.3

sudo ./configure && sudo make && sudo make install

sudo ldconfig

sudo pip install superlance 

sudo apt-get install supervisor -y
 
 
echo "finished installs, now configuring IPtables"
 
#sssetings then IPTABLES
sudo -s

wget https://raw.githubusercontent.com/shadowsocks/stackscript/master/shadowsocks.conf -O /etc/supervisor/conf.d/shadowsocks.conf

wget https://raw.githubusercontent.com/shadowsocks/stackscript/master/local.conf -O /etc/sysctl.d/local.conf





service supervisor stop
echo 'ulimit -n 51200' >> /etc/default/supervisor
service supervisor start


#delete rules for eth0
/sbin/tc qdisc del dev eth0 root



#queuing discipline
/sbin/tc qdisc add dev eth0 root handle 1:0 htb 

#class w rate , ceil = max kilobytes not bits this is total
/sbin/tc class add dev eth0 parent 1: classid 1:1 htb rate 1048576kbps

#each sub branch, 22 high prio, NO SPACE FOR kbps
/sbin/tc class add dev eth0 parent 1:1 classid 1:5 htb rate 1024kbps ceil 2048kbps prio 0

#userports, doesnt matter if 22 not involved
/sbin/tc class add dev eth0 parent 1:1 classid 1:6 htb rate 10240kbps ceil 12288kbps prio 1
 
#assign to ports
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 22 -j MARK --set-mark 5

/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 443 -j MARK --set-mark 6

/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8000 -j MARK --set-mark 6
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8001 -j MARK --set-mark 6
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8002 -j MARK --set-mark 6
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8003 -j MARK --set-mark 6
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8004 -j MARK --set-mark 6
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8005 -j MARK --set-mark 6
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8006 -j MARK --set-mark 6
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8007 -j MARK --set-mark 6
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8008 -j MARK --set-mark 6
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8009 -j MARK --set-mark 6
/sbin/iptables -A OUTPUT -t mangle -p tcp --sport 8010 -j MARK --set-mark 6

echo "IPtables set"

iptables-save > /etc/iptables/rules.v4

echo "IPTABLES SAVED"

apt-get install iptables-persistent

echo "IPtables persistent installed"