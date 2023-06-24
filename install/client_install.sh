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

# set hostname for client // set DNS for Server
echo "mailsurfer" > /etc/hostname
echo "$serverip mailproxy" >> /etc/hosts

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

# configure postfix for client
mkdir -p /etc/postfix
cat config/mailsurfer_postfix.conf > /etc/postfix/main.cf
echo "/.*/ root" >> /etc/postfix/virtual
echo 'smtpsurfer: "|/smtpsurfer/shell/client_mail-browser_tunnel.sh"' >> /etc/aliases
echo "somebody: root" >> /etc/aliases
# set mynetwork to cidr
sed -i "s/mynetworks = $cidr/mynetworks = $cidr/g" /etc/postfix/main.cf
postalias /etc/aliases
postmap /etc/postfix/virtual
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

mkdir -p /smtpsurfer/{shell,response,cert,python}
chmod -R 777 /smtpsurfer

# install mitmproxy
if [ $base -eq 1 ]; then
    pacman -S mitmproxy --noconfirm
elif [ $base -eq 2 ]; then
    apt-get install mitmproxy -y
fi

# set mitmproxy ca-cert
sudo mitmdump
wget -e use_proxy=yes -e http_proxy=localhost:8080 http://mitm.it/cert/pem -O /smtpsurfer/cert/mitmproxy-ca-cert.pem
if [ $base -eq 1 ]; then
    sudo trust anchor --store /smtpsurfer/cert/mitmproxy-ca-cert.pem
elif [ $base -eq 2 ]; then
    sudo mkdir -p /usr/local/share/ca-certificates
    sudo cp /smtpsurfer/cert/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy-ca-cert.pem
    sudo update-ca-certificates
fi
killall mitmdump

# copy tunnel script for client into /usr/bin/smtpsurfer
cp script/python/client_browser-mail-browser_tunnel.py /smtpsurfer/python/client_browser-mail-browser_tunnel.py
cp script/shell/client_browser-mail_tunnel.sh /smtpsurfer/shell/client_browser-mail_tunnel.sh && chmod +x /smtpsurfer/shell/client_browser-mail_tunnel.sh
cp script/shell/client_mail-browser_tunnel.sh /smtpsurfer/shell/client_mail-browser_tunnel.sh && chmod +x /smtpsurfer/shell/client_mail-browser_tunnel.sh
cp run/smtpsurfer.sh /usr/bin/smtpsurfer && chmod +x /usr/bin/smtpsurfer

# install chromium
if [ $base -eq 1 ]; then
    pacman -S chromium --noconfirm
elif [ $base -eq 2 ]; then
    apt-get install chromium-browser -y
fi

chmod -R 777 /smtpsurfer

echo '
    ______ _____ _   _  _____ 
    |  _  \  _  | \ | ||  ___|
    | | | | | | |  \| || |__  
    | | | | | | | . ` ||  __| 
    | |/ /\ \_/ / |\  || |___ 
    |___/  \___/\_| \_/\____/ 

        REBOOT REQUIRED
        
reboot now? (y/n)'
read reboot
if [ $reboot == "y" ]; then
    reboot
fi