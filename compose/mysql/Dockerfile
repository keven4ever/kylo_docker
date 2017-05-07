FROM mariadb:10.1.10

ENV MYSQL_ROOT_PASSWORD hadoop

RUN mkdir -p ./kylo_setup/

ADD ./scripts ./kylo_setup/

RUN chmod +x kylo_setup/run.sh

CMD ["kylo_setup/run.sh"]