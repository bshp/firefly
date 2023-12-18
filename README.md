## Application Server  
Designed for a tomcat web application
    
Using AJP (mod_jk) for performance reasons, no listeners for http, only AJP on 127.0.0.1 for apache2 access. Both apache2 and tomcat have a subset of standard security practices applied. You can view the configs in the /etc/apache2 and /opt/tomcat of the repo.
    
Base OS: Ubuntu Server LTS - Latest    
Tomcat/JDK: Latest versions for Tomcat and Corretto    
    
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
CERT_SUBJECT = the subject for the server ssl keys, e.g "localhost"
CERT_FILTER = the filter for certificate import, e.g "*_CA.crt"
CERT_UPDATE_KEYS = 0 to not update, 1 to force update
CERT_PATH = URL or PATH to where CA Certificates can be found
CERT_AUTO_UPDATE = 1 (Import CERT_PATH certs into the OS and Java stores)
VADC_IP_ADDRESS = address of load balancer, space seperated, e.g 192.168.100.105 192.168.0.105, default: any
VADC_IP_HEADER = client ip header name, e.g X-Client-IP , default: X-Forwarded-For
````
    
#### Note:    
Some variables do not need to be set, the app-config and app-updater will change runas and directory permissions based on application type, see [Base Scripts](https://github.com/bshp/apache2/tree/master/src/usr/local/bin) for more info
    
## Tags:
    
latest = v9.11    
v9.11 = Tomcat 9 with Corretto JDK 11    
v10.17 = Tomcat 10 with Corretto JDK 17    
    
## Build:  
````
docker build . --build-arg TOMCAT_VERSION=10 --tag YOUR_TAG
````
    
