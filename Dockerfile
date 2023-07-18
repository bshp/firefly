FROM ubuntu:latest
    
MAINTAINER jason.everling@gmail.com
    
ARG TOMCAT_VERSION
ARG TZ=America/North_Dakota/Center
    
ENV JAVA_HOME=/opt/java
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$PATH:$CATALINA_HOME/bin:$JAVA_HOME/bin
ENV TOMCAT_VERSION=$TOMCAT_VERSION
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
    
# Initial Setup for httpd, tomcat, and java
RUN set -eux; \
    installPkgs='apache2 ca-certificates libapache2-mod-jk wget jq'; \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone; \
    apt-get update; \
    apt-get install -y --no-install-recommends $installPkgs; \
    service apache2 stop && a2enmod rewrite ssl; \
    TOMCAT_LATEST=$(wget --quiet --no-cookies https://raw.githubusercontent.com/docker-library/tomcat/master/versions.json -O - \
            | jq -r --arg TOMCAT_VERSION "${TOMCAT_VERSION}" '. \
            | with_entries(select(.key | startswith($TOMCAT_VERSION))) \
            | .[].version'); \
    wget --quiet --no-cookies https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_VERSION}/v${TOMCAT_LATEST}/bin/apache-tomcat-${TOMCAT_LATEST}.tar.gz -O /opt/tomcat.tgz; \
    tar xzf /opt/tomcat.tgz -C /opt && mv /opt/apache-tomcat-${TOMCAT_LATEST} ${CATALINA_HOME}; \
    if [ ${TOMCAT_VERSION} -le 9 ];then \
        JAVA_VERSION=11; \
    else \
        JAVA_VERSION=17; \
    fi; \
    wget --quiet --no-cookies https://corretto.aws/downloads/latest/amazon-corretto-${JAVA_VERSION}-x64-linux-jdk.tar.gz -O /opt/java.tgz; \
    tar xzf /opt/java.tgz -C /opt && mv /opt/amazon-corretto-* ${JAVA_HOME}; \
    rm /opt/java.tgz && rm /opt/tomcat.tgz && rm -rf /opt/tomcat/webapps/*; \
    mkdir /var/log/tomcat && chmod -R 0755 /var/log/tomcat; \
    openssl req -newkey rsa:2048 -x509 -nodes -keyout /etc/ssl/server.key -new -out /etc/ssl/server.pem -subj /CN=localhost -sha256 -days 3650; \
    openssl dhparam -out /etc/ssl/dhparams.pem 2048; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    # Ensure apache2 can start
    apache2Test=$(apachectl configtest 2>&1); \
    apache2Starts=$(echo "$apache2Test" | grep 'Syntax OK'); \
    if [ -z "$apache2Starts" ];then \
        echo "Apache2 config test failed: $apache2Test"; \
        exit 1; \
    fi; \
    echo "Installed Tomcat Version: ${TOMCAT_LATEST} and OpenJDK Version: amazon-corretto-${JAVA_VERSION}-x64";

# Build Tomcat Native Library
RUN set -eux; \
    echo "Attempting to build Tomcat Native Library"; \
    saveAptManual="$(apt-mark showmanual)"; \
    buildDeps='dpkg-dev gcc libapr1-dev libssl-dev make'; \
    buildDir="$(mktemp -d)"; \
    tar -xf ${CATALINA_HOME}/bin/tomcat-native.tar.gz -C "$buildDir" --strip-components=1; \
    apt-get install -y --no-install-recommends $buildDeps; \
    ( \
        cd "$buildDir/native"; \
        osArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
        aprConfig="$(command -v apr-1-config)"; \
        ./configure --build="$osArch" --libdir="${TOMCAT_NATIVE_LIBDIR}" --prefix="${CATALINA_HOME}" --with-apr="${aprConfig}" --with-java-home="${JAVA_HOME}" --with-ssl; \
        nproc="$(nproc)"; \
        make -j "$nproc"; \
        make install; \
    ); \
    rm -rf "$buildDir"; \
    apt-mark auto '.*' > /dev/null; \
    [ -z "$saveAptManual" ] || apt-mark manual $saveAptManual > /dev/null; \
    find "$TOMCAT_NATIVE_LIBDIR" -type f -executable -exec ldd '{}' ';' \
        | awk '/=>/ { print $(NF-1) }' \
        | xargs -rt readlink -e \
        | sort -u \
        | xargs -rt dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | tee "$TOMCAT_NATIVE_LIBDIR/.dependencies.txt" \
        | xargs -r apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    tomcatTest="$(/opt/tomcat/bin/catalina.sh configtest  2>&1)"; \
    tomcatNative="$(echo "$tomcatTest" | grep 'Apache Tomcat Native')"; \
    tomcatNative="$(echo "$tomcatNative" | sort -u)"; \
    if ! echo "$tomcatNative" | grep -E 'INFO: Loaded( APR based)? Apache Tomcat Native library' >&2; then \
        echo >&2 "$tomcatTest"; \
        exit 1; \
    fi;
    
# Scripts and Configs
COPY ./src/ ./
    
EXPOSE 80 443
    
CMD ["/bin/bash"]
