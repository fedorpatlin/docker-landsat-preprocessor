#!/bin/bash
PATH=$PATH:"$GRASS_HOME"
MONITOR_CONFIG="$NEXTGIS_HOME/monitor/development.ini"

function deploy_database {
  source $NEXTGIS_ENV/bin/activate
  initialize_monitor_db development.ini
}

function setup_program {
# Check missing parameter tmp.dir
if [ ! $(grep 'tmp.dir =' "$MONITOR_CONFIG") ]; then # tmp.dir is missing in default config. Need to apply patch.
  patch -p1 "$MONITOR_CONFIG" << EOPATCH
*************** result.dir = /var/local/monitor/result
*** 45,46 ****
--- 45,48 ----
  
+ tmp.dir = /var/local/monitor/tmp
+ 
  # By default, the toolbar only appears for clients from IP addresses
EOPATCH
fi 

#
# Database setup
  sed -i "s/dbuser = ndviuser/dbuser = $MONITOR_DB_USER/g" "$MONITOR_CONFIG"
  sed -i "s/dbpass = ndvi/dbpass = $MONITOR_DB_PASSWORD/g" "$MONITOR_CONFIG"
  sed -i "s/dbhost = localhost/dbhost = $MONITOR_DB_HOST/g" "$MONITOR_CONFIG"
  sed -i "s/dbname = ndvi/dbname = $MONITOR_DB_NAME/g" "$MONITOR_CONFIG"
#
# Earthexplorer login setup
  if [ ! -z "$MONITOR_EE_USER" ]; then
    sed -i "s|ee.login = ndviuser|ee.login = $MONITOR_EE_USER|g" "$MONITOR_CONFIG"
  else echo "WARNING! MONITOR_EE_USER not set. Using default value"
  fi
  if [ ! -z "$MONITOR_EE_PASSWORD" ]; then
    sed -i "s|ee.password = ndvipassword|ee.password = $MONITOR_EE_PASSWORD|g" "$MONITOR_CONFIG"
  else echo "WARNING! MONITOR_EE_PASSWORD not set. Using default value"
  fi
#
# GRASS GIS setup
  if [ ! -z "$GRASSGIS_HOME" ]; then
    sed -i "s|grass.gisbase = /usr/lib/grass70|grass.gisbase = $GRASSGIS_HOME|g" "$MONITOR_CONFIG"
  else echo "GRASSGIS_HOME not set. Using defalt value"
  fi
#
# Filesystem setup
  if [ ! -z "$MONITOR_FS_GRASSDATA" ]; then
    sed -i "s|grass.data = /var/local/monitor/GRASSDATA|grass.data = $MONITOR_FS_GRASSDATA|g" "$MONITOR_CONFIG"
    mkdir -p "$MONITOR_FS_GRASSDATA"
    chown -R "$NEXTGIS_USER": "$MONITOR_FS_GRASSDATA"
  else echo "MONITOR_FS_GRASSDATA not set. Using default value"
  fi
  if [ ! -z "$MONITOR_FS_POOL" ]; then
    sed -i "s|pool.dir = /var/local/monitor/pool|pool.dir = $MONITOR_FS_POOL|g" "$MONITOR_CONFIG";
    mkdir -p "$MONITOR_FS_POOL"
    chown -R "$NEXTGIS_USER": "$MONITOR_FS_POOL"
  else echo "MONITOR_FS_POOL not set. Using default value"
  fi
  if [ ! -z "$MONITOR_FS_RESULT" ]; then
    sed -i "s|result.dir = /var/local/monitor/result|result.dir = $MONITOR_FS_RESULT|" "$MONITOR_CONFIG"
    mkdir -p "$MONITOR_FS_RESULT"
    chown -R "$NEXTGIS_USER": "$MONITOR_FS_RESULT"
  else echo "MONITOR_FS_RESULT not set. Using default value"
  fi
  if [ ! -z "$MONITOR_FS_TMP" ]; then
    sed -i "s|tmp.dir = .*|tmp.dir = $MONITOR_FS_TMP|g" "$MONITOR_CONFIG"
    mkdir -p "$MONITOR_FS_TMP"
    chown -R "$NEXTGIS_USER": "$MONITOR_FS_TMP"
  else echo "WARNING! MONITOR_FS_TMP not set. Using default value"
  fi
}

if [ "$1" = "monitor" ]; then
  setup_program;
  supervisord;
elif [ "$1" = "deploy_db" ]; then
  setup_program;
  deploy_database;
elif [ "$1" = "help" ]; then
  echo "Available commands are: monitor, deploy_db.";
else
  exec "$@"
fi
exit 0
