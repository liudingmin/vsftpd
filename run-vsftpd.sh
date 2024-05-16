#!/bin/sh


export Version="1.1-alpine3"
export Date="2024-05-16"

# Function to receive SIGTERM
function cleanup {
    echo "· Received stop signal, stopping vsftpd..."
    ps -ef|grep /usr/sbin/vsftpd|grep -v grep|awk '{print $2}'|xargs -I {} kill -15 {}
    exit 0
}

# Receive SIGTERM
trap cleanup TERM INT

# Initialization
if [ ! -d "/etc/vsftpd/userconfig" ]; then

	# If no env var for FTP_USER has been specified, use 'ftpuser':
	if [ "$FTP_USER" = "**String**" ]; then
		export FTP_USER='ftpuser'
	fi

	#If no env var for FTP_GROUP has been specified,use groupname same as username:
	if [ "$FTP_GROUP" = "**String**" ]; then
		export FTP_GROUP=$FTP_USER
	fi

	# If no env var has been specified, generate a random password for FTP_USER:
	if [ "$FTP_PASS" = "**Random**" ]; then
		export FTP_PASS=`cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -c${1:-10}`
	fi

	if [ "$XFERLOG_ENABLE" != "**NO**" ]; then
		export XFERLOG_ENABLE='YES'
	else
		export XFERLOG_ENABLE='NO'
	fi

	# Create home dir and update vsftpd user db:
	groupadd -g $GROUP_ID $FTP_GROUP
	mkdir "/home/${FTP_USER}"
	useradd -u $USER_ID -g $GROUP_ID $FTP_USER
	echo "${FTP_USER}:${FTP_PASS}" | chpasswd
	mkdir -p "/appdata/ftpdata/${FTP_GROUP}"
	chmod 777 "/appdata/ftpdata/"
	chown -R "${FTP_USER}:${FTP_GROUP}" "/appdata/ftpdata/${FTP_GROUP}"
	chown -R "${FTP_USER}:${FTP_GROUP}" "/home/${FTP_USER}"
	chmod 770 "/appdata/ftpdata/${FTP_GROUP}"

	# Set passive mode parameters:
	if [ "$PASV_ENABLE" != "YES" ]; then
		export PASV_ENABLE = "NO"
	fi

	if [ "$PASV_ADDRESS" = "**IPv4**" ]; then
		export PASV_ADDRESS=$(/sbin/ip route|awk '/default/ { print $3 }')
	fi

	echo "userlist_enable=YES" >> /etc/vsftpd/vsftpd.conf # use user_list
	echo "userlist_deny=YES" >> /etc/vsftpd/vsftpd.conf # set user_list as blacklist
	echo "user_config_dir=/etc/vsftpd/userconfig" >> /etc/vsftpd/vsftpd.conf
	mkdir "/etc/vsftpd/userconfig"
	echo "local_root=/appdata/ftpdata/${FTP_GROUP}" >> "/etc/vsftpd/userconfig/${FTP_USER}"
	echo "pasv_enable=${PASV_ENABLE}" >> /etc/vsftpd/vsftpd.conf
	echo "pasv_address=${PASV_ADDRESS}" >> /etc/vsftpd/vsftpd.conf
	echo "pasv_max_port=${PASV_MAX_PORT}" >> /etc/vsftpd/vsftpd.conf
	echo "pasv_min_port=${PASV_MIN_PORT}" >> /etc/vsftpd/vsftpd.conf
	echo "pasv_addr_resolve=${PASV_ADDR_RESOLVE}" >> /etc/vsftpd/vsftpd.conf
	echo "file_open_mode=${FILE_OPEN_MODE}" >> /etc/vsftpd/vsftpd.conf
	echo "local_umask=${LOCAL_UMASK}" >> /etc/vsftpd/vsftpd.conf
	echo "xferlog_enable=${XFERLOG_ENABLE}" >> /etc/vsftpd/vsftpd.conf
	echo "xferlog_std_format=${XFERLOG_STD_FORMAT}" >> /etc/vsftpd/vsftpd.conf
	echo "pasv_promiscuous=${PASV_PROMISCUOUS}" >> /etc/vsftpd/vsftpd.conf
	echo "port_promiscuous=${PORT_PROMISCUOUS}" >> /etc/vsftpd/vsftpd.conf
	cat > /etc/vsftpd/user_list <<-EOF 
	root
	bin
	daemon
	adm
	lp
	sync
	shutdown
	halt
	mail
	news
	uucp
	operator
	man
	postmaster
	cron
	ftp
	sshd
	at
	squid
	xfs
	games
	cyrus
	vpopmail
	ntp
	smmsp
	guest
	nobody
	vsftp
	EOF

	cp /etc/vsftpd/user_list /etc/vsftpd/ftpusers
	ln -s /etc/vsftpd/user_list /etc/vsftpd.user_list
fi

FTP_ALL_USER=$(ls /etc/vsftpd/userconfig | tr '\n' ' ')
starttime=$(date|awk '{print $6,$2,$3,$4}')


cat << EOB
*************************************************
*                                               *
*       Docker image: liudingmin/vsftpd         *
*            Version: "${Version}"             *
*              Date: "${Date}"               *
*                                               *
*************************************************

SERVER SETTINGS
---------------
. Starttime: $starttime
· FTP User: $FTP_ALL_USER
· FTP Password: Secret!
· VSFTPD Log file: /var/log/vsftpd/vsftpd.log
EOB

if [ "$XFERLOG_ENABLE" != "**NO**" ]; then
	echo "· XFERLOG file: /var/log/vsftpd/vsftpd.log" >> /dev/stdout
fi

# Start vsftpd service
/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf &

# Wait vsftpd service till stop
wait $!