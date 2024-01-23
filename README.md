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
    
see [Base Image](https://github.com/bshp/apache2/blob/master/Dockerfile) for more variables
    
#### Required:    
````
APP_NAME = name of the app, e.g myapp.war would be myapp
APP_UPDATE_PATH = Path to where the app war is located, without the trailing slash, e.g /opt/updates
````
    
#### Optional:    
````
APP_DATA = the path of where the application can store data, e.g /opt/myapp, default: /etc/${APP_NAME}
APP_PARAMS = additional params to append to JAVA_OPTS, e.g -Dmyapp.setting=something
CA_FILTER = the filter for certificate import, e.g "*_CA.crt"
CA_PATH = URL or PATH to where CA Certificates can be found, prefixed with file: or url: , e.g url:https://www.example.com/ or file:/opt/certs
CA_AUTO_UPDATE = 1 (Import CERT_PATH certs into the OS and Java stores)
CERT_UPDATE_KEYS = 0 to not update, 1 to force update
CERT_SUBJECT = the subject for the server ssl keys, e.g "localhost"
VADC_IP_ADDRESS = address of load balancer, space seperated, e.g 192.168.100.105 192.168.0.105, default: any
VADC_IP_HEADER = client ip header name, e.g X-Client-IP , default: X-Forwarded-For
````
    
#### Note:    
Some need to be set for certain functions when used direct with app-run, see [Base Scripts](https://github.com/bshp/apache2/tree/master/src/usr/local/bin) for more info    
#### Direct:  
````
docker run \
    -e APP_PARAMS=-Xmx2048m \
    -e CA_AUTO_UPDATE=1 \
    -e CA_PATH=url:https://cert.example.com/ \
    -e CA_FILTER="*_CA.crt" \
    -e CERT_SUBJECT="localhost" \
    -e APP_NAME=myapp \
    -e APP_DATA=/etc/myapp \
    -e APP_UPDATE_PATH=/opt/updates \
    -e APP_UPDATE_AUTO=1 \
    -e REWRITE_CORS=0 \
    -e REWRITE_DEFAULT=1 \
    -e REWRITE_SKIP=0 \
    -e VADC_IP_ADDRESS=192.168.100.10 \
    -e VADC_IP_HEADER=X-VADC-Client \
    -d bshp/firefly:v10.17
````
#### Custom:  
Add at end of your entrypoint script either of:  
````
/usr/local/bin/ociectl --run;
````
````
/usr/sbin/apachectl -k start;
su tomcat -c "${CATALINA_HOME}/bin/catalina.sh run";
````
    
## Tags:
    
latest = v9.11    
v9.11 = Tomcat 9 with Corretto JDK 11    
v10.17 = Tomcat 10 with Corretto JDK 17    
    
## Build:  
````
docker build . --build-arg VERSION=22.04 --build-arg TOMCAT_VERSION=10 --tag YOUR_TAG
````
    
