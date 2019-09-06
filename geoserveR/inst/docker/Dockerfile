FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

ENV GEOSERVER_VERSION 2.15.2

RUN apt-get update && \
  apt-get install -y \
    ca-certificates openssl wget openjdk-8-jre openssh-server openssh-client unzip && \
  apt-get clean && \
  update-ca-certificates && \
  cd /usr/local && \
  wget http://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/geoserver-${GEOSERVER_VERSION}-bin.zip && \
  unzip geoserver-${GEOSERVER_VERSION}-bin.zip && \
  mv geoserver-${GEOSERVER_VERSION} geoserver && \
  rm geoserver-${GEOSERVER_VERSION}-bin.zip

ENV GEOSERVER_HOME /usr/local/geoserver

ENV GEOSERVER_DATA_DIR ${GEOSERVER_HOME}/data_dir

EXPOSE 8080

CMD ["sh", "/usr/local/geoserver/bin/startup.sh"]
