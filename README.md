## Introduction
This image is based on vanilla spark image and Setup Wizard Deployment Guide from kylo.io, https://kylo.readthedocs.io/en/latest/installation/KyloSetupWizardDeploymentGuide.html#
The spark image is the most popular spark image on docker hub, https://hub.docker.com/r/sequenceiq/spark/, so the baseline is:
-   CentOS 6.5
-   Hadoop 2.6.0
-   Spark 1.6.0
-   JDK 1.5

Most of them are a little bit old, i agree, which brings some pb for me, see below

## How to build image

docker build -t "image name":"image version" .

## Lessons learnt
It takes much more time to build this image, lots of trivial problem, so i decided to write them down and anyone else who wants to install kylo manually might be interested.
-	ElasticSearch & JDK 7
	    - ES requires JDK 7.0+ ; Kylo installation includes JDK 8.0 but after ElasticSearch installation
	    - Solution: Swap the steps
-	ElasticSearch requires kernel parameter modification
	    - Set “vm.max_map_count” to 262144
	    - Docker 0.11 restrict accessing /proc & /sys for security by default
	    - Solution 1: Privileged container -> not valid
	    - Only in runtime (“docker run”) but not in build phase (”docker build”)
	    - Solution 2: Modify the host parameter, VM runs the Docker daemon, see https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode
-   MySQL & MariaDB
    - MySQL 5.7.7+ required for long table index
    - Complicated initial password setup since MySQL 5.7
    - MariaDB is fork of MySQL with high compatibility, i.e JDBC driver
-   Hive server related
    - By default, Hiverserver2 will suffer with insufficient PermGen space, then it ends up connection refuse when connects it through JDBC. So, you have to add some JVM options in hive-site.xml to increase the PermGen space.
-   Spark SQL interact with Hive
    - Access the same Metastore
        - Configuration files: hive-site.xml, hdfs-site.xml, core-site.xml, see http://spark.apache.org/docs/1.6.0/sql-programming-guide.html#hive-tables
        - Classpath issue, spark-defaults.xml, kylo-post installation, MariaDB driver, etc
    - User access to Hive
        - Pb: Spark-shell launch by kylo-spark-shell as ”kylo” user
        - Solution: Create dfs dir “/user/hive/warehouse” and change owner to kylo
    - SparkSQL and Hive2 schema version incompatibility issue
        - Pb: independent of the version of Hive, Spark SQL will compile against Hive 1.2.1
        - Solution: Ignore schema version validation in hive, see hive-site.xml
-   kylo related
    - There is a common security key namely "security.jwt.key" configed in application.properties of both kylo-ui and kylo-services which are generated in kylo post-installation, they should have the same value, otherwise there will be some HTTP 401 Unauthorized error. So be careful when replace the application.properties. 

## How to run
1. Change "vm.max_map_count" kernel varialble in the VM running docker daemon: https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode.
So if you are using macbook with Docker for Mac installed (note, docker for mac https://docs.docker.com/docker-for-mac/install/ is different from previous generation of docker on mac which is Docker machine https://docs.docker.com/machine/), then you can follow steps below
```
# Launch a termal in your macbook and start a screen session to connect to the VM which is the host of docker containers
screen ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty
# Click "enter" once to get shell promot, then type in shell command "login"
/ # login
# input login credential, root/<empty password>
moby login: root
# Input empty pwd by click enter
# Set the parameter
moby:~#sysctl -w vm.max_map_count=262144
# Then you can check if this parameter is set:
moby:~# sysctl vm.max_map_count
# You should see sth like below
vm.max_map_count = 262144
# At the end exit the screen session by type in Ctrl-A + D to exist the screen session, Hold Ctrl and A together then click D.
```
2. Start container
```
docker run -it -v <absoluate path of your local directory to be mounted to container>:/var/share -p 8400:8400 -p 8079:8079 -p 3306:3306 -p 10000:10000 keven4ever/kylo_docker:kylo-0.8.0.1 bash
```
3. After few mins, access http://localhost:8400 from host browser and login with dladmin/thinkbig
4. After login, import template first, then create a categoly, then start to import feed.
