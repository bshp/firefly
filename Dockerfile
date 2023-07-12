FROM ubuntu:latest

MAINTAINER jason.everling@gmail.com

ARG TOMCAT_VERSION
ARG GEN_KEYS=false
ARG TZ=America/North_Dakota/Center

ENV JAVA_HOME=/opt/java
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$PATH:$CATALINA_HOME/bin:$JAVA_HOME/bin
ENV TOMCAT_VERSION=$TOMCAT_VERSION
ENV GEN_KEYS=$GEN_KEYS
ENV VADC_IP_HEADER=X-VADC-Client
ENV VADC_IP_ADDRESS=10.0.0.0/8\ 172.16.0.0/12\ 192.168.0.0/16

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    apache2 \
    ca-certificates \
    libapache2-mod-jk \
    wget \
    jq && \
    service apache2 stop && \
    a2enmod remoteip rewrite ssl

# Setup Tomcat 9 + Java 11, Tomcat 10 + Java 17
RUN TOMCAT_MAJOR=${TOMCAT_VERSION%%.*} && wget --quiet --no-cookies https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -O /opt/tomcat.tgz && \
    tar xzf /opt/tomcat.tgz -C /opt && \
    mv /opt/apache-tomcat-${TOMCAT_VERSION} ${CATALINA_HOME} && \
    if [ ${TOMCAT_MAJOR} -eq 9 ];then JAVA_VERSION=11; else JAVA_VERSION=17; fi && \
    wget --quiet --no-cookies https://corretto.aws/downloads/latest/amazon-corretto-${JAVA_VERSION}-x64-linux-jdk.tar.gz -O /opt/java.tgz && \
    tar xzf /opt/java.tgz -C /opt && \
    mv /opt/amazon-corretto-* ${JAVA_HOME} && \
    rm /opt/java.tgz && \
    rm /opt/tomcat.tgz && \
    rm -rf /opt/tomcat/webapps/* && \
    mkdir /var/log/tomcat && chmod -R 0777 /var/log/tomcat && \
    echo "Installed Tomcat Version: ${TOMCAT_VERSION} and OpenJDK Version: amazon-corretto-${JAVA_VERSION}-x64"
    
# SSL Certificates
RUN openssl req -newkey rsa:2048 -x509 -nodes -keyout /etc/ssl/server.key -new -out /etc/ssl/server.pem -subj /CN=localhost -sha256 -days 3650 && \
    openssl dhparam -out /etc/ssl/dhparams.pem 2048
    
# Scripts and Configs
COPY etc/ /etc/
COPY opt/ /opt/

EXPOSE 80 443

WORKDIR /opt/tomcat

VOLUME ["/opt/tomcat/webapps", "/var/log/tomcat", "/var/log/apache2"]

ENTRYPOINT ["/opt/entrypoint.sh"]
