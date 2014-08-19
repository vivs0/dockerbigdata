#!/bin/bash
#
#sudo ./startup.sh

WAITING_TIME=64
waitfunc()
{
	CURRENT=0
	while [ $CURRENT -le $WAITING_TIME ]; do
		CURRENT=$(($CURRENT + 1))
		RESULT=$(sudo docker logs $1 2>&1)
		if grep -q "$2" <<< $RESULT ; then
			break
		fi
		sleep 1
	done
}

echo -e "Starting...\nIt will take some time.\n"

#remove before container
docker rm -f data 1>&- 2>&-
docker rm -f zookeeper 1>&- 2>&-
docker rm -f kafka 1>&- 2>&-
docker rm -f appflume 1>&- 2>&-
docker rm -f hadoop 1>&- 2>&-
docker rm -f elasticsearch 1>&- 2>&-
docker rm -f flume 1>&- 2>&-
docker rm -f storm 1>&- 2>&-

#run
docker run -d -P --name data moonnoon/data:testing
docker run -d -P --volumes-from data --name zookeeper moonnoon/zookeeper:testing
#waiting for zookeeper finish start
waitfunc zookeeper 'binding to port 0.0.0.0/0.0.0.0:2181'

docker run -d -P --volumes-from data --name kafka --link zookeeper:zookeeper moonnoon/kafka:testing
#waiting for zookeeper finish start
waitfunc kafka 'INFO success: kafka entered RUNNING state'

docker run -d -P --volumes-from data --name storm --link zookeeper:zookeeper moonnoon/storm:testing
ID=$(sudo docker run -d -P --volumes-from data --name appflume --link zookeeper:zookeeper --link kafka:kafka moonnoon/appflume:testing)
docker run -d -P --volumes-from data --name hadoop --link zookeeper:zookeeper  moonnoon/hadoop:testing
docker run -d -P --volumes-from data --name elasticsearch --link zookeeper:zookeeper moonnoon/elasticsearch:testing

#waiting for hadoop finish start
waitfunc hadoop 'INFO exited: dfs (exit status 0; expected)'

docker run -d -P --volumes-from data --name flume --link zookeeper:zookeeper --link hadoop:hadoop --link elasticsearch:elasticsearch moonnoon/flume:testing

#
IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' $ID)

echo -e "\nplease connect $IP:44444 or localhost:$(docker port appflume 44444 | cut -d":" -f2)"
