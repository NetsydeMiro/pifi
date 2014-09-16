#!/bin/bash
# This script require root access, it should be run via sudo


##### Sane Defaults #####
# read -p 'Enter desired server name: ' pifi_server_name
pifi_server_name='pifi'
# read -p 'Enter notification email server: ' notification_server
notification_server='smtp.gmail.com'
# read -p 'Enter notification email server port: ' notification_port
notification_port=587
# read -p 'Enter backup job start hour (0 is midnight, 23 is 11pm): ' backup_start_hour
backup_start_hour=2


##### Inputs we require #####
read -p  'Enter Workgroup name: ' workgroup
read -p  'Enter notification sender gmail: ' notification_sender
read -sp 'Enter notification sender gmail password: ' notification_password; echo
read -p  'Enter notification receiver email: ' notification_receiver


##### Housekeeping
apt-get -y update
# htop is slicker than top for checking server load
apt-get -y install htop
# Vim is the bomb
update-alternatives --set editor /usr/bin/vim.tiny


##### Hostname Setup
hostname $pifi_server_name
sed -i "s/raspberrypi/${pifi_server_name}/" /etc/hosts
sed -i "s/raspberrypi/${pifi_server_name}/" /etc/hostname


##### NTFS drive mounting
apt-get -y install ntfs-3g
mkdir /media/pri /media/aux 

# add entries to fstab so that we mount drives on every bootup
echo '/dev/sda1  /media/pri  ntfs-3g  default  0  0' >> /etc/fstab
echo '/dev/sdb1  /media/aux  ntfs-3g  default  0  0' >> /etc/fstab
mount -a

# ensure shares directories are available
mkdir -p -m a=rwx /media/pri/shares /meida/aux/shares


##### Samba Setup
apt-get -y install samba samba-common-bin libpam-smbpass
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# set workgroup name
sed -i "s/WORKGROUP/${workgroup}/" /etc/samba/smb.conf

# make home directories writeable (first instance of read only is in homes section)
sed -i "0,/read only = yes/{s/read only = yes/read only = no/}" /etc/samba/smb.conf

# ensure public media directory is available
mkdir -p -m a=rwx /media/pri/shares/public

# add public share
cat <<EOF >> /etc/samba/smb.conf

[public]
   comment = Public Files
   path = /media/pri/shares/public
   browseable = yes
   writeable = yes
   guest ok = yes
   read only = no
EOF

service samba restart


##### MiniDLNA Setup
apt-get -y install minidlna
cp /etc/minidlna.conf /etc/minidlna.conf.bak

# set minidlna server name
sed -i "s/#friendlyname=/friendlyname=${pifi_server_name}/" /etc/minidlna.conf

# ensure public media directories are available
mkdir -p -m a=rwx /media/pri/shares/public/video /media/pri/shares/public/audio /media/pri/shares/public/pictures

# set media directories
sed -i 's/media_dir=\/var\/lib\/minidlna/# defined at end/' /etc/minidlna.conf
cat <<EOF >> /etc/minidlna.conf

media_dir=V,/media/pri/shares/public/video
media_dir=A,/media/pri/shares/public/audio
media_dir=P,/media/pri/shares/public/pictures
EOF

service minidlna force-reload


##### Notification Email Setup
sudo apt-get -y install msmtp

# add mail settings
cat <<EOF > /etc/msmtprc
account default
host $notification_server
port $notification_port
auth on
user $notification_sender
password $notification_password
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
from $notification_sender
aliases /etc/aliases
EOF

cat <<EOF > /etc/aliases
default: $notification_receiver
EOF


##### Backup Task Setup
# Add backup task to /usr/local/sbin since it should only be executed by superusers
cat <<EOF > /usr/local/sbin/pifi-backup
#!/bin/bash

{
	cat <<HEADER
	From: $pifi_server_name Backup Operation
	To: $notification_receiver
	Subject: Backup Report
	HEADER
	rsync -rvt --stats /media/pri/shares/ /media/aux/shares ;
} | msmtp $notification_receiver
EOF


# make it executable by root
chmod u+x /usr/local/sbin/pifi-backup

# Automate it via cron to run daily
# (this should create a root cron job, so we shouldn't require sudo in the command)
crontab <<EOF
00 $backup_start_hour * * *   /usr/local/sbin/pifi-backup 2>> /var/log/pifi-backup.err
EOF


##### pifi-adduser command
# Add adduser command to /usr/local/sbin since it should only be executed by superusers
wget https://raw.githubusercontent.com/NetsydeMiro/pifi/master/pifi-adduser \
  -O /usr/local/sbin/pifi-adduser

# make it executable by root
chmod u+x /usr/local/sbin/pifi-adduser

