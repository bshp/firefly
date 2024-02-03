## Application Server  
Designed for a tomcat web application
    
Using AJP (mod_jk) for performance reasons, no listeners for http, only AJP on 127.0.0.1 for apache2 access. Both apache2 and tomcat have a subset of standard security practices applied. You can view the configs in the /etc/apache2 of the base image below and /opt/tomcat of this repo.
    
#### Base OS:    
Ubuntu Server LTS - Latest
    
#### Packages:    
Updated weekly from the official upstream Ubuntu LTS, see [Apache2 Base](https://github.com/bshp/apache2) for packages added.
    
Corretto (JDK) and Tomcat are also updated weekly using the latest version of the branch, e.g tomcat 10.x and corretto 17.x
````
corretto - https://corretto.aws/downloads/latest
tomcat - https://dlcdn.apache.org/tomcat
````
## Environment Variables:
    
see [Ocie Environment](https://github.com/bshp/ocie/blob/main/Environment.md) for more info
    
#### Direct:  
````
docker run \
    -e APP_PARAMS=-Xmx2048m \
    -e CA_ENABLED=1 \
    -e CA_UPDATE_AUTO=1 \
    -e CA_PATH=url:https://cert.example.com/ \
    -e CA_FILTER="*_CA.crt" \
    -e CERT_ENABLED=1 \
    -e CERT_SUBJECT="localhost" \
    -e APP_DEPLOY=1 \
    -e APP_NAME=myapp \
    -e APP_DATA=/etc/myapp \
    -e APP_UPDATE=1 \
    -e APP_UPDATE_PATH=/opt/updates \
    -e REWRITE_ENABLED=1 \
    -e REWRITE_CORS=0 \
    -e REWRITE_DEFAULT=1 \
    -e VADC_IP_ADDRESS=192.168.100.10 \
    -e VADC_IP_HEADER=X-VADC-Client \
    -d bshp/firefly:v10.17
````
#### Custom:  
Add at end of your entrypoint script either of:  
````
/usr/sbin/ociectl --run;
````
````
/usr/sbin/apachectl -k start;
su tomcat -c "${CATALINA_HOME}/bin/catalina.sh run";
````
    
## Tags:
    
latest = v10.21    
v9.11 = Tomcat 9 with Corretto JDK 11    
v10.17 = Tomcat 10 with Corretto JDK 17    
v10.21 = Tomcat 10 with Corretto JDK 21    
    
## Build:  
````
docker build . --build-arg VERSION=22.04 --build-arg TOMCAT_VERSION=10 --tag YOUR_TAG
````
    
