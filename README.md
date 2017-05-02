## Introduction
This image is based on vanilla spark image and Setup Wizard Deployment Guide from kylo.io, https://kylo.readthedocs.io/en/latest/installation/KyloSetupWizardDeploymentGuide.html#
The spark image is the most popular spark image on docker hub, https://hub.docker.com/r/sequenceiq/spark/, so the baseline is:
-   CentOS 6
-   Hadoop 2.6.0
-   Spark 1.6.0
-   JDK 1.5

Most of them are a little bit old, i agree, which brings some pb for me, see below

## How to build image
docker build -t <image name>:<version> .

## Lessons learnt
It takes much more time to build this image, lots of trivial problem, so i decided to write them down and anyone else who wants to install kylo manually might be interested.
-   Although both MySQL and PostgreSQL are supported according to kylo setup wizard, but actually only MySQL works because only Mysql based data source is activated in application.properties.
-   MySQL 5.7.7+ is required since some of index created by kylo has quite long name (>1000), although mysql 5.5 starts to support long index name (check the global parameter "innodb_large_prefix") but it is a tricky parameter to set. MySQL 5.7.7 starts to support long index name offically.
-   JDK 1.7+ required. Although JDK 8.0 is part of Kylo setup wizard steps, but it comes after elasticsearch installation which required JDK 1.7, so in the end i installed JDK 8.0 before start kylo setup wizard and skip JDK installation in kylo
-   Elasticsearch requires to change one kernel parameter "vm.max_map_count", see https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html. Set this parameter requires privileged container (https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities, why sysctl requires privileged container: https://github.com/moby/moby/issues/5703), but it is not possible to build container in privileged mode, so in the end i have to run kylo setup wizard when run container, since this step really take lots of time (mostly affected by network bandwidth), so the start up of container is kind of slow. I need to find out some solution. 


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
docker run -it -p 8400:8400 -v <local directory to be mapped>:/var/dropzone kylo:0.5
```
3.after container started, start hive2: 
```
/usr/local/hive/bin/hiveserver2 >>/var/log/hive 2>&1 &
/opt/kylo/start-kylo-apps.sh
```
4.after few mins, access http://localhost:8400 from host browser and login with dladmin/thinkbig
5.After login, import template first, then create a catalogy, then start to import feed