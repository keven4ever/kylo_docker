#!/bin/bash

echo "Install MySQL" 
yum install -y mariadb mariadb-server
service mysql start
chkconfig mysql on
mysql -uroot -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('hadoop'); FLUSH PRIVILEGES;"
mysql -uroot -phadoop -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'hadoop'"
echo "MySQL installation complete"