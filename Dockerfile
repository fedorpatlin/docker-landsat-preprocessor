FROM centos:7
MAINTAINER patlin.f@sovzond.center

ENV GRASS_HOME=/opt/grassgis

RUN curl https://grass.osgeo.org/grass70/binary/linux/snapshot/grass-7.0.3svn-x86_64-unknown-linux-gnu-30_11_2015.tar.gz > /grass-7.0.3svn-x86_64-unknown-linux-gnu-30_11_2015.tar.gz\
  && mkdir -p $GRASS_HOME\
  && cd $GRASS_HOME\
  && tar -zxvf /grass-7.0.3svn-x86_64-unknown-linux-gnu-30_11_2015.tar.gz\
  && rm -f /grass-7.0.3svn-x86_64-unknown-linux-gnu-30_11_2015.tar.gz

RUN yum install -y unzip\
    python-virtualenv\
    epel-release\
    curl\
    wget\
  && yum install -y python-pip\
    geos\
    geos-python\
    gcc\
    geos-devel\
    postgresql-libs\
    postgresql\
    postgresql-devel\
    rabbitmq-server\
    supervisor\
  && yum clean all && echo "" > /var/log/yum.log
  
ENV NEXTGIS_HOME=/opt/landsat_preprocess-master

COPY landsat_preprocess-master $NEXTGIS_HOME

COPY config.ini $NEXTGIS_HOME/monitor/development.ini

WORKDIR $NEXTGIS_HOME/monitor

COPY gosu celery-start.sh monitor-start.sh /bin/

RUN adduser celery\
  && adduser nextgis\
  && chmod +x /bin/gosu /bin/celery-start.sh /bin/monitor-start.sh\
  && chown -R nextgis: $NEXTGIS_HOME

RUN virtualenv env\
  && source env/bin/activate\
  && pip install pyramid\
  && pip install waitress\
  && $VENV/bin/python setup.py develop



RUN chmod +x /bin/gosu\
  && chown -R nextgis: $NEXTGIS_HOME

COPY supervisord.conf /etc/supervisord.conf

EXPOSE 6543

CMD [ "supervisord" ]
