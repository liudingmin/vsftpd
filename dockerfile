FROM alpine:3.19.1
LABEL author="Dingmin Liu"
LABEL version="1.1-alpine3"
LABEL date="2024-05-16"
LABEL Description="vsftpd Docker image based on alpine 3.19.1. Supports passive mode. Inspired from fauria/vsftpd."
LABEL Usage="docker run -d -v /appdata/vsftpd/ftpdata:/appdata/ftpdata -v /appdata/vsftpd/log/:/var/log/vsftpd/\
-p 20:20 -p 21:21 -p 20000-20009:20000-20009 -e FTP_USER=myuser (-e FTP_GROUP=myuser) \
-e FTP_PASS=mypass (-e PASV_ENABLE=[YES]) -e PASV_ADDRESS=<external IP address> \
-e PASV_MIN_PORT=20000 -e PASV_MAX_PORT=20009 (-e XFERLOG_ENABLE=[NO])\
--name vsftpd --restart=always liudingmin/vsftpd:1.1-alpine3"
RUN apk update
RUN apk add vsftpd vim procps shadow tzdata && apk cache clean
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo 'Asia/Shanghai' >/etc/timezone
ENV USER_ID=1000
ENV GROUP_ID=1000
ENV FTP_USER=**String**
ENV FTP_GROUP=**String**
ENV FTP_PASS=**Random**
ENV PASV_ADDRESS=**IPv4**
ENV PASV_ENABLE=YES
ENV PASV_ADDR_RESOLVE=NO
ENV PASV_MIN_PORT=20000
ENV PASV_MAX_PORT=20009
ENV XFERLOG_STD_FORMAT=YES
ENV FILE_OPEN_MODE=0777
ENV LOCAL_UMASK=027
ENV PASV_PROMISCUOUS=NO
ENV PORT_PROMISCUOUS=NO
ENV XFERLOG_ENABLE=**NO**
COPY vsftpd.conf /etc/vsftpd/
COPY run-vsftpd.sh /usr/sbin/
RUN chmod +x /usr/sbin/run-vsftpd.sh
RUN mkdir -p /appdata/
VOLUME ["/appdata/ftpdata"]
VOLUME ["/var/log/vsftpd"]
EXPOSE 20 21 ${PASV_MIN_PORT}-${PASV_MAX_PORT}
ENTRYPOINT ["/usr/sbin/run-vsftpd.sh"]