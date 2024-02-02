# bshp/ocie:version_tag, e.g 22.04 unquoted
ARG OCIE_VERSION
    
# Tomcat/Java
ARG TOMCAT_VERSION
ARG JAVA_VERSION=0
    
# Optional: Change Timezone
ARG TZ=America/North_Dakota/Center
    
FROM bshp/apache2:${OCIE_VERSION}
    
LABEL org.opencontainers.image.authors="jason.everling@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/bshp/firefly"
LABEL org.opencontainers.image.title="Firefly"
    
ARG TZ
ARG TOMCAT_VERSION
ARG JAVA_VERSION
    
ENV OCIE_CONFIG=/opt \
    JAVA_HOME=/opt/java \
    CATALINA_HOME=/opt/tomcat \
    PATH=$PATH:$CATALINA_HOME/bin:$JAVA_HOME/bin \
    TOMCAT_VERSION=$TOMCAT_VERSION \
    TOMCAT_NATIVE_LIBDIR=$CATALINA_HOME/native-jni-lib \
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR \
    APP_DEPLOY=1 \
    APP_TYPE="tomcat" \
    APP_GROUP="tomcat" \
    APP_OWNER="root" \
    APP_HOME=$CATALINA_HOME/webapps \
    APP_DATA=/etc \
    CA_ENABLED=1 \
    CA_UPDATE_AUTO=1 \
    ENABLE_CORS=0 \
    ENABLE_XFRAME=0 \
    REWRITE_ENABLED=1 \
    REWRITE_CORS=0 \
    REWRITE_DEFAULT=1
    
# Initial Setup for httpd, tomcat, and java
RUN <<"EOD" bash
    set -eu;
    useradd -m -u 1080 tomcat;
    TOMCAT_LATEST=$(wget --quiet --no-cookies https://raw.githubusercontent.com/docker-library/tomcat/master/versions.json -O - \
        | jq -r --arg TOMCAT_VERSION "${TOMCAT_VERSION}" '. | with_entries(select(.key | startswith($TOMCAT_VERSION))) | .[].version');
    echo "Getting Tomcat Distribution, Version: ${TOMCAT_LATEST}";
    wget --quiet --no-cookies https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_VERSION}/v${TOMCAT_LATEST}/bin/apache-tomcat-${TOMCAT_LATEST}.tar.gz -O /opt/tomcat.tgz;
    tar xzf /opt/tomcat.tgz -C /opt && mv /opt/apache-tomcat-${TOMCAT_LATEST} ${CATALINA_HOME};
    if [[ ${JAVA_VERSION} -eq 0 ]];then
        echo "OpenJDK build-arg was omitted";
        if [[ ${TOMCAT_VERSION} -le 9 ]];then
            JAVA_VERSION=11;
        else
            JAVA_VERSION=17;
        fi;
    fi;
    echo "Getting OpenJDK Distribution, Version: ${JAVA_VERSION}.x";
    wget --quiet --no-cookies https://corretto.aws/downloads/latest/amazon-corretto-${JAVA_VERSION}-x64-linux-jdk.tar.gz -O /opt/java.tgz;
    tar xzf /opt/java.tgz -C /opt && mv /opt/amazon-corretto-* ${JAVA_HOME};
    rm /opt/java.tgz && rm /opt/tomcat.tgz && rm -rf /opt/tomcat/webapps/*;
    # Tomcat EOL Notice
    if [ ${TOMCAT_VERSION} -lt 9 ];then
        echo "Tomcat ${TOMCAT_LATEST} will reach end of life on 31 March 2024, bugs and security vulnerabilities will no longer be addressed";
        echo "Consider changing your tag to v9.11 or v10.17";
    fi;
    # Adjust permissions
    chown -R ${APP_OWNER}:${APP_GROUP} $CATALINA_HOME;
    chmod -R 0775 $CATALINA_HOME;
    echo "Installed Tomcat Version: ${TOMCAT_LATEST} and OpenJDK Version: amazon-corretto-${JAVA_VERSION}-x64";
EOD
    
# Build Tomcat Native Library
RUN <<"EOD" bash
    set -eu;
    echo "Attempting to build Tomcat Native Library";
    saveAptManual="$(apt-mark showmanual)";
    buildDeps='dpkg-dev gcc libapr1-dev libssl-dev make';
    buildDir="$(mktemp -d)";
    tar -xf ${CATALINA_HOME}/bin/tomcat-native.tar.gz -C "$buildDir" --strip-components=1;
    echo "Gathering build dependencies";
    apt-get -qq update >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends $buildDeps >/dev/null 2>&1;
    (
        cd "$buildDir/native";
        osArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)";
        aprConfig="$(command -v apr-1-config)";
        ./configure --build="$osArch" --libdir="${TOMCAT_NATIVE_LIBDIR}" --prefix="${CATALINA_HOME}" --with-apr="${aprConfig}" \
            --with-java-home="${JAVA_HOME}" "$([ ${TOMCAT_VERSION} -le 9 ] && echo '--with-ssl' || echo '')";
        nproc="$(nproc)";
        make -j "$nproc";
        make install;
    ) >/dev/null 2>&1;
    rm -rf "$buildDir";
    echo "Finished building Tomcat Native Library";
    echo "Removing build dependencies";
    apt-mark auto '.*' >/dev/null 2>&1;
    [[ -z "$saveAptManual" ]] || apt-mark manual $saveAptManual >/dev/null;
    (
        find "$TOMCAT_NATIVE_LIBDIR" -type f -executable -exec ldd '{}' ';' \
        | awk '/=>/ { print $(NF-1) }' | xargs -rt readlink -e | sort -u | xargs -rt dpkg-query --search \
        | cut -d: -f1 | sort -u | tee "$TOMCAT_NATIVE_LIBDIR/.dependencies.txt" | xargs -r apt-mark manual
    ) >/dev/null 2>&1;
    apt-get -qq purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false >/dev/null 2>&1;
    rm -rf /var/lib/apt/lists/*;
    echo "Finished building Tomcat Native Library";
EOD
    
# Ensure Tomcat Starts
RUN <<"EOD" bash
    set -eu;
    echo "Validating Tomcat configuration";
    CFG_TEST="$(echo "$(/opt/tomcat/bin/catalina.sh configtest  2>&1)" | grep 'Apache Tomcat Native' | sort -u)";
    CFG_RESULT=$(echo "$CFG_TEST" | grep -E "INFO: Loaded( APR based)? Apache Tomcat Native library");
    if [[ -z "$CFG_RESULT" ]];then
        echo "Validation: FAILED";
        echo "$CFG_RESULT";
        exit 1;
    else
        echo "Validation: SUCCESS";
    fi;
EOD
    
# Tomcat Config
COPY --chown=root:root --chmod=755 ./src/ ./
    
EXPOSE 80 443
    
ENTRYPOINT ["/bin/bash"]
