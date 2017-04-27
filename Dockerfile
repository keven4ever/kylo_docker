FROM sequenceiq/spark:1.6.0
RUN /bin/bash -c 'yum clean all'
RUN /bin/bash -c 'yum -y install wget expect java-1.8.0-openjdk-headless.x86_64;exit 0'
RUN /bin/bash -c 'wget http://bit.ly/2oVaQJE -O kylo.rpm'
#RUN /bin/bash -c 'yum -y install mysql-server vim;exit 0'
#RUN /bin/bash -c '/sbin/service mysqld start'
COPY ./mysql_secure_installation.sql .
COPY ./auto_wizard.sh .
COPY ./CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
RUN /bin/bash -c 'wget https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6-x86_64/pgdg-centos96-9.6-3.noarch.rpm'
RUN /bin/bash -c 'rpm -ivh pgdg*'
RUN /bin/bash -c 'yum install -y postgresql96-server; exit 0'
RUN service postgresql-9.6 initdb && chkconfig postgresql-9.6 on
RUN service postgresql-9.6 start && su postgres -c "psql -c \"update pg_database set encoding = 6, datcollate = 'en_US.UTF8', datctype = 'en_US.UTF8' where datname = 'template0'; update pg_database set encoding = 6, datcollate = 'en_US.UTF8', datctype = 'en_US.UTF8' where datname = 'template1';\"" && service postgresql-9.6 stop
#RUN service postgresql-9.6 start && /bin/sleep 5 && su postgres -c "psql -c \"UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';BEGIN \rDROP DATABASE template1\rCOMMIT;CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UTF8';UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';\""
COPY ./pg_hba.conf /var/lib/pgsql/9.6/data/pg_hba.conf
RUN service postgresql-9.6 reload && service postgresql-9.6 start && su postgres -c "psql -c \"CREATE USER kylo WITH PASSWORD 'kylo'; ALTER USER kylo with superuser;\""
RUN /bin/bash -c 'chmod +x auto_wizard.sh'
RUN /bin/bash -c 'useradd -r -m -s /bin/bash nifi; \
useradd -r -m -s /bin/bash kylo; \
useradd -r -m -s /bin/bash activemq'
RUN /bin/bash -c 'rpm -ivh kylo.rpm'
RUN /bin/bash -c 'mkdir -p /var/dropzone; \
chown nifi /var/dropzone'
# RUN /bin/bash -c '/opt/kylo/start-kylo-apps.sh'
EXPOSE 8400
