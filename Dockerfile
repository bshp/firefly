# bshp/apache2:version_tag, e.g 22.04 unquoted
ARG VERSION
    
# Tomcat/Java
ARG TOMCAT_VERSION
ARG JAVA_VERSION=0
    
# Optional: Change Timezone
ARG TZ=America/North_Dakota/Center
    
FROM bshp/apache2:${VERSION}
    
LABEL org.opencontainers.image.authors="jason.everling@gmail.com"
    
ARG TZ
ARG TOMCAT_VERSION
ARG JAVA_VERSION
    
ENV APP_TYPE="tomcat"
ENV ENABLE_CORS=0
ENV ENABLE_XFRAME=0
ENV OCIE_TYPES=${OCIE_TYPES}:/opt/ocie/type
ENV REWRITE_CORS=0
ENV REWRITE_DEFAULT=1
ENV REWRITE_SKIP=0
ENV JAVA_HOME=/opt/java
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$PATH:$CATALINA_HOME/bin:$JAVA_HOME/bin
ENV TOMCAT_VERSION=$TOMCAT_VERSION
ENV TOMCAT_NATIVE_LIBDIR=$CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
    
# Initial Setup for httpd, tomcat, and java
RUN set -eu; \
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
    # Ensure apache2 can start
    apache2Test=$(apachectl configtest 2>&1); \
    apache2Starts=$(echo "$apache2Test" | grep 'Syntax OK'); \
    if [ -z "$apache2Starts" ];then \
        echo "Apache2 config test failed: $apache2Test"; \
        exit 1; \
    fi; \
    if [ ${TOMCAT_VERSION} -lt 9 ];then \
        echo "Tomcat ${TOMCAT_LATEST} will reach end of life on 31 March 2024, bugs and security vulnerabilities will no longer be addressed"; \
        echo "Consider changing your tag to v9.11 or v10.17"; \
    fi; \
    echo "Installed Tomcat Version: ${TOMCAT_LATEST} and OpenJDK Version: amazon-corretto-${JAVA_VERSION}-x64";

# Build Tomcat Native Library
RUN set -eu; \
    echo "Attempting to build Tomcat Native Library"; \
    saveAptManual="$(apt-mark showmanual)"; \
    buildDeps='dpkg-dev gcc libapr1-dev libssl-dev make'; \
    buildDir="$(mktemp -d)"; \
    tar -xf ${CATALINA_HOME}/bin/tomcat-native.tar.gz -C "$buildDir" --strip-components=1; \
    apt-get update && apt-get install -y --no-install-recommends $buildDeps; \
    ( \
        cd "$buildDir/native"; \
        osArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
        aprConfig="$(command -v apr-1-config)"; \
        ./configure \
            --build="$osArch" \
            --libdir="${TOMCAT_NATIVE_LIBDIR}" \
            --prefix="${CATALINA_HOME}" \
            --with-apr="${aprConfig}" \
            --with-java-home="${JAVA_HOME}" \
            "$([ ${TOMCAT_VERSION} -le 9 ] && echo '--with-ssl' || echo '')"; \
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
COPY --chown=root:root --chmod=755 ./src/ ./
    
RUN set -eu; \
    useradd -m -u 1080 tomcat; \
    chown -R root:tomcat $CATALINA_HOME; \
    chmod -R 0775 $CATALINA_HOME;
    
EXPOSE 80 443
    
ENTRYPOINT ["/usr/local/bin/ociectl", "--run"]
