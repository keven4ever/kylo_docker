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
RUN ln -s /usr/local/apache-hive-2.1.1-bin /usr/local/hive
COPY ./hive-site.xml /usr/local/hive/conf
RUN echo "export HIVE_HOME=/usr/local/hive" >> /etc/profile
RUN echo "export PATH=$PATH:/usr/local/hive/bin">> /etc/profile
# Add kylo and nifi user to supergroup otherwise kylo-spark-shell service which runs as kylo user will not be able to create database in hive.
RUN groupadd supergroup
RUN usermod -a -G supergroup kylo
RUN usermod -a -G supergroup nifi
RUN echo "HADOOP_HOME=/usr/local/hadoop" >> /usr/local/hive/bin/hive-config.sh
# Download mysql jdbc driver and prepare hive metastore.
RUN wget http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.41/mysql-connector-java-5.1.41.jar && mv mysql-connector-java-5.1.41.jar /usr/local/apache-hive-2.1.1-bin/lib/
RUN service mysql start && cd /usr/local/hive/scripts/metastore/upgrade/mysql/ && mysql -uroot -phadoop -e "CREATE DATABASE hive;" && mysql -uroot -phadoop hive < ./hive-schema-2.1.0.mysql.sql
# ---- Hive installation finished -------


# Prepare spark-hive integration, so spark sql will use hive tables defined in hive metastore, see https://spark.apache.org/docs/1.6.0/sql-programming-guide.html#hive-tables
RUN cp /usr/local/hadoop/etc/hadoop/hdfs-site.xml /usr/local/spark/conf
RUN cp /usr/local/hive/conf/hive-site.xml /usr/local/spark/conf
RUN cp /usr/local/hive/lib/mysql-connector-java-5.1.41.jar /usr/local/spark/lib
# These two steps are for hive integration when use spark-shell directly., kylo-spark-shell managers classpath seperatly, see https://github.com/Teradata/kylo/blob/62037ddf09df0b9bff73360caa576ee7359a63aa/install/src/main/scripts/post-install.sh
#RUN echo "spark.executor.extraClassPath /usr/local/spark/lib/mysql-connector-java-5.1.41.jar" >> /usr/local/spark/conf/spark-defaults.conf
#RUN echo "spark.driver.extraClassPath /usr/local/spark/lib/mysql-connector-java-5.1.41.jar" >> /usr/local/spark/conf/spark-defaults.conf
# Make mysql driver available to kylo-spark-shell
RUN cp /usr/local/apache-hive-2.1.1-bin/lib/mysql-connector-java-5.1.41.jar /opt/nifi/mysql/
# ----- Spark-Hive integration finished ---------

VOLUME /var/dropzone
VOLUME /var/sampledata

COPY core-site.xml.template2 /usr/local/hadoop/etc/hadoop/


# be careful below (1) we need to copy hadoop core-site.xml to spark folder when run container since the hostname is generated at this stage and needs to available in core-site.xml.
# (2) Somehow spark-defaults.conf always overwriten by some process, so we need to append mysql driver when run the container.
# (3) we need to first start hive than start spark since spark sql always generate hive 1.2 schema and hive2 will have compatible issue with it.
CMD 'service mysql start && service elasticsearch start && service activemq start && service nifi start \
&& cp /usr/local/hadoop/etc/hadoop/core-site.xml /usr/local/spark/conf \
&& echo "spark.executor.extraClassPath /usr/local/spark/lib/mysql-connector-java-5.1.41.jar" >> /usr/local/spark/conf/spark-defaults.conf \
&& echo "spark.driver.extraClassPath /usr/local/spark/lib/mysql-connector-java-5.1.41.jar" >> /usr/local/spark/conf/spark-defaults.conf \
&& sed s/HOSTNAME/$HOSTNAME/ /usr/local/hadoop/etc/hadoop/core-site.xml.template2 > /usr/local/hadoop/etc/hadoop/core-site.xml \
&& /usr/local/hadoop/sbin/stop-dfs.sh && /usr/local/hadoop/sbin/start-dfs.sh \
&& source /etc/profile \
&& bash'
EXPOSE 8400