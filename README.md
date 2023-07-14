#### App Server  
Designed to be run as a base image for a tomcat web application.  You would design it in a way to inject your WAR      
    
Using AJP (mod_jk) for performance reasons, no listeners for http, only AJP on 127.0.0.1 for apache2 access. Both apache2 and tomcat have a subset of standard security practices applied. You can view the configs in the /etc/apache2 and /opt/tomcat of the repo.
    
Base OS: Ubuntu Server LTS - Latest    
Tomcat/JDK: Latest versions for Tomcat and Corretto    
    
You must have the below in your entrypoint
````
service apache2 start && $CATALINA_HOME/bin/catalina.sh run
````
Tags:
    
v9.11 = Tomcat 9 with Corretto JDK 11    
v10.17 = Tomcat 10 with Corretto JDK 17    
    
Build:  
````
docker build . --build-arg TOMCAT_VERSION=10.1.11 --tag YOUR_TAG
````
Run:  
````
docker run -p 9443:443 \
    -v /var/log/apache2:/var/log/apache2 \
    -v /var/log/tomcat:/var/log/tomcat \
    -d --name firefly YOUR_TAG/NAME -m 2g
````
    
##### Notes  