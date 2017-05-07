FROM mariadb:10.1.13

ENV MYSQL_ROOT_PASSWORD hadoop

RUN mkdir -p ./kylo_setup/
ADD ./scripts ./kylo_setup/
CMD mysqld ; kylo_setup/mysql/setup-mysql.sh localhost root hadoop