FROM sequenceiq/spark:1.6.0
RUN /bin/bash -c 'yum -y install wget java-1.8.0-openjdk-headless.x86_64; exit 0'
COPY conf/MariaDB.repo /etc/yum.repos.d/
COPY scripts/setup_mysql.sh .
RUN chmod +x setup_mysql.sh && ./setup_mysql.sh

# RUN /bin/bash -c 'useradd -r -m -s /bin/bash nifi; \
# useradd -r -m -s /bin/bash kylo; \
# useradd -r -m -s /bin/bash activemq'

RUN /bin/bash -c 'echo \"Downloading the RPM\";\
wget http://bit.ly/2oVaQJE -O kylo-0.8.0.1.rpm;\
rpm -ivh kylo-0.8.0.1.rpm;\
rm kylo-0.8.0.1.rpm'

RUN service mysql start && echo "Setup database in MySQL" && /opt/kylo/setup/sql/mysql/setup-mysql.sh localhost root hadoop

RUN echo "Install Elasticsearch" && /opt/kylo/setup/elasticsearch/install-elasticsearch.sh

RUN echo "Install activemq" && /opt/kylo/setup/activemq/install-activemq.sh

# RUN echo "Install NiFi" && /opt/kylo/setup/nifi/install-nifi.sh

# RUN echo "Install Kylo" && service mysql start && /opt/kylo/setup/nifi/install-kylo-components.sh

RUN rm -f /opt/nifi/nifi-1.0.0-bin.tar.gz

# RUN echo "Creating the dropzone folder" && mkdir -p /var/dropzone
# RUN chown nifi:nifi /var/dropzone
# RUN chmod 774 /var/dropzone/

# RUN echo "Creating the sample data folder" && mkdir -p /var/sampledata

# COPY sample_data/* /var/sampledata/

# RUN chown -R kylo:kylo /var/sampledata

# ENV KYLO_HOME=/opt/kylo
# ENV PATH $PATH:$KYLO_HOME
# COPY conf/application.properties /opt/kylo/kylo-services/conf/

# RUN echo "Kylo Installation complete"

# add spark and hadoop path to PATH env variable for kylo user
RUN echo "export PATH=$PATH:/usr/java/default/bin:/usr/local/spark/bin:/usr/local/hadoop/bin" >> /etc/profile

# Install hive
RUN wget http://apache.mirrors.spacedump.net/hive/hive-2.1.1/apache-hive-2.1.1-bin.tar.gz
RUN tar xvf apache-hive-2.1.1-bin.tar.gz
RUN rm ./apache-hive-2.1.1-bin.tar.gz
RUN mv ./apache-hive-2.1.1-bin /usr/local/
RUN ln -s /usr/local/apache-hive-2.1.1-bin /usr/local/hive
COPY conf/hive-site.xml /usr/local/hive/conf
RUN echo "export HIVE_HOME=/usr/local/hive" >> /etc/profile
RUN echo "export PATH=$PATH:/usr/local/hive/bin">> /etc/profile
ENV HIVE_HOME /usr/local/hive
ENV PATH $PATH:$HIVE_HOME/bin
# Create directory for hive logs
RUN mkdir -p /var/log/hive
# Increase PermGen space for hiveserver2 to fix OOM pb.
COPY conf/hive-env.sh /usr/local/hive/conf/
# Add kylo and nifi user to supergroup otherwise kylo-spark-shell service which runs as kylo user will not be able to create database in hive.
RUN groupadd supergroup
RUN usermod -a -G supergroup kylo
RUN usermod -a -G supergroup nifi
RUN echo "HADOOP_HOME=/usr/local/hadoop" >> /usr/local/hive/bin/hive-config.sh
# Download mysql jdbc driver and prepare hive metastore.
RUN wget http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.41/mysql-connector-java-5.1.41.jar && mv mysql-connector-java-5.1.41.jar /usr/local/apache-hive-2.1.1-bin/lib/
RUN service mysql start && cd /usr/local/hive/scripts/metastore/upgrade/mysql/ && mysql -uroot -phadoop -e "CREATE DATABASE hive;" && mysql -uroot -phadoop hive < ./hive-schema-2.1.0.mysql.sql
# create hiveserver2 service
COPY conf/hive-server2 /etc/init.d/
RUN chmod +x /etc/init.d/hive-server2
RUN chkconfig --add /etc/init.d/hive-server2
# ---- Hive installation finished -------


# Prepare spark-hive integration, so spark sql will use hive tables defined in hive metastore, see https://spark.apache.org/docs/1.6.0/sql-programming-guide.html#hive-tables
RUN cp /usr/local/hadoop/etc/hadoop/hdfs-site.xml /usr/local/spark/conf
RUN cp /usr/local/hive/conf/hive-site.xml /usr/local/spark/conf
RUN cp /usr/local/hive/lib/mysql-connector-java-5.1.41.jar /usr/local/spark/lib
# Make mysql driver available to kylo-spark-shell
# RUN cp /usr/local/apache-hive-2.1.1-bin/lib/mysql-connector-java-5.1.41.jar /opt/nifi/mysql/
# ----- Spark-Hive integration finished ---------

RUN mkdir -p /var/share
VOLUME /var/share

COPY conf/core-site.xml.template2 /usr/local/hadoop/etc/hadoop/

COPY scripts/bootstrap_base.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

ENTRYPOINT ["/etc/bootstrap.sh"]

EXPOSE 10000