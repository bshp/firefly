#!/bin/bash
set -ex;
    
## Defaults ##
APP_NAME=${APP_NAME:-none};
APP_PARAMS=${APP_PARAMS:-};
APP_UPDATE=${APP_UPDATE:-none};
CA_URL=${CA_URL:-none};
VADC_IP_ADDRESS=${VADC_IP_ADDRESS:-0.0.0.0};
VADC_IP_HEADER=${VADC_IP_HEADER:-X-Forwarded-For};
    
## App Deploy ##
/usr/local/bin/updateApp.sh ${APP_NAME} ${APP_UPDATE}
    
## Certificates ##
/usr/local/bin/updateCerts.sh ${CA_URL}
    
## Initialization ##
VADC_IP_REG=$(echo "${VADC_IP_ADDRESS}" | sed -e 's/\s/\|/g')
TC_PROXIES=$(echo "${VADC_IP_REG}" | sed -e 's/\./\\./g')
TC_OPTS=$(echo 'export JAVA_OPTS="'$JAVA_OPTS $APP_PARAMS'"')
export VADC_IP_REG=${TC_PROXIES}
echo "export VADC_IP_ADDRESS=${VADC_IP_ADDRESS}" >> /etc/apache2/envvars
echo "export VADC_IP_HEADER=${VADC_IP_HEADER}" >> /etc/apache2/envvars
echo $TC_OPTS > /opt/tomcat/bin/setenv.sh && chmod -R 0755 /opt/tomcat/bin/setenv.sh
    
## Print Configs ##
echo "Remote IP: Apache2 module configured with address: ${VADC_IP_ADDRESS} and header: ${VADC_IP_HEADER}"
echo "Remote IP: Tomcat RemoteIpValve configured with remoteIpHeader: ${VADC_IP_HEADER} and internalProxies: ${VADC_IP_REG}"
echo "Tomcat: Configured JAVA_OPTS with ${TC_OPTS}"
echo "Initialization complete, attempting to start container as: [Apache: www-data, Tomcat: tomcat]"
    
# Start Services:
a2enmod remoteip && service apache2 restart
su -c "$CATALINA_HOME/bin/catalina.sh run" tomcat
