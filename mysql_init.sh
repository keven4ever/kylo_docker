#!/bin/bash
service mysqld start
psd=$(grep -E 'A temporary password is generated for ' /var/log/mysqld.log |awk '{print $11}')
echo "psd is $psd"
MYSQL_ROOT_PASSWORD=1qaz!QAZ

SECURE_MYSQL=$(expect -c "
set timeout 5
spawn /usr/bin/mysql_secure_installation
expect \"Enter password for user root:\"
send \"$psd\r\"
expect \"New password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Change the password for root ? ((Press y|Y for Yes, any other key for No) :\"
send \"Y\r\"
expect \"New password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
send \"Y\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"n\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"
