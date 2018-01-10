#!/bin/bash
# This script require root access, it should be run via sudo

# UPDATE: It appears that this script is no longer necessary with Raspbian Jessie and/or Win10.  
# Leaving for reference in case needed in some form again in the future. 

# With Raspbian Wheezy PiFi needed a samba -> linux user mapping 
# because my windows box user is an email due win8's weird initial setup procedure, 
# and 'nix recommends against symbols in usernames.  
# Other Windows 8 users may be in a similar bind... modify this as required.

# create username mapping file
echo 'miro = miro@netsyde.com' > /etc/samba/smbusers.map

# add username mapping reference to samba config
sed -i 's/\(^#\s*security = user\s*\)/\1\n   username map = \/etc\/samba\/smbusers.map/' \
  /etc/samba/smb.conf

service samba restart
