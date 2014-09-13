#!/bin/bash
# Note that this script require root access, it should be run via sudo


##### Sane Defaults #####
# read -p 'Enter desired server name: ' pifi_server_name
pifi_server_name='pifi'
# read -p 'Enter notification email server: ' notification_server
notification_server='smtp.gmail.com:587'
# read -p 'Enter backup job start hour (0 is midnight, 23 is 11pm): ' backup_start_hour
backup_start_hour=2


##### Inputs we require #####
read -p  'Enter Workgroup name: ' workgroup
read -p  'Enter notification sender gmail: ' notification_sender
read -sp 'Enter notification sender gmail password: ' notification_password; echo
read -p  'Enter notification receiver email: ' notification_receiver


#### Housekeeping
apt-get -y update
# htop is slicker than top
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
apt-get -y install samba samba-common-bin libpam-smbpass winbind

# backup configs
cp /etc/nsswitch.conf /etc/nsswitch.conf.bak
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# so that we can see the server on windows machines on the network
sed -i 's/files dns/files wins dns/' /etc/nsswitch.conf

# set workgroup name
sed -i "s/WORKGROUP/${workgroup}/" /etc/samba/smb.conf

# set security = user, which is usually a good idea
sed -i "s/#\s*security = user/   security = user/" /etc/samba/smb.conf

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

# backup config
cp /etc/minidlna.conf /etc/minidlna.conf.bak

# may not need this, appears to use hostname by default
#sed -i 's/#friendlyname=/friendlyname=${pifi_server_name}/ ' /etc/minidlna.conf


# ensure public media directories are available
mkdir -p -m a=rwx /media/pri/shares/public/video /media/pri/shares/public/audio /media/pri/shares/public/pictures

sed -i 's/media_dir=\/var\/lib\/minidlna/# defined at end/' /etc/minidlna.conf
cat <<EOF >> /etc/minidlna.conf

media_dir=V,/media/pri/shares/public/video
media_dir=A,/media/pri/shares/public/audio
media_dir=P,/media/pri/shares/public/pictures
EOF

service minidlna force-reload


##### Notification Email Setup
sudo apt-get -y install ssmtp mailutils
# keep copy of original for kicks
cp /etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf.bak

# replace mail settings
sed -i "s/=mail/=${notification_server}/" /etc/ssmtp/ssmtp.conf
sed -i 's/#FromLineOverride/FromLineOverride/' /etc/ssmtp/ssmtp.conf
sed -i "s/hostname=.*/hostname=${pifi_server_name}/" /etc/ssmtp/ssmtp.conf

# add more mail settings
cat <<EOF >> /etc/ssmtp/ssmtp.conf

AuthUser=$notification_sender
AuthPass=$notification_password
UseSTARTTLS=YES
EOF


##### Backup Task Setup
# Add backup task to /usr/local/sbin since it should only be executed by superusers
cat <<EOF > /usr/local/sbin/pifi-backup
rsync -rv --stats /media/pri/shares/ /media/aux/shares |
mail -s "Backup Report" -a "From: $pifi_server_name Backup Operation" $notification_receiver
EOF

# make it executable by root
chmod u+x /usr/local/sbin/pifi-backup

# Automate it via cron to run daily
# (this should create a root cron job, so we shouldn't require sudo in the command)
crontab <<EOF
00 $backup_start_hour * * *   /usr/local/sbin/pifi-backup 2>> /var/log/pifi-backup.err
EOF


##### pifi_adduser command
# Add adduser command to /usr/local/sbin since it should only be executed by superusers
wget https://raw.githubusercontent.com/NetsydeMiro/pifi/master/pifi-adduser \
  -O /usr/local/sbin/pifi-adduser

# make it executable by root
chmod u+x /usr/local/sbin/pifi-adduser

