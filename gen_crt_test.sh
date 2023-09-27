#!/bin/bash
##### TLS TEST #####

# variable setting #
CAname=git-rootca
CN=GIT
OU=Bigdata_Team
O=GIT
L=MapoGu
ST=Seoul
C=KR
passwd=vmware1!
# 밑에는 수정 X #
serverdir=/opt/cloudera/security/pki
CAdir=${serverdir}/ca
ServerName=$(hostname -f)
Domain=echo $(hostname -f) | cut -d'.' -f 2-

# server.crt SAN
# DNS.1 = ${Domain}
# DNS.2 = *.${Domain}
# DNS.3 = $(hostname -f)
# DNS.4 = *.$(hostname -f)



#################
#RootCA generate#
#################

function gen_rootca(){
#Dir 생성 (Rootca Dir)

mkdir -p ${CAdir}

#CRT(인증서)생성에 필요한 configuration 파일 생성
cat << EOT > ${CAdir}/${CAname}.cnf
[ req ]
default_bits = 2048
default_md = sha1
default_keyfile = rootca.key
distinguished_name = req_distinguished_name 
extensions = v3_ca
req_extensions = v3_ca 
[ v3_ca ]
basicConstraints = critical, CA:TRUE, pathlen:0 
subjectKeyIdentifier = hash
##authorityKeyIdentifier = keyid:always, issuer:always 
keyUsage = keyCertSign, cRLSign
nsCertType = sslCA, emailCA, objCA 
[req_distinguished_name ]
countryName = Country Name (2 letter code)
countryName_default = KR
countryName_min = 2
countryName_max = 2 
# 회사명 입력
organizationName = Organization Name (eg, company) 
organizationName_default = GIT Inc.
# 부서 입력
#organizationalUnitName = Organizational Unit Name (eg, section) 
#organizationalUnitName_default = Condor Project
# SSL 서비스할 domain명 입력
commonName = ${Domain}
commonName_default = GIT's Self Signed CA
commonName_max = 64
EOT

# rootca.jks 
$JAVA_HOME/bin/keytool -genkeypair -storepass ${passwd} -alias ${CAname} -keyalg RSA \
-keystore ${CAdir}/${CAname}.jks -keysize 2048 \
-dname "CN=${CN},OU=${OU},O=${O},L=${L},ST=${ST},C=${C}" 

# rootca.csr  
$JAVA_HOME/bin/keytool -certreq -alias ${CAname} -storepass ${passwd} -keystore ${CAdir}/${CAname}.jks \
-file ${CAdir}/${CAname}.csr \
-ext EKU=serverAuth,clientAuth

# rootca.p12 
$JAVA_HOME/bin/keytool -importkeystore -srcstorepass ${passwd} -deststorepass ${passwd} \
-srckeystore ${CAdir}/${CAname}.jks -destkeystore ${CAdir}/${CAname}.p12 \
-deststoretype PKCS12 -srcalias ${CAname}

# rootca.key / pem
openssl pkcs12 -in ${CAdir}/${CAname}.p12 -nocerts -out ${CAdir}/${CAname}.key -passin pass:${passwd} -passout pass:${passwd}
openssl pkcs12 -in ${CAdir}/${CAname}.p12 -nocerts -out ${CAdir}/${CAname}.key.pem -passin pass:${passwd} -passout pass:${passwd}

# rootca.crt / pem
openssl x509 -req -days 365 -extensions v3_ca -set_serial 1 -sha256 -in ${CAdir}/${CAname}.csr \
-signkey ${CAdir}/${CAname}.key \
-out ${CAdir}/${CAname}.crt.pem \
-extfile ${CAdir}/${CAname}.cnf -passin pass:${passwd}

openssl x509 -req -days 365 -extensions v3_ca -set_serial 1 -sha256 -in ${CAdir}/${CAname}.csr \
-signkey ${CAdir}/${CAname}.key \
-out ${CAdir}/${CAname}.crt \
-extfile ${CAdir}/${CAname}.cnf -passin pass:${passwd}

# permission for security
chmod 600 ${CAdir}/${CAname}.*
}



#######################
# server.crt generate #
#######################

function gen_servercrt(){
#CRT(인증서)생성에 필요한 configuration 파일 생성
cat << EOT > ${serverdir}/${ServerName}.cnf
[ req ]
default_bits = 2048
distinguished_name = req_distinguished_name
string_mask = utf8only
default_md = sha256
x509_extensions = server_cert

[ req_distinguished_name ]
countryName = Country Name (2 letter code)
stateOrProvinceName = State or Province Name
localityName = Locality Name
0.organizationName = Organization Name 
organizationalUnitName = Organizational Unit Name 
commonName = Common Name
emailAddress = Email Address 
countryName_default = KR 
stateOrProvinceName_default = Seoul 
localityName_default = Mapo-Gu
0.organizationName_default = GIT
organizationalUnitName_default = Biadata Team 
emailAddress_default = git@goodmit.co.kr
[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer 
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign 
[ server_cert ]
basicConstraints = CA:FALSE
nsComment = "OpenSSL Generated Server Certificate" 
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = nonRepudiation, digitalSignature, keyEncipherment 
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names 
[ alt_names ]
DNS.1 = ${Domain}
DNS.2 = *.${Domain}
DNS.3 = $(hostname -f)
DNS.4 = *.$(hostname -f)
EOT

# server.jks 
$JAVA_HOME/bin/keytool -genkeypair -storepass ${passwd} -alias ${ServerName} -keyalg RSA \
-keystore ${serverdir}/${ServerName}.jks -keysize 2048 \
-dname "CN=${CN},OU=${OU},O=${O},L=${L},ST=${ST},C=${C}" 


# server.csr  
$JAVA_HOME/bin/keytool -certreq -alias ${ServerName} -storepass ${passwd} -keystore ${serverdir}/${ServerName}.jks \
-file ${serverdir}/${ServerName}.csr \
-ext EKU=serverAuth,clientAuth

# server.p12 
$JAVA_HOME/bin/keytool -importkeystore -srcstorepass ${passwd} -deststorepass ${passwd} \
-srckeystore ${serverdir}/${ServerName}.jks -destkeystore ${serverdir}/${ServerName}.p12 \
-deststoretype PKCS12 -srcalias ${ServerName}


# server.key / pem
openssl pkcs12 -in ${serverdir}/${ServerName}.p12 -nocerts -out ${serverdir}/${ServerName}.key -passin pass:${passwd} -passout pass:${passwd}
openssl pkcs12 -in ${serverdir}/${ServerName}.p12 -nocerts -out ${serverdir}/${ServerName}.key.pem -passin pass:${passwd} -passout pass:${passwd}


# server.crt / pem
openssl x509 -req -sha256 -days 365 -extensions server_cert -in ${serverdir}/${ServerName}.csr \
-CA ${serverdir}/ca/${CAname}.crt.pem -CAkey ${serverdir}/ca/${CAname}.key \
-CAcreateserial -out ${serverdir}/${ServerName}.crt.pem -extfile ${serverdir}/${ServerName}.cnf -passin pass:${passwd}

openssl x509 -req -sha256 -days 365 -extensions server_cert -in ${serverdir}/${ServerName}.csr \
-CA ${serverdir}/ca/${CAname}.crt.pem -CAkey ${serverdir}/ca/${CAname}.key \
-CAcreateserial -out ${serverdir}/${ServerName}.crt -extfile ${serverdir}/${ServerName}.cnf -passin pass:${passwd}


# permission for security
chmod 600 ${serverdir}/${ServerName}.*
}


# CLOUDERA TLS truststore, keystore
function make_store(){
cp $JAVA_HOME/lib/security/cacerts ${CAdir}/jssecacerts

# rootca.crt -> truststore(jssecacerts)
$JAVA_HOME/bin/keytool -importcert -alias ${CAname} -file ${CAdir}/${CAname}.crt -keystore ${CAdir}/jssecacerts -storepass changeit -noprompt

# rootca.crt -> server.jks
$JAVA_HOME/bin/keytool -importcert -alias ${CAname} -file ${CAdir}/${CAname}.crt -keystore ${serverdir}/${ServerName}.jks -storepass ${passwd} -noprompt
# server.crt -> server.jks
$JAVA_HOME/bin/keytool -importcert -alias ${ServerName} -file ${serverdir}/${ServerName}.crt -keystore ${serverdir}/${ServerName}.jks -storepass ${passwd} -noprompt

# symbolic link 
ln -s /opt/cloudera/security/pki/$(hostname -f).crt.pem /opt/cloudera/security/pki/agent.pem
ln -s /opt/cloudera/security/pki/$(hostname -f).jks /opt/cloudera/security/pki/server.jks
}

gen_rootca
gen_servercrt
make_store
