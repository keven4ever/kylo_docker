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

#COPY ./setup_kylo.sh .
#RUN chmod +x setup_kylo.sh && ./setup_kylo.sh
VOLUME /var/dropzone
VOLUME /var/sampledata
CMD 'service mysql start && service elasticsearch start && service activemq start && service nifi start && bash'
EXPOSE 8400
