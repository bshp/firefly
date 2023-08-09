FROM bshp/apache2:latest
    
MAINTAINER jason.everling@gmail.com
    
ARG TOMCAT_VERSION
ARG JAVA_VERSION=0

ENV JAVA_HOME=/opt/java
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$PATH:$CATALINA_HOME/bin:$JAVA_HOME/bin
ENV TOMCAT_VERSION=$TOMCAT_VERSION
#ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
#ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
    
# Initial Setup for httpd, tomcat, and java
RUN set -eux; \
    installPkgs='libapache2-mod-jk'; \
    apt-get update; \
    apt-get install -y --no-install-recommends $installPkgs; \
    TOMCAT_LATEST=$(wget --quiet --no-cookies https://raw.githubusercontent.com/docker-library/tomcat/master/versions.json -O - \
            | jq -r --arg TOMCAT_VERSION "${TOMCAT_VERSION}" '. \
            | with_entries(select(.key | startswith($TOMCAT_VERSION))) \
            | .[].version'); \
    wget --quiet --no-cookies https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_VERSION}/v${TOMCAT_LATEST}/bin/apache-tomcat-${TOMCAT_LATEST}.tar.gz -O /opt/tomcat.tgz; \
    tar xzf /opt/tomcat.tgz -C /opt && mv /opt/apache-tomcat-${TOMCAT_LATEST} ${CATALINA_HOME}; \
    if [ ${TOMCAT_VERSION} -le 9 ];then \
        if [ ${JAVA_VERSION} -ne 0 ];then \
            JAVA_VERSION=${JAVA_VERSION}; \
        else \
            JAVA_VERSION=11; \
        fi \
    else \
        JAVA_VERSION=17; \
    fi; \
    wget --quiet --no-cookies https://corretto.aws/downloads/latest/amazon-corretto-${JAVA_VERSION}-x64-linux-jdk.tar.gz -O /opt/java.tgz; \
    tar xzf /opt/java.tgz -C /opt && mv /opt/amazon-corretto-* ${JAVA_HOME}; \
    rm /opt/java.tgz && rm /opt/tomcat.tgz && rm -rf /opt/tomcat/webapps/*; \
    mkdir /var/log/tomcat && chmod -R 0755 /var/log/tomcat; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    # Ensure apache2 can start
    apache2Test=$(apachectl configtest 2>&1); \
    apache2Starts=$(echo "$apache2Test" | grep 'Syntax OK'); \
    if [ -z "$apache2Starts" ];then \
        echo "Apache2 config test failed: $apache2Test"; \
        exit 1; \
    fi; \
    echo "Installed Tomcat Version: ${TOMCAT_LATEST} and OpenJDK Version: amazon-corretto-${JAVA_VERSION}-x64";
    
# Scripts and Configs
COPY ./src/ ./
    
EXPOSE 80 443
    
CMD ["/bin/bash"]
