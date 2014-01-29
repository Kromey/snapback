snapback
========

An rsync-based tool designed to make lightweight snapshots.

Description
-----------

This tool consists of a pair of scripts that, together, take advantage of hard links to allow a virtually unlimited number of snapshots and essentially any resolution with a minimum of storage space overhead.

`make_snapshot.sh` performs the initial sync, and is the script responsible for updating the files themselves. It is capable of backing up local or remote files, with or without using compression during the transfer operation. `rotate_snapshots.sh` makes the actual snapshots themselves, with a configurable retention policy and variable resolution. Both scripts are designed to be used within a framework of cron jobs to produce your desired backup policy.

Usage
-----

`make_snapshot.sh` should be used first to create/update the backup's copy of your source files. Basic usage is
```
make_snapshot.sh -s source_dir -d destination_dir
```
Additional options available are:
 * -z: Turns compression on (only really useful for over-the-network transfers)
 * -e /path/to/ssh: Provide path to SSH client executable

The `-e` parameter can also be used to supply parameters to your SSH client, for example if you want to supply an SSH key that may be different from your usual default:
```
make_snapshot.sh -e '/usr/bin/ssh -i /path/to/id_rsa' -s user@example.com:source_dir -d dest_dir
```

`rotate_snapshots.sh` should follow, and is used to rotate from the backup copy created by `make_snapshot.sh` into the actual snapshots. The following options are all required:
 * -s Directory for your snapshots
 * -y Snapshot to sync from; if using `make_snapshot.sh`, this should be '.sync'
 * -l Snapshot level (e.g. hourly, daily, weekly)
 * -r Number of snapshots to retain

Note that the value provided in the -l option has no bearing on function, except that that is how the snapshot directories will be named. That is, if -l is "hourly", you would have snapshot directories named hourly.0, hourly.1, etc.

Building a Full Backup Solution
-------------------------------

This is how I back up my file server with 7 days (1 week) of daily snapshots, 4 weeks of weekly snapshots, and 6 months of monthly snapshots, all with virtually no storage overhead beyond that used by the files themselves:

In `/etc/cron.daily`, I have a script that runs these commands:
```
make_snapshot.sh -s /var/smb/ -d /root/snapshots/smb/
rotate_snapshots.sh -s /root/snapshots/smb/ -y .sync -l daily -r 7
```
The first line makes a copy of the SMB share that lives in `/var/smb`, and puts it into `/root/snapshots/smb/.sync/`. The second line produces 7 days of `daily.N` directories in `/root/snapshots/smb/` -- `daily.0` is the most recent, `daily.1` is one day older, etc. As a new snapshot is made, the previous `daily.6` (the 7th snapshot) is removed, and the remaining ones are shifted by one to make room for the new `daily.0`.

To make the weeklies, I simply run this command from a script in `/etc/cron.weekly`:
```
/root/backup_scripts/rotate_snapshots.sh -s /root/snapshots/smb/ -y daily.0 -l weekly -r 4
```
This makes a copy from `daily.0` -- the most recent daily snapshot -- and produces a set of `weekly.N` snapshots, from `weekly.0` up to `weekly.3`.

The monthlies are made in a virtually identical manner, via `/etc/cron.monthly`:
```
/root/backup_scripts/rotate_snapshots.sh -s /root/snapshots/smb/ -y daily.0 -l monthly -r 6
```

I also back up remote systems within this same framework; for my web server, it starts with (again in `/etc/cron.daily`):
```
make_snapshot.sh -z -e '/usr/bin/ssh -i /root/backup/id_rsa' -s backupuser@example.com:/var/www/ -d /root/snapshots/example.com/www/
```
I then follow an identical pattern of `rotate_snapshots.sh` calls as above.

Warning
-------

The snapshots are made lightweight through the use of hard links! This means that, from the perspective of e.g. a text editor, the file `daily.0/sometext.txt` and the file `daily.1/sometext.txt` *are the same file!* Editing one results in the changes being made in the other as well.

The exception is if the file was changed between snapshots; in that case each file is completely separate.

Regardless, it's bad form to modify backups. For this reason I recommend putting strong protections on your snapshots directory to avoid your backups being modified or corrupted in any way (which is why mine above are safely tucked away inside `/root`).

Credits
-------

Credit goes out to [Mike Rubel](http://www.mikerubel.org/computers/rsync_snapshots/) for his excellent article that formed the basis of these scripts. I've taken his methods virtually wholesale, and merely turned his scripts into these general-purpose shell scripts to make it easy to back up new sources with merely a few extra lines in the cron jobs.
