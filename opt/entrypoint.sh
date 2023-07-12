#!/bin/bash
set -e

if [ ${GEN_KEYS} = true ];then
    openssl req -newkey rsa:2048 -x509 -nodes -keyout /etc/ssl/server.key -new -out /etc/ssl/server.pem \
            -subj /CN=localhost -sha256 -days 3650 && \
            openssl dhparam -out /etc/ssl/dhparams.pem 2048
fi
    
# Set config variables for httpd and tomcat
echo "export JAVA_OPTS="\""\$JAVA_OPTS -Dvadc_ip_regex=$(echo "${VADC_IP_ADDRESS}" | sed -e 's/\s/\|/g') -Dvadc_ip_hdr=${VADC_IP_HEADER}\"" > /opt/tomcat/bin/setenv.sh && chmod -R 0755 /opt/tomcat/bin/setenv.sh
echo "RemoteIPInternalProxy "${VADC_IP_ADDRESS} >> /etc/apache2/mods-enabled/remoteip.conf
echo "RemoteIPHeader "${VADC_IP_HEADER} >> /etc/apache2/mods-enabled/remoteip.conf
    
# Start Services
service apache2 start && $CATALINA_HOME/bin/catalina.sh run
