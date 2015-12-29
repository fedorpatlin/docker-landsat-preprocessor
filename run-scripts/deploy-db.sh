#!/bin/bash
mydir="$(dirname $(readlink -f $0))"
. $mydir/config

docker run -it --rm\
  -e MONITOR_EE_USER=$MONITOR_EE_USER\
  -e MONITOR_EE_PASSWORD=$MONITOR_EE_PASSWORD\
  -e MONITOR_DB_USER=$MONITOR_DB_USER\
  -e MONITOR_DB_PASSWORD=$MONITOR_DB_PASSWORD\
  -e MONITOR_DB_HOST=$MONITOR_DB_HOST\
  -e MONITOR_DB_NAME=$MONITOR_DB_NAME\
  -e GRASSGIS_HOME=$GRASSGIS_HOME\
  -e MONITOR_FS_GRASSDATA=$MONITOR_FS_GRASSDATA\
  -e MONITOR_FS_POOL=$MONITOR_FS_POOL\
  -e MONITOR_FS_RESULT=$MONITOR_FS_RESULT\
  -e MONITOR_FS_TMP=$MONITOR_FS_TMP\
  -p 6543:6543\
  -v /monitor:/var/lib/monitor\
  -v /tmp/monitor:/tmp\
  --name nextgis-monitor\
  docker.ltmn.sovzond.center:5000/nextgis-centos7:current deploy_db

