#!/bin/bash

#Start mysql
mysqld
echo "Create Kylo database"
kylo_setup/mysql/setup-mysql.sh localhost root hadoop
echo "Create hive database"
mysql -uroot -phadoop -e "CREATE DATABASE hive;" 
cd kylo_setup/hive ; mysql -uroot -phadoop hive < ./hive-schema-2.1.0.mysql.sql 

echo "Mysql databases created"