#### App Server  
Designed to be run as a base image for a tomcat web application. You would design it in a way to inject your WAR    
    
You must have the below in your entrypoint
````
service apache2 start && $CATALINA_HOME/bin/catalina.sh run
````
    
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
  
