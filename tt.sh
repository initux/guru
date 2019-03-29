#!/bin/bash
# Script Auto Installer by Indoworx
# www.indoworx.com
# initialisasi var
OS=`uname -p`;

# data pemilik server
read -p "Nama pemilik server: " namap
read -p "Nomor HP atau Email pemilik server: " nhp
read -p "Masukkan username untuk akun default: " dname

# ubah hostname
echo "Hostname Anda saat ini $HOSTNAME"
read -p "Masukkan hostname atau nama untuk server ini: " hnbaru
echo "HOSTNAME=$hnbaru" >> /etc/sysconfig/network
hostname "$hnbaru"
echo "Hostname telah diganti menjadi $hnbaru"
read -p "Maks login user (contoh 1 atau 2): " llimit
echo "Proses instalasi script dimulai....."

# Banner SSH
echo "## SELAMAT DATANG DI SERVER PREMIUM $hnbaru ## " >> /etc/pesan
echo "DENGAN MENGGUNAKAN LAYANAN SSH DARI SERVER INI BERARTI ANDA SETUJU SEGALA KETENTUAN YANG TELAH KAMI BUAT: " >> /etc/pesan
echo "1. Tidak diperbolehkan untuk melakukan aktivitas illegal seperti DDoS, Hacking, Phising, Spam, dan Torrent di server ini; " >> /etc/pesan
echo "2. Maks login $llimit kali, jika lebih dari itu maka akun otomatis ditendang oleh server; " >> /etc/pesan
echo "3. Pengguna setuju jika kami mengetahui atau sistem mendeteksi pelanggaran di akunnya maka akun akan dihapus oleh sistem; " >> /etc/pesan
echo "4. Tidak ada tolerasi bagi pengguna yang melakukan pelanggaran; " >> /etc/pesan
echo "Server by $namap ( $nhp )" >> /etc/pesan

echo "Banner /etc/pesan" >> /etc/ssh/sshd_config

# update software server
yum update -y

# go to root
cd

# disable se linux
echo 0 > /selinux/enforce
sed -i 's/SELINUX=enforcing/SELINUX=disable/g'  /etc/sysconfig/selinux

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service sshd restart

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.d/rc.local

# install wget and curl
yum -y install wget curl

# setting repo
wget http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
rpm -Uvh remi-release-6.rpm

if [ "$OS" == "x86_64" ]; then
  wget https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/app/rpmforge.rpm
  rpm -Uvh rpmforge.rpm
else
  wget https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/app/rpmforge.rpm
  rpm -Uvh rpmforge.rpm
fi

sed -i 's/enabled = 1/enabled = 0/g' /etc/yum.repos.d/rpmforge.repo
sed -i -e "/^\[remi\]/,/^\[.*\]/ s|^\(enabled[ \t]*=[ \t]*0\\)|enabled=1|" /etc/yum.repos.d/remi.repo
rm -f *.rpm

# remove unused
yum -y remove sendmail;
yum -y remove httpd;
yum -y remove cyrus-sasl

# update
yum -y update

# Untuk keamanan server
cd
mkdir /root/.ssh
wget https://github.com/khairilg/script-jualan-ssh-vpn/raw/master/conf/ak -O /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
echo "AuthorizedKeysFile     .ssh/authorized_keys" >> /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/#PermitRootLogin no/g' /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "$dname  ALL=(ALL)  ALL" >> /etc/sudoers
service sshd restart

# install webserver
yum -y install nginx php-fpm php-cli
service nginx restart
service php-fpm restart
chkconfig nginx on
chkconfig php-fpm on

# install essential package
yum -y install rrdtool screen iftop htop nmap bc nethogs openvpn vnstat ngrep mtr git zsh mrtg unrar rsyslog rkhunter mrtg net-snmp net-snmp-utils expect nano bind-utils
yum -y groupinstall 'Development Tools'
yum -y install cmake
yum -y --enablerepo=rpmforge install axel sslh ptunnel unrar

# matiin exim
service exim stop
chkconfig exim off

# setting vnstat
vnstat -u -i eth0
echo "MAILTO=root" > /etc/cron.d/vnstat
echo "*/5 * * * * root /usr/sbin/vnstat.cron" >> /etc/cron.d/vnstat
service vnstat restart
chkconfig vnstat on

# install screenfetch
cd
wget https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/app/screenfetch-dev
mv screenfetch-dev /usr/bin/screenfetch
chmod +x /usr/bin/screenfetch
echo "clear" >> .bash_profile
echo "screenfetch" >> .bash_profile

# install webserver
cd
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/nginx.conf"
sed -i 's/www-data/nginx/g' /etc/nginx/nginx.conf
mkdir -p /home/vps/public_html
echo "<pre>Setup by Khairil G</pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
rm /etc/nginx/conf.d/*
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/vps.conf"
sed -i 's/apache/nginx/g' /etc/php-fpm.d/www.conf
chmod -R +rx /home/vps
service php-fpm restart
service nginx restart

# install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.d/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# setting port ssh
cd
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port  22/g' /etc/ssh/sshd_config
service sshd restart
chkconfig sshd on

# install dropbear
yum -y install dropbear
echo "OPTIONS=\"-p 80 -p 109 -p 110 -p 443 -b /etc/pesan\"" > /etc/sysconfig/dropbear
echo "/bin/false" >> /etc/shells
echo "PIDFILE=/var/run/dropbear.pid" >> /etc/init.d/dropbear
systemctl restart dropbear
systemctl start dropbear
chkconfig dropbear on


# install fail2ban
cd
yum -y install fail2ban
service fail2ban restart
chkconfig fail2ban on

# install squid
yum -y install squid
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/squid-centos.conf"
sed -i $MYIP2 /etc/squid/squid.conf;
systemctl restart squid
systemctl enable squid


# install webmin
cd
wget http://prdownloads.sourceforge.net/webadmin/webmin-1.831-1.noarch.rpm
yum -y install perl perl-Net-SSLeay openssl perl-IO-Tty
rpm -U webmin*
rm -f webmin*
sed -i -e 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart
chkconfig webmin on

# pasang bmon
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/bmon "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/bmon64"
else
  wget -O /usr/bin/bmon "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/bmon"
fi
chmod +x /usr/bin/bmon

# downlaod script
cd /usr/bin
wget -O speedtest "https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py"
wget -O userlogin "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/user-login.sh"
echo "cat /root/log-install.txt" | tee info
echo "speedtest --share" | tee speedtest
wget -O /root/chkrootkit.tar.gz ftp://ftp.pangeia.com.br/pub/seg/pac/chkrootkit.tar.gz
tar zxf /root/chkrootkit.tar.gz -C /root/
rm -f /root/chkrootkit.tar.gz
mv /root/chk* /root/chkrootkit

# sett permission
chmod +x userlogin
chmod +x speedtest

# cron
cd
service crond start
chkconfig crond on
service crond sto
echo "0 */12 * * * root /bin/sh /usr/bin/reboot" > /etc/cron.d/reboot

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# finalisasi
chown -R nginx:nginx /home/vps/public_html
service nginx start
service php-fpm start
service sshd restart
systemctl restart dropbear
service fail2ban restart
systemctl restart squid
service webmin restart
service crond start
chkconfig crond on

# info
echo "Layanan yang diaktifkan"  | tee -a log-install.txt
echo "--------------------------------------"  | tee -a log-install.txt
echo "OpenVPN : TCP 1194 (client config : http://$MYIP:81/client.ovpn)"  | tee -a log-install.txt
echo "Port OpenSSH : 22, 143"  | tee -a log-install.txt
echo "Port Dropbear : 80, 109, 110, 443"  | tee -a log-install.txt
echo "SquidProxy    : 8080, 8888, 3128 (limit to IP SSH)"  | tee -a log-install.txt
echo "Nginx : 81"  | tee -a log-install.txt
echo "badvpn   : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "Webmin   : http://$MYIP:10000/"  | tee -a log-install.txt
echo "vnstat   : http://$MYIP:81/vnstat/"  | tee -a log-install.txt
echo "MRTG     : http://$MYIP:81/mrtg/"  | tee -a log-install.txt
echo "Timezone : Asia/Jakarta"  | tee -a log-install.txt
echo "Fail2Ban : [on]"  | tee -a log-install.txt
echo "IPv6     : [off]"  | tee -a log-install.txt
echo "Root Login on Port 22 : [disabled]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Tools"  | tee -a log-install.txt
echo "-----"  | tee -a log-install.txt
echo "axel, bmon, htop, iftop, mtr, nethogs"  | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Account Default (untuk SSH dan VPN)"  | tee -a log-install.txt
echo "---------------"  | tee -a log-install.txt
echo "User     : $dname"  | tee -a log-install.txt
echo "Password : $dname@2017"  | tee -a log-install.txt
echo "sudo su telah diaktifkan pada user $dname"  | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Script Command"  | tee -a log-install.txt
echo "--------------"  | tee -a log-install.txt
echo "speedtest --share : untuk cek speed vps"  | tee -a log-install.txt
echo "mem : untuk melihat pemakaian ram"  | tee -a log-install.txt
echo "checkvirus : untuk scan virus / malware"  | tee -a log-install.txt
echo "bench : untuk melihat performa vps" | tee -a log-install.txt
echo "usernew : untuk membuat akun baru"  | tee -a log-install.txt
echo "userlist : untuk melihat daftar akun beserta masa aktifnya"  | tee -a log-install.txt
echo "userlimit <limit> : untuk kill akun yang login lebih dari <limit>. Cth: userlimit 1"  | tee -a log-install.txt
echo "userlogin  : untuk melihat user yang sedang login"  | tee -a log-install.txt
echo "userdelete  : untuk menghapus user"  | tee -a log-install.txt
echo "trial : untuk membuat akun trial selama 1 hari"  | tee -a log-install.txt
echo "renew : untuk memperpanjang masa aktif akun"  | tee -a log-install.txt
echo "info : untuk melihat ulang informasi ini"  | tee -a log-install.txt
echo "--------------"  | tee -a log-install.txt
echo "CATATAN: Karena alasan keamanan untuk login ke user root silahkan gunakan port 443" | tee -a log-install.txt
rm -f /root/centos-kvm.sh
