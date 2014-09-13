# I need to add a samba -> linux user mapping because my windows box user is an email
# due to a weird win8 initial setup procedure.  Nix recommends against symbols in usernames.  
# Other Windows 8 users may be in a similar bind... modify this as required.

# create username mapping file
echo 'miro = miro@netsyde.com' > /etc/samba/smbusers.map

# add username mapping reference to samba config
sed -i 's/\(^\s*security = user\s*\)/\1\n   username map = \/etc\/samba\/smbusers.map/' \
  /etc/samba/smb.conf
