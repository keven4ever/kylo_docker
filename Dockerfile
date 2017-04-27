FROM sequenceiq/spark:1.6.0
#RUN /bin/bash -c 'yum clean all'
RUN /bin/bash -c 'yum -y install wget expect java-1.8.0-openjdk-headless.x86_64;exit 0'
RUN /bin/bash -c 'wget http://bit.ly/2oVaQJE -O kylo.rpm'
RUN wget http://dev.mysql.com/get/mysql57-community-release-el6-7.noarch.rpm
RUN yum localinstall -y mysql57-community-release-el6-7.noarch.rpm; exit 0
RUN yum clean all
RUN yum install -y mysql-community-server
COPY ./auto_wizard.sh .
COPY ./mysql_init.sh .
RUN chmod +x auto_wizard.sh && chmod +x mysql_init.sh
RUN ./mysql_init.sh
RUN /bin/bash -c 'useradd -r -m -s /bin/bash nifi; \
useradd -r -m -s /bin/bash kylo; \
useradd -r -m -s /bin/bash activemq'
RUN /bin/bash -c 'rpm -ivh kylo.rpm'
RUN /bin/bash -c 'mkdir -p /var/dropzone; \
chown nifi /var/dropzone'
RUN ./auto_wizard.sh
RUN sed -i 's/spring.datasource.password=hadoop/spring.datasource.password=1qaz!QAZ/g' /opt/kylo/kylo-services/conf/application.properties
EXPOSE 8400
