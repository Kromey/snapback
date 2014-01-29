#!/bin/bash
# ----------------------------------------------------------------------
# Snapshot rotation script
# ----------------------------------------------------------------------
# Based upon the excellent article by Mike Rubel
#  http://www.mikerubel.org/computers/rsync_snapshots/
# Modified and updated by Travis Veazey
# ----------------------------------------------------------------------
# This script rotates previous snapshots made by make_snapshot.sh.
# ----------------------------------------------------------------------
# Arguments:
#  -s	Snapshot path
#  -y	Snapshot to sync from
#  -l Snapshot level (e.g. hourly, daily, etc.) to create
#  -r Retention: how many snapshots of this level to retain

###### Prevent accidentally using the system path ######
unset PATH

###### Commands used by this script ######
ID=/usr/bin/id;
ECHO=/bin/echo;

RM=/bin/rm;
MV=/bin/mv;
CP=/bin/cp;
TOUCH=/bin/touch;

###### File locations ######
SNAPSHOT=;

###### Variables used in this script ######
LEVEL=;
RETAIN=;
SYNC=;
USAGE="Usage: $0 -s snapshot_dir -y sync_from -l snapshot_level -r snapshot_retention";

#if (( $# != 4 )); then { $ECHO $USAGE; exit; } fi

while getopts ":s:y:l:r:" options; do
	case $options in
		s ) SNAPSHOT=$OPTARG;;
		y ) SYNC=$OPTARG;;
		l ) LEVEL=$OPTARG;;
		r ) RETAIN=$OPTARG;;
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

if [[ -z $SNAPSHOT ]] || [[ -z $RETAIN ]] || [[ -z $LEVEL ]] || [[ -z $SYNC ]]
then
	$ECHO $USAGE
	exit 1
fi

###### Make sure we're running as root ######
if (( `$ID -u` != 0 )); then { $ECHO "Sorry, must be root.  Exiting..."; exit; } fi

###### Rotating snapshots of $FILES ######

###### Step 1: delete the oldest snapshot, if it exists: ######
CUR_SNAPSHOT=$(($RETAIN - 1));
if [ -d $SNAPSHOT/$LEVEL.$CUR_SNAPSHOT ] ; then			\
$RM -rf $SNAPSHOT/$LEVEL.$CUR_SNAPSHOT ;				\
fi ;

###### Step 2: rotate the middle snapshot(s), if it exists: ######
for((CUR_SNAPSHOT; CUR_SNAPSHOT >= 0; CUR_SNAPSHOT--))
do
	if [ -d $SNAPSHOT/$LEVEL.$CUR_SNAPSHOT ] ; then			\
	$MV $SNAPSHOT/$LEVEL.$CUR_SNAPSHOT $SNAPSHOT/$LEVEL.$(($CUR_SNAPSHOT+1)) ;	\
	fi;
done

###### Step 3: make a hard-link-only copy of the sync target: ######
if [ -d $SNAPSHOT/$SYNC ] ; then			\
$CP -al $SNAPSHOT/$SYNC $SNAPSHOT/$LEVEL.0 ;
fi ;

###### Step 4: update the mtime of $LEVEL.0 to reflect the snapshot time ######
if [ -d $SNAPSHOT/$LEVEL.0 ] ; then			\
$TOUCH $SNAPSHOT/$LEVEL.0 ;
fi ;

