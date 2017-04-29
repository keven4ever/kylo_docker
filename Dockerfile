FROM sequenceiq/spark:1.6.0
RUN /bin/bash -c 'yum -y install wget;exit 0'
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
COPY ./setup_kylo.sh .
RUN chmod +x setup_kylo.sh && ./setup_kylo.sh
VOLUME /var/dropzone
EXPOSE 8400