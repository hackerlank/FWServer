#!/bin/sh
funcKillProc(){
	param=$1
	ps -ef |grep $param |grep -v grep | awk '{print $2}' |while read pid
	do
		echo "---kill>>name=[$param], procid=[$pid]---"
		kill -9 $pid
	done
}
#funcKillProc "/usr/local/mongodb/bin/mongod"
funcKillProc "redis-server"
#echo "-----------start--mongodb---------------"
#/usr/local/mongodb/bin/mongod --dbpath=/usr/local/mongodb/data --logpath=/usr/local/mongodb/logs --logappend  --auth  --port=27017 --fork

echo "-----------start--redis---------------"
redis-server /etc/redis/redis.conf

echo "-----------stop--iptables---------------"
service iptables stop

echo "-----------start--end---------------"
ps -ef | grep redis


