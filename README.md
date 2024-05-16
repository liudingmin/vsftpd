# vsftpd-alpine3
An vsftpd image based on Alpine 3.
# Introduction
Basically this image has almost the same function as fauria/vsftpd, but there are two differences. Firstly, I use system users instead of virtual users for login authentication. Users with same group has the same home ftp directory (groupname), and they have the same permissions in this directory. Secondly, I use alpine:3 as base image, which could reduce the image size a lot. (Only 42MB!) 
# An usage example
docker run -d -v /appdata/vsftpd/ftpdata:/appdata/ftpdata -v /appdata/vsftpd/log/:/var/log/vsftpd/ \
-p 20:20 -p 21:21 -p 20000-20009:20000-20009 -e FTP_USER=myuser (-e FTP_GROUP=myuser) \
-e FTP_PASS=mypass (-e PASV_ENABLE=[YES]) (-e PASV_ADDRESS=external IP address) \
-e PASV_MIN_PORT=20000 -e PASV_MAX_PORT=20009 (-e XFERLOG_ENABLE=[NO]) \
--name vsftpd --restart=always aprilthevine/vsftpd:1.1
