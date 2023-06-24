#!/bin/bash

serverip="10.0.0.9"
clientip="10.0.0.8"
cidr="10.0.0.0/24"

echo "________________________________________________________"
echo "Insert Server IP:"
read serverip
echo "Insert Client IP:"
read clientip
echo "Insert network CIDR:"
read cidr
echo ""
echo "You set serverip: $serverip"
echo "You set clientip: $clientip"
echo "You set network CIDR: $cidr"
echo ""
echo "Is this correct? (y/n)"
read correct
echo ""
while [ $correct != "y" ]; do
    echo "Insert Server IP:"
    read serverip
    echo "Insert Client IP:"
    read clientip
    echo "Insert network CIDR:"
    read cidr
    echo ""
    echo "You set serverip: $serverip"
    echo "You set clientip: $clientip"
    echo "You set network CIDR: $cidr"
    echo ""
    echo "Is this correct? (y/n)"
    read correct
    echo ""
done
echo ""
echo "________________________________________________________"

# set hostname for server // set DNS for Client
echo "mailproxy" > /etc/hostname
echo "$clientip mailsurfer" >> /etc/hosts

# set editor to nano
echo "export EDITOR=nano" >> /etc/bash.bashrc
source /etc/bash.bashrc

base=0
# check if arch set 1 or debian set 2
if [ -f /etc/arch-release ]; then
    base=1
elif [ -f /etc/debian_version ]; then
    base=2
fi

# update system
if [ $base -eq 1 ]; then
    pacman -Syu --noconfirm
elif [ $base -eq 2 ]; then
    apt-get update
    apt-get upgrade -y
fi

# install python3
if [ $base -eq 1 ]; then
    pacman -S python3 --noconfirm
elif [ $base -eq 2 ]; then
    apt-get install python3 -y
fi

# install postfix / sendmail
if [ $base -eq 1 ]; then
    pacman -S postfix mailutils --noconfirm
elif [ $base -eq 2 ]; then
    apt-get install postfix mailutils -y
fi
echo "postfix postfix/main_mailer_type select No configuration" | sudo debconf-set-selections

# configure postfix for server
mkdir -p /etc/postfix
cat config/mailproxy_postfix.conf > /etc/postfix/main.cf
echo "/.*/ root" >> /etc/postfix/virtual
postmap /etc/postfix/virtual
echo 'smtpsurfer: "|/smtpsurfer/shell/server_mail-proxy-mail_tunnel.sh"' >> /etc/aliases
echo "somebody: root" >> /etc/aliases
sed -i "s/mynetworks = $cidr/mynetworks = $cidr/g" /etc/postfix/main.cf
postalias /etc/aliases
systemctl enable --now postfix

# install nmap-netcat
if [ $base -eq 1 ]; then
    pacman -S nmap-netcat --noconfirm
elif [ $base -eq 2 ]; then
    apt-get install nmap-netcat -y
fi

#####                                         #####
##### different configs for server and client #####
#####                                         #####

# copy tunnel script for server into /usr/bin/smtpsurfer
mkdir -p /smtpsurfer/{shell,response,cert}
chmod -R 777 /smtpsurfer
cp script/shell/server_mail-proxy-mail_tunnel.sh /smtpsurfer/shell/server_mail-proxy-mail_tunnel.sh && chmod +x /smtpsurfer/shell/server_mail-proxy-mail_tunnel.sh
cp run/smtpsurfer.sh /usr/bin/smtpsurfer && chmod +x /usr/bin/smtpsurfer

# install squid
if [ $base -eq 1 ]; then
    pacman -S squid --noconfirm
elif [ $base -eq 2 ]; then
    apt-get install squid -y
fi

# configure squid for server
sed -i "s/http_port 3128/http_port 8080/g" /etc/squid/squid.conf # change port to 8080
sed -i "s/# http_access allow localnet/http_access allow localnet/g" /etc/squid/squid.conf # allow localnet
#sudo openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -keyout /smtpsurfer/cert/squid.key -out /smtpsurfer/cert/squid.pem -subj "/C=DE/ST=BY/L=Earth/O=smtpsurfer/OU=IT/CN=mailproxy"
systemctl enable --now squid

# # install nginx
# if [ $base -eq 1 ]; then
#     pacman -S nginx --noconfirm
# elif [ $base -eq 2 ]; then
#     apt-get install nginx -y
# fi

# # configure nginx for server
# mkdir -p /etc/nginx/conf.d
# cp config/mailproxy_nginx.conf /etc/nginx/nginx.conf
# cp config/mailproxy_nginx_confd.conf /etc/nginx/conf.d/mailproxy.conf
# systemctl enable --now nginx

chmod -R 777 /smtpsurfer

echo '
    ______ _____ _   _  _____ 
    |  _  \  _  | \ | ||  ___|
    | | | | | | |  \| || |__  
    | | | | | | | . ` ||  __| 
    | |/ /\ \_/ / |\  || |___ 
    |___/  \___/\_| \_/\____/ 

        REBOOT REQUIRED

reboot now? [y/n]'
read reboot
if [ $reboot == "y" ]; then
    reboot
fi