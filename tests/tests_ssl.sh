#!/bin/bash

##### currently not usable, collection of possible solutions #####

# socat/ncat listen on port 30 and forward to ssl port 60 whereas socat/ncat listen and forward to sendmail
# both same but one with ncat and one with socat
# socat will wait until the connection is closed, ncat will (maybe) not
socat -d tcp-listen:30,fork openssl:localhost:60,verify=0 &
ncat -vkl 30 | ncat --ssl localhost 60 &

ncat -vkl 60 --ssl-key /smtpsurfer/cert/mailsurfer_sig.key --ssl-cert /smtpsurfer/cert/mailsurfer_sig.pem | sendmail -i smtpsurfer@mailproxy &
socat openssl-listen:60,cert=/smtpsurfer/cert/mailsurfer_sig.pem,fork,verify=0 - | sendmail -i smtpsurfer@mailproxy &

# route ssl via socat to sendmail
socat openssl-listen:30,cert=/smtpsurfer/cert/mailsurfer_sig.pem,fork,verify=0 - | sendmail -i smtpsurfer@mailproxy &

# sudo openssl genrsa -out /smtpsurfer/cert/myCA.key 2048
# sudo openssl req -x509 -new -nodes -key /smtpsurfer/cert/myCA.key -sha256 -days 1024 -out /smtpsurfer/cert/myCA.pem -subj "/C=/ST=/L=/O=/OU=/CN=localhost"
# sudo openssl genrsa -out /smtpsurfer/cert/mailsurfer.key 2048
# sudo openssl req -new -key /smtpsurfer/cert/mailsurfer.key -out /smtpsurfer/cert/mailsurfer.csr -subj "/C=/ST=/L=/O=/OU=/CN=localhost"
# sudo openssl x509 -req -in /smtpsurfer/cert/mailsurfer.csr -CA myCA.pem -CAkey /smtpsurfer/cert/myCA.key -CAcreateserial -out /smtpsurfer/cert/mailsurfer.crt -days 1024 -sha256
# sudo cat /smtpsurfer/cert/mailsurfer.key /smtpsurfer/cert/mailsurfer.crt > /smtpsurfer/cert/mailsurfer.pem
# if [ $base -eq 1 ]; then
#     sudo trust anchor --store /smtpsurfer/cert/myCA.pem
#     sudo trust anchor --store /smtpsurfer/cert/mailsurfer.pem
# elif [ $base -eq 2 ]; then
#     sudo mkdir -p /usr/local/share/ca-certificates
#     sudo cp /smtpsurfer/cert/myCA.pem /usr/local/share/ca-certificates/myCA.pem
#     sudo cp /smtpsurfer/cert/mailsurfer.pem /usr/local/share/ca-certificates/mailsurfer.pem
#     sudo update-ca-certificates
# fi

# create rootCA and sign new cert for mailsurfer https proxy
# gen rootCA for mailsurfer https proxy
# convert to pem (for debian), add it to trusted
# sudo openssl genrsa -out /smtpsurfer/cert/rootCA.key 4096
# sudo openssl req -x509 -new -nodes -key /smtpsurfer/cert/rootCA.key -sha256 -days 1024 -out /smtpsurfer/cert/rootCA.crt -subj "/C=/ST=/L=/O=/OU=/CN=localhost"
# sudo openssl req -new -sha256 -nodes -out /smtpsurfer/cert/mailsurfer_sig.csr -newkey rsa:2048 -keyout /smtpsurfer/cert/mailsurfer_sig.key -subj "/C=/ST=/L=/O=/OU=/CN=localhost"
# sudo openssl x509 -req -in /smtpsurfer/cert/mailsurfer_sig.csr -CA /smtpsurfer/cert/rootCA.crt -CAkey /smtpsurfer/cert/rootCA.key -CAcreateserial -out /smtpsurfer/cert/mailsurfer_sig.crt -days 500 -sha256
# sudo cat /smtpsurfer/cert/mailsurfer_sig.crt /smtpsurfer/cert/mailsurfer_sig.key > /smtpsurfer/cert/mailsurfer_sig.pem
# sudo openssl x509 -in /smtpsurfer/cert/rootCA.crt -out /smtpsurfer/cert/rootCA.pem -outform PEM
# if [ $base -eq 1 ]; then
#     sudo trust anchor --store /smtpsurfer/cert/rootCA.pem
#     sudo trust anchor --store /smtpsurfer/cert/mailsurfer_sig.pem
# elif [ $base -eq 2 ]; then
#     sudo mkdir -p /usr/local/share/ca-certificates
#     sudo cp /smtpsurfer/cert/rootCA.pem /usr/local/share/ca-certificates/rootCA.pem
#     sudo cp /smtpsurfer/cert/mailsurfer_sig.pem /usr/local/share/ca-certificates/mailsurfer_sig.pem
#     sudo update-ca-certificates
# fi

# cert for mailsurfer https proxy without rootCA
# convert to pem (for debian), add it to trusted
sudo openssl req -newkey rsa:2048 -sha256 -nodes -keyout /smtpsurfer/cert/mailsurfer_nosig.key -x509 -days 365 -subj "/C=/ST=/L=/O=/OU=/CN=localhost" -out /smtpsurfer/cert/mailsurfer_nosig.crt
sudo openssl dhparam -out /smtpsurfer/cert/dhparam.pem 2048
sudo cat /smtpsurfer/cert/mailsurfer_nosig.crt /smtpsurfer/cert/mailsurfer_nosig.key > /smtpsurfer/cert/mailsurfer_nosig.pem
sudo cat /smtpsurfer/cert/dhparam.pem >> /smtpsurfer/cert/mailsurfer_nosig.pem
if [ $base -eq 1 ]; then
    sudo trust anchor --store /smtpsurfer/cert/mailsurfer_nosig.pem
elif [ $base -eq 2 ]; then
    sudo mkdir -p /usr/local/share/ca-certificates
    sudo cp /smtpsurfer/cert/mailsurfer_nosig.pem /usr/local/share/ca-certificates/mailsurfer_nosig.pem
    sudo update-ca-certificates
fi