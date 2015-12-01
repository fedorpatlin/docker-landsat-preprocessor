#!/bin/bash
cd $NEXTGIS_HOME/monitor
celery worker -A pyramid_celery.celery_app --ini development.ini
