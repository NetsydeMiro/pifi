PiFi
====
Your Own Raspberry Pi File Server
------------------------------------

PiFi is a bash script that quickly converts your Raspberry Pi into a DLNA-enabled NAS server with public and private drive space that is automatically backed up nightly for redundancy.  Optionally, it can also be outfitted as a [Plex Media Server](https://www.plex.tv/).

Also installed are: 
- pifi-backup: a command to allow manually backing up your PiFi at any time.
- pifi-adduser: a convenient counterpart to linux’s adduser command, which can be used to quickly allot and enable private drive space for new users. 
- msmtp: so that automated email notifications can be sent out that summarize nightly backups, as well as report system faults.

Optionally you can also install Plex via the *plex-setup.sh* script, if you want to make PiFi into a Plex server as well. 

Why build your own Pi-based NAS?  Because it’s awesome!  

### Requirements

- **A Raspberry Pi, running Raspian Jessie**.
<br/>
Here are the final Jessie releases of [Raspbian](http://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/) and [Raspbian Lite](https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2017-07-05/). 
Other combinations of Raspbian and Pi might work (or even other hardware running another Debian variant), but samba private shares will need custom configuration after Jessie, since Raspbian Stretch drops support for libpam-smbpass, and the Plex install was not tested with versions earlier than Jessie.  

- **Two NTFS formatted USB hard drives.**
<br/>Other HDD Filesystems will work as well, but would require altering the portion of the script that installs ntfs-3g and creates mounting entries in fstab. Also lost would be the convenience of interoperation with windows systems when a drive is taken on the road, which was deemed a priority. 


### Installation

1. Configure your Pi with a Raspian image
   - http://www.raspberrypi.org/downloads/
2. Download and execute the pifi-setup script
   - wget https://raw.githubusercontent.com/NetsydeMiro/pifi/master/pifi-setup.sh
   - sudo bash pifi-setup.sh
3. You will be prompted for a few pieces of information
   - Windows Workgroup
   - Notification sender email and password
     - The email from which notifications will be sent.
     - Configured to use a gmail address by default, but this can be customized (see defaults and customization, below)
   - Notification receiver email
     - The email to which notifications are sent (can differ from the sender). 
4. Allow the script to finish executing (this will take a few minutes).  
   - Congrats, you’ve got yourself a PiFi! 
5. (Optional)  Download and execute the Plex Server script. 
   - wget https://raw.githubusercontent.com/NetsydeMiro/pifi/master/plex-setup.sh
   - sudo bash plex-setup.sh


### Defaults and Customization

The following were deemed "sane" defaults, but can easily be altered in the script either by hardcoding the desired values, or commenting out the defaults and uncommenting their corresponding input prompts

- Server Name. Default: pifi
- Notification Server. Default: gmail (smtp.gmail.com)
- Notifcation Server Port. Default: 587
- Backup Start Hour. Default: 2am

### Features

After installation your pifi is: 

- A Samba Server.  Its public folder should show up on any windows machine that connects to your router.  
- A DLNA Server.  Any audio, video, or pictures in their respective public folders will be parsed and available for any DLNA enabled client connected to your network. 

It also: 

- Runs nightly backups via an rsync cronjob.
  - It copies any new and/or modified files from the primary drive to the auxiliary.  
  - Deleted files on the primary are NOT deleted from the auxiliary, so that they are still available in case of accidental deletion. 
- Notifies you via email to summarize nightly backups and to inform you of any possible system faults.
- Can execute a manual backup at any time
  - sudo pifi-backup
- Can be easily expanded to allow for more users.
  - sudo pifi-adduser newusername
- Is totally awesome and typically fulfills a portion of your daily nerd and/or hacker quota.

Here is the resultant directory setup for a PiFi NAS that’s had two users subsequently created via pifi-adduser (jon and jane).

    /home
    |-- jon  -> /media/pri/shares/jon
    |-- jane -> /media/pri/shares/jane
    `-- pi
        |-- .bashrc, .profile, and other default pi files
        `-- rest of pi's files...
    /media
    |-- pri (hdd1, the primary drive mount point)
    |   `-- shares
    |       |-- jon 
    |       |   |-- .bashrc, .profile, and other adduser skeleton files
    |       |   `-- rest of jon's files
    |       |-- jane
    |       |   |-- .bashrc, .profile, and other adduser skeleton files
    |       |   `-- rest of jane's files
    |       `-- public
    |           |-- audio
    |           |-- video
    |           `-- pictures
    |   
    `-- aux (hdd2, the auxiliary drive mount point)
        `-- shares (rsynced from the primary each night)
            |-- jon 
            |-- jane
            `-- public
    /usr
    `-- local
        `-- sbin
            |-- pifi-backup 
            `-- pifi-adduser


### One Drawback

It’s a bit slow.

- File transfer speeds appear to max out at under 2 MB/s, even for internal copies between attached HDDs.  The bottleneck is likely the Pi’s USB transfer speed or its execution of the ntfs-3g driver.  
- This might be addressed by using disks formatted with an ext filesystem (or another linux-performant variant), or by using a server that has a bit more muscle than a Pi.  Most if not all of the setup script would likely work on any Debian variant. 

I've found the server performs very well for all file and media serving functions I've put it through.  Only when writing large files to it will you notice slowdowns, but for seeding the drives with large amounts of data you'd probably want to connect them directly via USB to a computer anyway.  

### And a Couple Cautions

The private file shares are not fully secure

- Because of NTFS file system limitations when mounted in a Linux system, all private user shares are actually accessible to anyone who knows how to ssh into the system and navigate a linux system.  
- This might be addressed by using disks formatted with an ext filesystem (or another linux permission compatible variant), but we would lose the convenience of being able to easily interoperate with windows systems when taking a drive on the road. 

The notification sender password is stored in clear text.

- In msmtp’s config file: /etc/msmtprc
- This is only r/w accessible to the root user however, so it’s about as secure as using a tool such as gpg to encode it. You may still want to setup a free dummy email account specifically for use with your pifi so that there’s no risk of sensitive information being jeopardized. 
