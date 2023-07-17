#### App Server  
Designed to be run as a base image for a tomcat web application.  You would design it in a way to inject your WAR      
    
Using AJP (mod_jk) for performance reasons, no listeners for http, only AJP on 127.0.0.1 for apache2 access. Both apache2 and tomcat have a subset of standard security practices applied. You can view the configs in the /etc/apache2 and /opt/tomcat of the repo.
    
Base OS: Ubuntu Server LTS - Latest    
Tomcat/JDK: Latest versions for Tomcat and Corretto    
    
You must have the below in your entrypoint
````
service apache2 restart && $CATALINA_HOME/bin/catalina.sh run
````
Tags:
    
v9.11 = Tomcat 9 with Corretto JDK 11    
v10.17 = Tomcat 10 with Corretto JDK 17    
    
Build:  
````
docker build . --build-arg TOMCAT_VERSION=10 --tag YOUR_TAG
````
    
##### Notes  
SSL Certs:  
    
Modify your entrypoint to add or generate new keys  
    
CA Certs Update:  
    
Within your entrypoint script you could do something like the below to inject your ca certs,
````
echo "CA Certificates: Checking for CA Import"
if [[ ! -z "${CA_URL}" ]];then
    echo "CA Certificates: The following URL will be searched ${CA_URL}"
    cd /usr/local/share/ca-certificates
    wget -r -nH -A *_CA.crt ${CA_URL}
    for CA_CRT in /usr/local/share/ca-certificates/*.crt; do
        CA_NAME=$(openssl x509 -noout -subject -nameopt multiline -in $CA_CRT | sed -n 's/ *commonName *= //p')
        ${JAVA_HOME}/bin/keytool -import -trustcacerts -cacerts -storepass changeit -noprompt -alias "$CA_NAME" -file $CA_CRT >/dev/null 2>&1 | echo "CA Certificates: Added certificate to cacert, $CA_CRT"
    done
    update-ca-certificates
else 
    echo "CA Certificates: Nothing to import, CA_URL is not defined"
fi
````