FROM sequenceiq/spark:1.6.0
RUN /bin/bash -c 'yum -y install wget java-1.8.0-openjdk-headless.x86_64; exit 0'
COPY ./MariaDB.repo /etc/yum.repos.d/
COPY ./setup_mysql.sh .
RUN chmod +x setup_mysql.sh && ./setup_mysql.sh
#RUN /bin/bash -c 'yum install -y mariadb mariadb-server;\
#service mysql start; \
#chkconfig mysql on'
#RUN service mysql start && sleep 5 && mysql -uroot -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('hadoop'); FLUSH PRIVILEGES;"  && mysql -uroot -phadoop -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'hadoop'"
#RUN /bin/bash -c 'useradd -r -m -s /bin/bash nifi; \
#useradd -r -m -s /bin/bash kylo; \
#useradd -r -m -s /bin/bash activemq'
#RUN wget http://bit.ly/2oVaQJE -O kylo-0.8.0.1.rpm && rpm -ivh kylo-0.8.0.1.rpm && rm kylo-0.8.0.1.rpm

RUN /bin/bash -c 'useradd -r -m -s /bin/bash nifi; \
useradd -r -m -s /bin/bash kylo; \
useradd -r -m -s /bin/bash activemq'

RUN /bin/bash -c 'echo \"Downloading the RPM\";\
wget http://bit.ly/2oVaQJE -O kylo-0.8.0.1.rpm;\
rpm -ivh kylo-0.8.0.1.rpm;\
rm kylo-0.8.0.1.rpm'

RUN service mysql start && echo "Setup database in MySQL" && /opt/kylo/setup/sql/mysql/setup-mysql.sh localhost root hadoop

RUN echo "Install Elasticsearch" && /opt/kylo/setup/elasticsearch/install-elasticsearch.sh

RUN echo "Install activemq" && /opt/kylo/setup/activemq/install-activemq.sh

RUN echo "Install NiFi" && /opt/kylo/setup/nifi/install-nifi.sh

RUN echo "Install Kylo" && service mysql start && /opt/kylo/setup/nifi/install-kylo-components.sh

RUN rm -f /opt/nifi/nifi-1.0.0-bin.tar.gz

RUN echo "Creating the dropzone folder" && mkdir -p /var/dropzone
#chown nifi:hdfs /var/dropzone
#chmod 774 /var/dropzone/

RUN echo "Creating the sample data folder" && mkdir -p /var/sampledata

# echo "Moving sample files"
# mv /tmp/allevents.csv /var/sampledata
# mv /tmp/userdata2.csv /var/sampledata
# mv /tmp/userdata6.csv /var/sampledata
# mv /tmp/venue.csv /var/sampledata
# mv /tmp/toys.sql /var/sampledata

#chown -R kylo:kylo /var/sampledata

RUN echo "Kylo Installation complete"

# add spark and hadoop path to PATH env variable for kylo user
RUN echo "export PATH=$PATH:/usr/java/default/bin:/usr/local/spark/bin:/usr/local/hadoop/bin" >> /etc/profile
#COPY ./setup_kylo.sh .
#RUN chmod +x setup_kylo.sh && ./setup_kylo.sh

# Install hive
RUN wget http://apache.mirrors.spacedump.net/hive/hive-2.1.1/apache-hive-2.1.1-bin.tar.gz
RUN tar xvf apache-hive-2.1.1-bin.tar.gz
RUN rm ./apache-hive-2.1.1-bin.tar.gz
RUN mv ./apache-hive-2.1.1-bin /usr/local/
COPY ./hive-site.xml /usr/local/apache-hive-2.1.1-bin/conf
RUN echo "export HIVE_HOME=/usr/local/apache-hive-2.1.1-bin" >> /etc/profile
RUN echo "export PATH=$PATH:/usr/local/apache-hive-2.1.1-bin/bin">> /etc/profile
RUN groupadd supergroup
RUN usermod -a -G supergroup kylo
RUN usermod -a -G supergroup nifi
RUN echo "HADOOP_HOME=/usr/local/hadoop" >> /usr/local/apache-hive-2.1.1-bin/bin/hive-config.sh
#RUN hadoop dfs -mkdir -p /user/hive/warehouse
#RUN hadoop dfs -chown kylo /user/hive/warehouse
#RUN hadoop dfs -chown kylo:kylo /user/hive/warehouse
RUN wget http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.41/mysql-connector-java-5.1.41.jar && mv mysql-connector-java-5.1.41.jar /usr/local/apache-hive-2.1.1-bin/lib/
RUN cp /usr/local/hadoop/etc/hadoop/hdfs-site.xml /usr/local/spark/conf
RUN cp /usr/local/apache-hive-2.1.1-bin/conf/hive-site.xml /usr/local/spark/conf
RUN cp /usr/local/apache-hive-2.1.1-bin/lib/mysql-connector-java-5.1.41.jar /usr/local/spark/lib
RUN echo "spark.executor.extraClassPath /usr/local/spark/lib/mysql-connector-java-5.1.41.jar" >> /usr/local/spark/conf/spark-defaults.conf
RUN echo "spark.driver.extraClassPath /usr/local/spark/lib/mysql-connector-java-5.1.41.jar" >> /usr/local/spark/conf/spark-defaults.conf
RUN service mysql start && cd /usr/local/apache-hive-2.1.1-bin/scripts/metastore/upgrade/mysql/ && mysql -uroot -phadoop -e "CREATE DATABASE hive;" && mysql -uroot -phadoop hive < ./hive-schema-2.1.0.mysql.sql

VOLUME /var/dropzone
VOLUME /var/sampledata
CMD 'service mysql start \
&& service elasticsearch start \
&& service activemq start && service nifi start \
&& cp /usr/local/hadoop/etc/hadoop/core-site.xml /usr/local/spark/conf \
&& echo "spark.executor.extraClassPath /usr/local/spark/lib/mysql-connector-java-5.1.41.jar" >> /usr/local/spark/conf/spark-defaults.conf \
&& echo "spark.driver.extraClassPath /usr/local/spark/lib/mysql-connector-java-5.1.41.jar" >> /usr/local/spark/conf/spark-defaults.conf && bash'
EXPOSE 8400