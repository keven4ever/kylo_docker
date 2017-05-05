#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

# altering the core-site configuration
sed s/HOSTNAME/$HOSTNAME/ /usr/local/hadoop/etc/hadoop/core-site.xml.template2 > /usr/local/hadoop/etc/hadoop/core-site.xml

# setting spark defaults
echo spark.yarn.jar hdfs:///spark/spark-assembly-1.6.0-hadoop2.6.0.jar > $SPARK_HOME/conf/spark-defaults.conf
cp $SPARK_HOME/conf/metrics.properties.template $SPARK_HOME/conf/metrics.properties

service sshd start
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh

service mysql start
service elasticsearch start
service activemq start
service nifi start
service hive-server2 start


# For hive and spark sql integration, we can only do it at runtime since hostname is required in core-site.xml
cp $HADOOP_PREFIX/etc/hadoop/core-site.xml $SPARK_HOME/conf
# Somehow spark-defaults.conf always overwriten by some process, so we need to append mysql driver when run the container.
echo "spark.executor.extraClassPath $SPARK_HOME/lib/mysql-connector-java-5.1.41.jar" >> $SPARK_HOME/conf/spark-defaults.conf
echo "spark.driver.extraClassPath $SPARK_HOME/lib/mysql-connector-java-5.1.41.jar" >> $SPARK_HOME/conf/spark-defaults.conf

# sleep 5 sec to make sure nifi is ready
sleep 10s

/opt/kylo/start-kylo-apps.sh

cp -r /var/sampledata/* /var/dropzone/


CMD=${1:-"exit 0"}
if [[ "$CMD" == "-d" ]];
then
	service sshd stop
	/usr/sbin/sshd -D -d
else
	/bin/bash -c "$*"
fi