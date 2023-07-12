#### App Server  
Apps: ``/opt/tomcat/webapps/``  
SSL: ``/etc/ssl/``  
    
  Build:  
````
docker build . --build-arg TOMCAT_VERSION=TOMCAT_VERSION --tag bshp/firefly:latest
````
  Run:  
````
docker run -p 9443:443 \
    -v /var/log/apache2:/var/log/apache2 \
    -v /var/log/tomcat:/var/log/tomcat \
    -v /opt/webapps:/opt/tomcat/webapps \
    -e VADC_IP_ADDRESS="LOAD_BALANCE_IP_SET" \
    -d --name firefly bshp/firefly:latest -m 2g
````
    
  Maint:
````
docker rm -f firefly  
docker rmi bshp/firefly:latest  
````
    
##### Notes  
  
