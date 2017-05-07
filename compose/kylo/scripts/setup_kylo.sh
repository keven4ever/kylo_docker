#!/bin/bash

echo "Create users"
# required for rpm install.
useradd -r -m -s /bin/bash nifi
useradd -r -m -s /bin/bash kylo
useradd -r -m -s /bin/bash activemq

service mysql start

echo "Downloading the RPM"
wget http://bit.ly/2oVaQJE -O kylo-0.8.0.1.rpm
rpm -ivh kylo-0.8.0.1.rpm
rm kylo-0.8.0.1.rpm

echo "Setup database in MySQL"
/opt/kylo/setup/sql/mysql/setup-mysql.sh localhost root hadoop

# First install java8 since elasticsearch demonds JDK 5.0+
# /opt/kylo/setup/java/install-java8.sh

# also set JAVA_HOME in this step
# /opt/kylo/setup/java/change-nifi-java-home.sh /opt/java/current

echo "Install Elasticsearch"
/opt/kylo/setup/elasticsearch/install-elasticsearch.sh

echo "Install activemq"
/opt/kylo/setup/activemq/install-activemq.sh

echo "Install NiFi"
/opt/kylo/setup/nifi/install-nifi.sh

echo "Install Kylo"
/opt/kylo/setup/nifi/install-kylo-components.sh

rm -f /opt/nifi/nifi-1.0.0-bin.tar.gz

echo "Creating the dropzone folder"
mkdir -p /var/dropzone
#chown nifi:hdfs /var/dropzone
#chmod 774 /var/dropzone/

echo "Creating the sample data folder"
mkdir -p /var/sampledata

echo "Moving sample files"
# mv /tmp/allevents.csv /var/sampledata
# mv /tmp/userdata2.csv /var/sampledata
# mv /tmp/userdata6.csv /var/sampledata
# mv /tmp/venue.csv /var/sampledata
# mv /tmp/toys.sql /var/sampledata

#chown -R kylo:kylo /var/sampledata

echo "Kylo Installation complete"