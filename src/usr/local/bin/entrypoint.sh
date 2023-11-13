#!/bin/bash
set -ex;
    
## Defaults ##
APP_NAME=${APP_NAME:-none};
APP_DATA=${APP_DATA:-none};
APP_UPDATE=${APP_UPDATE:-none};
APP_PARAMS=${APP_PARAMS:-};
CA_URL=${CA_URL:-none};
VADC_IP_ADDRESS=${VADC_IP_ADDRESS:-0.0.0.0};
VADC_IP_HEADER=${VADC_IP_HEADER:-X-Forwarded-For};
    
## Required ##
if [ "${APP_NAME}" == "none" ] || [ "${APP_UPDATE}" == "none" ];then
    echo "Firefly: Environment APP_NAME and APP_UPDATE must be set, container will now exit";
    exit 1;
fi
    
## App Data ##
if [[ ! -d ${APP_DATA} ]]; then
    if [ "${APP_DATA}" == "none" ];then
        APP_DATA="/etc/${APP_NAME}";
    fi
    echo "Firefly: Data directory for application does not exist, creating ${APP_DATA}";
    install -d -m 0770 -o root -g tomcat ${APP_DATA};
fi
    
## App Deploy ##
/usr/local/bin/updateApp.sh ${APP_NAME} ${APP_UPDATE}
    
## Certificates ##
/usr/local/bin/updateCerts.sh ${CA_URL}
    
## Initialization ##
FIREFLY_IP_REGEX=$(echo "${VADC_IP_ADDRESS}" | sed -e 's/\s/\|/g')
FIREFLY_PROXIES=$(echo "${FIREFLY_IP_REGEX}" | sed -e 's/\./\\./g')
FIREFLY_OPTS=$(echo 'export JAVA_OPTS="'$JAVA_OPTS $APP_PARAMS'"')
export VADC_IP_REG=${FIREFLY_PROXIES}
echo "export VADC_IP_ADDRESS=${VADC_IP_ADDRESS}" >> /etc/apache2/envvars
echo "export VADC_IP_HEADER=${VADC_IP_HEADER}" >> /etc/apache2/envvars
echo $FIREFLY_OPTS > /opt/tomcat/bin/setenv.sh && chmod -R 0755 /opt/tomcat/bin/setenv.sh
    
## Print Configs ##
echo "Remote IP: Apache2 module configured with address: ${VADC_IP_ADDRESS} and header: ${VADC_IP_HEADER}"
echo "Remote IP: Tomcat RemoteIpValve configured with remoteIpHeader: ${VADC_IP_HEADER} and internalProxies: ${FIREFLY_PROXIES}"
echo "Tomcat: Configured JAVA_OPTS with ${FIREFLY_OPTS}"
echo "Firefly: Data directory for application is ${APP_DATA}";
echo "Initialization complete, attempting to start container as: [Apache: www-data, Tomcat: tomcat]"
    
# Start Services:
a2enmod remoteip && service apache2 restart
#su -c "$CATALINA_HOME/bin/catalina.sh run" tomcat
$CATALINA_HOME/bin/catalina.sh run
