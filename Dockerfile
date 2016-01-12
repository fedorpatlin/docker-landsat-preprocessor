FROM centos:7
MAINTAINER patlin.f@sovzond.center

ENV GRASS_HOME=/opt/grassgis\
    GRASS_URL=https://grass.osgeo.org/grass70/binary/linux/snapshot/grass-7.0.3svn-x86_64-unknown-linux-gnu-29_12_2015.tar.gz\
    GRASSINST_URL=https://grass.osgeo.org/grass70/binary/linux/snapshot/grass-7.0.3svn-x86_64-unknown-linux-gnu-29_12_2015-install.sh\
    GRASS_ARCHIVE=/grass-7.0.3svn-x86_64-unknown-linux-gnu-13_12_2015.tar.gz\
    GRASSINST=/grass-install.sh

RUN  yum install -y epel-release\
  && yum install -y proj\
                    freetype\
  && yum clean all && echo "" > /var/log/yum*

RUN curl $GRASS_URL > $GRASS_ARCHIVE\
  && curl $GRASSINST_URL > $GRASSINST && chmod +x $GRASSINST\
  && rm -rf $GRASS_HOME\
  && $GRASSINST $GRASS_ARCHIVE $GRASS_HOME $GRASS_HOME\
  && rm -f $GRASS_ARCHIVE\
  && rm -f $GRASSINST

RUN yum install -y unzip\
    curl\
    wget\
    python-pip\
    python-virtualenv\
    geos\
    geos-python\
    gcc\
    geos-devel\
    postgresql-libs\
    postgresql\
    postgresql-devel\
    rabbitmq-server\
    supervisor\
    gdal\
    patch\
  && yum clean all && echo "" > /var/log/yum.log
  
ENV NEXTGIS_HOME=/opt/landsat_preprocess-master\
    NEXTGIS_USER=nextgis\
    CELERY_USER=celery

COPY landsat_preprocess-master $NEXTGIS_HOME

WORKDIR $NEXTGIS_HOME/monitor

COPY gosu /bin/
ENV NEXTGIS_ENV=ng-env
RUN adduser $CELERY_USER\
  && touch /bin/celery-start.sh && touch /bin/monitor-start.sh\
  && adduser $NEXTGIS_USER\
  && chmod +x /bin/gosu /bin/celery-start.sh /bin/monitor-start.sh\
  && chown -R nextgis: $NEXTGIS_HOME

RUN virtualenv $NEXTGIS_ENV\
  && source $NEXTGIS_ENV/bin/activate\
  && pip install pyramid\
#  && pip install waitress\
  && $VIRTUAL_ENV/bin/python setup.py develop



RUN chmod +x /bin/gosu\
  && chown -R nextgis: $NEXTGIS_HOME

EXPOSE 6543

COPY docker-entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh
ENTRYPOINT [ "/bin/entrypoint.sh" ]

CMD [ "monitor" ]

################################################
# Create configuration files and shell-scripts #
################################################

RUN echo -e '#!/bin/bash \n\
cd $NEXTGIS_HOME/monitor \n\
source $NEXTGIS_ENV/bin/activate \n\
#celery worker -A pyramid_celery.celery_app --ini development.ini \n'\
celery worker -A pyramid_celery.celery_app --ini development.ini -B \n'\
> /bin/celery-start.sh\
\
 && echo -e '#!/bin/bash \n\
cd $NEXTGIS_HOME/monitor \n\
source $NEXTGIS_ENV/bin/activate \n\
pserve development.ini \n'\
> /bin/monitor-start.sh\
\
 && echo -e '[supervisord] \n\
pidfile = /tmp/supervisord.pid \n\
nodaemon = true \n\
minfds = 1024 \n\
minprocs = 200 \n\
umask = 022 \n\
identifier = supervisor \n\
directory = /tmp \n\
nocleanup = true \n\
strip_ansi = false \n\
stderr_logfile=/dev/stderr \n\
stderr_logfile_maxbytes=0 \n\
stdout_logfile=/dev/fd/1 \n\
stdout_logfile_maxbytes=0 \n\
 \n\
[program: rabbitmq] \n\
command=gosu rabbitmq rabbitmq-server \n\
priority=999 \n\
autostart=true \n\
autorestart=unexpected \n\
startsecs=10 \n\
startretries=3 \n\
exitcodes=0,2 \n\
stopsignal=TERM \n\
stopwaitsecs=10 \n\
stopasgroup=false \n\
killasgroup=false \n\
redirect_stderr=true \n\
stderr_logfile=/dev/stderr \n\
stderr_logfile_maxbytes=0 \n\
stdout_logfile=/dev/fd/1 \n\
stdout_logfile_maxbytes=0 \n\
 \n\
[program: celery] \n\
command=gosu nextgis /bin/celery-start.sh \n\
priority=999 \n\
autostart=true \n\
autorestart=unexpected \n\
startsecs=10 \n\
startretries=3 \n\
exitcodes=0,2 \n\
stopsignal=TERM \n\
stopwaitsecs=10 \n\
stopasgroup=false \n\
killasgroup=false \n\
redirect_stderr=true \n\
stderr_logfile=/dev/stderr \n\
stderr_logfile_maxbytes=0 \n\
stdout_logfile=/dev/fd/1 \n\
stdout_logfile_maxbytes=0 \n\
 \n\
[program:monitor] \n\
command=gosu nextgis /bin/monitor-start.sh \n\
priority=999 \n\
autostart=true \n\
autorestart=unexpected \n\
startsecs=10 \n\
startretries=3 \n\
exitcodes=0,2 \n\
stopsignal=TERM \n\
stopwaitsecs=10 \n\
stopasgroup=false \n\
killasgroup=false \n\
redirect_stderr=true \n\
stdout_logfile=/dev/fd/1 \n\
stdout_logfile_maxbytes=0 \n\
stderr_logfile=/dev/stderr \n\
stderr_logfile_maxbytes=0 \n'\
 > /etc/supervisord.conf

RUN echo -e '*** landsat_preprocess-master/monitor/development.ini   2015-12-26 00:20:26.000000000 +0500\n\
--- development.changed 2016-01-12 12:49:56.621547455 +0500\n\
*************** task = monitor.processing.processing.pro\n\
*** 65,67 ****\n\
  type = crontab\n\
! schedule = {"minute": "0", "hour": "0", "day_of_week": "*/7"}\n\
\n\
--- 65,67 ----\n\
  type = crontab\n\
! schedule = {"minute": "0", "hour": "*/1"}\n\
\n\
*************** task = monitor.processing.processing.che\n\
*** 70,72 ****\n\
  type = crontab\n\
! schedule = {"minute": "0", "hour": "0", "day_of_week": "*/7"}\n\
\n\
--- 70,72 ----\n\
  type = crontab\n\
! schedule = {"minute": "0", "hour": "*/1"}\n\
'| patch -p1 development.ini
