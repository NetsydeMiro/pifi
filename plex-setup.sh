#!/bin/bash
# This script require root access, it should be run via sudo

# Adapted from https://thepi.io/how-to-set-up-a-raspberry-pi-plex-server/

##### Add the dev2day repository to package source list (it contains Plex). 
# Get crypto key
wget -O - https://dev2day.de/pms/dev2day-pms.gpg.key | sudo apt-key add -
# Add repo to the package source list. 
echo "deb https://dev2day.de/pms/ jessie main" | sudo tee /etc/apt/sources.list.d/pms.list
# update the package list
sudo apt-get update

#### Download Plex
apt-get -y install -t jessie plexmediaserver-installer

#### Configue plex to run under the pi user
sed -i "s/PLEX_MEDIA_SERVER_USER=plex/PLEX_MEDIA_SERVER_USER=pi/" /etc/default/plexmediaserver.prev

service plexmediaserver restart
