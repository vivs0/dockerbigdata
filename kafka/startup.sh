#!/bin/bash
#
#startup.sh

export TOPIC=test

#configure
sed -i "s/^#advertised.host.name=<hostname routable by clients>/advertised.host.name=$(hostname -i)/" /opt/kafka/config/server.properties

#start kafka server
service supervisor start
sleep 1s

#create a topic "test" with single partion and only one replica
bin/kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 1 --partitions 1 --topic $TOPIC

#change to foreground
service supervisor stop
sed -i "s/nodaemon=false/nodaemon=true/" /etc/supervisor/conf.d/supervisord.conf
sleep 1s
service supervisor start
