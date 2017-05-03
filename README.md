## Introduction
This image is based on vanilla spark image and Setup Wizard Deployment Guide from kylo.io, https://kylo.readthedocs.io/en/latest/installation/KyloSetupWizardDeploymentGuide.html#
The spark image is the most popular spark image on docker hub, https://hub.docker.com/r/sequenceiq/spark/, so the baseline is:
-   CentOS 6.5
-   Hadoop 2.6.0
-   Spark 1.6.0
-   JDK 1.5

Most of them are a little bit old, i agree, which brings some pb for me, see below

## How to build image
docker build -t <image name>:<version> .

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



## How to run
1.change "vm.max_map_count" kernel varialble in the VM running docker daemon: https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode.
```
screen ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty
login
root
sysctl -w vm.max_map_count=262144
```
ctrl-A + D to exist the screen session.
2.Start container
```
docker run -it -p 8400:8400 -v <local directory to be mapped>:/var/share kylo:0.7 bash
```
3.after few mins, access http://localhost:8400 from host browser and login with dladmin/thinkbig
5.After login, import template first, then create a categoly, then start to import feed
