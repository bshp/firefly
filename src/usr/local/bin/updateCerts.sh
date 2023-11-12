#!/bin/bash
set -ex;
    
############
    
URL=$1

## Keygen ##
echo "Keygen: Checking for certificate generation"
if [[ -f "/etc/ssl/server.key" ]] || [[ -f "/etc/ssl/server.pem" ]];then
    echo "Keygen: Certificate exist, checking if one should be generated"
    if [[ -f "/etc/ssl/default.keys" ]]; then
        echo "Keygen: Default build keys detected, new pair will be generated";
        rm /etc/ssl/default.keys;
        openssl dhparam -out /etc/ssl/dhparams.pem 2048
        openssl req -newkey rsa:2048 -x509 -nodes \
            -keyout /etc/ssl/server.key -new \
            -out /etc/ssl/server.pem \
            -subj /CN=localhost -sha256 -days 3650
    fi
    PEM_SHA1=$(openssl x509 -noout -fingerprint -sha1 -in /etc/ssl/server.pem | cut -f2 -d"=" | sed "s/://g" | awk '{print tolower($0)}')
    echo "Keygen: Finished, Certificate Thumbprint: $PEM_SHA1"
fi

echo "CA Certificates: Checking for CA Import"
if [ "${URL}" != "none" ];then
    echo "CA Certificates: The following URL will be searched ${URL}";
    cd /usr/local/share/ca-certificates;
    wget -r -nH -A *_CA.crt ${URL};
    for CA_CRT in /usr/local/share/ca-certificates/*.crt; do
        CA_NAME=$(openssl x509 -noout -subject -nameopt multiline -in $CA_CRT | sed -n 's/ *commonName *= //p');
        CA_EXISTS=$(${JAVA_HOME}/bin/keytool -list -cacerts -storepass changeit -alias "$CA_NAME" | echo $?);
        if [ "$CA_EXISTS" -eq 0 ];then
            ${JAVA_HOME}/bin/keytool -import -trustcacerts -cacerts \
                -storepass changeit -noprompt -alias "$CA_NAME" -file $CA_CRT >/dev/null 2>&1 \
                | echo "CA Certificates: Added certificate to cacert, $CA_CRT"
        else 
            echo "CA Certificates: Certificate ${CA_NAME} already exists, not adding";
        fi;
    done;
    update-ca-certificates;
    rm -rf /usr/local/share/ca-certificates/*;
else 
    echo "CA Certificates: Nothing to import, CA_URL is not defined"
fi
