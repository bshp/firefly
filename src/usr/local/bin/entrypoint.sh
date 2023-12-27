#!/bin/bash
    
## Initialization ##
/usr/local/bin/cert-updater;
/usr/local/bin/app-config;
/usr/local/bin/app-updater;
    
# Start Services:
apachectl -k start
su tomcat -c "$CATALINA_HOME/bin/catalina.sh run";
#$CATALINA_HOME/bin/catalina.sh run
