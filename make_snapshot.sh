#!/bin/bash
# ----------------------------------------------------------------------
# Snapshot creation script
# ----------------------------------------------------------------------
# Based upon the excellent article by Mike Rubel
#  http://www.mikerubel.org/computers/rsync_snapshots/
# Modified and updated for my environment by Travis Veazey
# ----------------------------------------------------------------------
# Arguments:
#  -s	Specifies the path to the backup source
#  -d	Specifies the path to the backup destination

###### Prevent accidentally using the system path ######
unset PATH

###### Commands used by this script ######
ID=/usr/bin/id;
ECHO=/bin/echo;

RM=/bin/rm;
MV=/bin/mv;
CP=/bin/cp;
TOUCH=/bin/touch;
MKDIR=/bin/mkdir;

RSYNC=/usr/bin/rsync;
SSH=/usr/bin/ssh;

###### File locations ######
SNAPSHOT=;
FILES=;
EXCLUDES=/root/backup_scripts/backup_exclude;

COMPRESS=;
USAGE="Usage: $0 -s source_dir -d destination_dir";

while getopts "ze:s:d:" options; do
	case $options in
		z ) COMPRESS="-z";;
		e ) SSH=$OPTARG;;
		s ) FILES=$OPTARG;;
		d ) SNAPSHOT=$OPTARG;;
		: ) $ECHO -$OPTARG requires an argument
			$ECHO $USAGE
			exit 1;;
		\? ) $ECHO Invalid option -$OPTARG
			$ECHO $USAGE
			exit 1;;
		* ) $ECHO $USAGE
			exit 1;;
	esac
done

if [[ -z $SNAPSHOT ]] || [[ -z $FILES ]]
then
	$ECHO $USAGE
	exit 1
fi

###### Make sure we're running as root ######
if (( `$ID -u` != 0 )); then { $ECHO "Sorry, must be root.  Exiting..."; exit; } fi

###### Make snapshot of $FILES ######

###### Step 1: rsync from the system into the latest snapshot: ######
$MKDIR -p $SNAPSHOT
$RSYNC $COMPRESS -e "$SSH" -va --delete --delete-excluded --exclude-from="$EXCLUDES" $FILES $SNAPSHOT/.sync ;
	#--link-dest=../hourly.1					\

###### Step 2: update the mtime of the snapshot to reflect the snapshot time ######
if [ -d $SNAPSHOT/.sync ] ; then			\
$TOUCH $SNAPSHOT/.sync ;
fi ;

