#!/bin/bash
set -ex;
    
APP_NAME=$1
UPDATE_PATH=$2
APP_PATH="${UPDATE_PATH}/${APP_NAME}.war"
DEPLOY_PATH="${CATALINA_HOME}/webapps"

############
if [ -f "/opt/tomcat/webapps/${APP_NAME}.war" ];then
    APP_LOCAL=$(sha1sum "${DEPLOY_PATH}/${APP_NAME}.war" | awk '{print $1}')
    echo "Firefly: Application exists, sha1: $APP_LOCAL"
else 
    APP_LOCAL=""
    echo "Firefly: Application DOES NOT exist and will be deployed from: ${APP_PATH}"
fi
    
# Update CAS if needed, exit/do not start if not valid
if [ -f "${APP_PATH}" ]; then
    APP_LATEST=$(sha1sum ${APP_PATH} | awk '{print $1}')
    if [ "$APP_LOCAL" != "$APP_LATEST" ];then
        echo "Firefly: Update is needed, using update path: ${APP_PATH}"
        cp ${APP_PATH} ${DEPLOY_PATH}
    else
        echo "Firefly: Update not needed"
    fi
else 
    echo "Firefly: Application not found at ${APP_PATH}";
fi
