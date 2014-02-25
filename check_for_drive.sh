#!/bin/bash
#TODO: Document; make parameters configurable

STATUS=0

while read line; do
	if [ -a "/dev/disk/by-id/$line" ]
	then
		STATUS=1
		break
	fi
done < /root/backup_scripts/disk_ids.txt

/usr/bin/zabbix_sender -z 127.0.0.1 -s Odin -k extern.connected[backup] -o $STATUS > /dev/null
