#### App Server  
Designed to be run as a base image for a tomcat web application.  You would design it in a way to inject your WAR      
    
Using AJP (mod_jk) for performance reasons, no listeners for http, only AJP on 127.0.0.1 for apache2 access. Both apache2 and tomcat have a subset of standard security practices applied. You can view the configs in the /etc/apache2 and /opt/tomcat of the repo.
    
Base OS: Ubuntu Server LTS - Latest    
Tomcat/JDK: Latest versions for Tomcat and Corretto    
    
Environment Variables:    
    
Required:    
````
APP_NAME = name of the app, e.g myapp.war would be myapp
UPDATE_PATH = Path to where the app war is located, without the trailing slash, e.g /opt/updates
````
    
Optional:    
````
APP_DATA = the path of where the application can store data, e.g /opt/myapp, default: /etc/${APP_NAME}
APP_PARAMS = additional params to append to JAVA_OPTS, e.g -Dmyapp.setting=something
CA_URL = URL or PATH to where CA Certificates can be found, they must have the .crt extension, if valid, will be imported into the OS and Java stores
VADC_IP_ADDRESS = address of load balancer, space seperated, e.g 192.168.100.105 192.168.0.105, default: any
VADC_IP_HEADER = client ip header name, e.g X-Client-IP , default: X-Forwarded-For
````
Tags:
    
latest = v9.11    
v9.11 = Tomcat 9 with Corretto JDK 11    
v10.17 = Tomcat 10 with Corretto JDK 17    
    
Build:  
````
docker build . --build-arg TOMCAT_VERSION=10 --tag YOUR_TAG
````
    
