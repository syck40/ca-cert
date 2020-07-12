#!/bin/bash

PROJECT_DIR="/home/dl/builds/ca-cert"

#mkdir
mkdir -p $PROJECT_DIR/ca
cd $PROJECT_DIR/ca
mkdir -p certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial

# root key
cd $PROJECT_DIR/ca
openssl genrsa -aes256 -out private/ca.key.pem 4096

chmod 400 private/ca.key.pem

# root cert

cd $PROJECT_DIR/ca
openssl req -config openssl.cnf \
      -key private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/ca.cert.pem

chmod 444 certs/ca.cert.pem

openssl x509 -noout -text -in certs/ca.cert.pem

# intermediate cert
mkdir -p $PROJECT_DIR/intermediate && cd $PROJECT_DIR/intermediate
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial

# make int key
cd $PROJECT_DIR/ca
openssl genrsa -aes256 \
      -out intermediate/private/intermediate.key.pem 4096
chmod 400 intermediate/private/intermediate.key.pem

# make int csr
openssl req -config intermediate/openssl.cnf -new -sha256 \
      -key intermediate/private/intermediate.key.pem \
      -out intermediate/csr/intermediate.csr.pem

# sign int cert with root ca
openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in intermediate/csr/intermediate.csr.pem \
      -out intermediate/certs/intermediate.cert.pem

# verify int cert
openssl x509 -noout -text -in intermediate/certs/intermediate.cert.pem

# cert chain file
cat intermediate/certs/intermediate.cert.pem \
      certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem

chmod 444 intermediate/certs/ca-chain.cert.pem

# client key
#For server certificates, the Common Name must be a fully qualified domain name (eg, www.example.com), whereas for client certificates it can be any unique identifier (eg, an e-mail address). Note that the Common Name cannot be the same as either your root or intermediate certificate.
openssl genrsa -aes256 \
      -out intermediate/private/www.example.com.key.pem 2048

# csr for signing the cert
openssl req -config intermediate/openssl.cnf \
      -key intermediate/private/www.example.com.key.pem \
      -new -sha256 -out intermediate/csr/www.example.com.csr.pem

# sign csr with int CA
openssl ca -config intermediate/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in intermediate/csr/www.dluo.gaikai.org.csr.pem -out intermediate/certs/www.dluo.gaikai.org.cert.pem

# verify cert
openssl x509 -noout -text -in intermediate/certs/www.dluo.gaikai.org.cert.pem

# verify chain of trust
openssl verify -CAfile intermediate/certs/ca-chain.cert.pem intermediate/certs/www.dluo.gaikai.org.cert.pem

# When deploying to a server application (eg, Apache), you need to make the following files available:

# ca-chain.cert.pem
# www.example.com.key.pem
# www.example.com.cert.pem