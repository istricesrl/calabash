# calabash
this is a simple Bash script collection to make some Debian (and a little Ubuntu) administration task more easy :)

## disclaimer
this document is still a work in progress, please be patient and check the comments in the scripts for more info

## installation
just clone or download the repository and merge the `usr` folder from the repository with the `usr` folder on your Linux box

### installation from github

You can manually launch these commands to install the Calabash script collection:

    apt-get update && apt-get upgrade
    apt-get install wget unzip
    wget https://github.com/istricesrl/calabash/archive/refs/heads/master.zip
    unzip -qq ./master.zip
    cp -R ./calabash-master/* /
    rm -rf ./master.zip
    rm -rf ./calabash-master

Or if you want you can just download the va.script.upgrade.sh scritp and let it do all the work for you:

    wget https://calabash.videoarts.eu/install.sh && chmod +x ./install.sh && ./install.sh

after doing so, Calabash will be available on your system without needing to take any further steps.

## config files
calabash uses a few config file to keep important informations at hand, these are usually located in /etc and
here are a short description for each one

### /etc/mysql.conf
if you install the MySQL/MariaDb server fron the `va.lamp.setup.sh` script, this file will be created with the
connection data needed for other `va.mysql.*` scripts to run; the file format is the one needed for use with the
`--defaults-file` parameter of most MySQL tools

## script
as a general rule, the scripts of this collection, if launched without parameters, do nothing but simply print their
own syntax, therefore they can always be launched without parameters safely

when this is not true, it is because the script simply generates such output (for example `va.txt.timestamp.compressed.sh`)
or when the script launches an interactive interface, so that the user can possibly stop the procedure if
he does not want to go on (for example `va.lamp.setup.sh`)

### bak script
these scripts are intended to simplify copy, archive and backup operations

#### va.bak.sh
this script creates a backup copy of a file or a directory

usage:

    va.bak.sh FILE|DIRECTORY [PATH] [REASON]

example:

    va.bak.sh /etc/mysql/my.cnf /var/backups/ pre-tuning

will create `/var/backups/20200703112437-pre-tuning/etc/mysql/my.cnf` if launched on 2020/07/03 11:24:37, preserving
permissions, ownership and timestamps, and will print the destination path on stdout so that the caller can capture it

the timestamp (created via `va.txt.timestamp.compressed.sh`) names the **containing directory**, while the copy keeps the
original file name and, most importantly, its real extension; the second parameter is the base destination and defaults
to `/var/backups`, the third one is an optional reason appended to the timestamp

**why the copy is not left next to the original with the timestamp appended to its name**, as this script used to do: a
great many mechanisms on a Linux box decide what to do with a file by looking at its **final** extension, and a trailing
timestamp hides it. Real cases found on one of our servers: a copy of a maintenance script in `/etc/cron.daily/` was not
executed by run-parts only because its name contained dots; a copy of a script in `/etc/profile.d/` was not sourced by
every shell only because the glob is `*.sh`; a copy of a ModSecurity rules file was not loaded only because the include
is `rules/*.conf`, and duplicate rule IDs would have stopped Apache from starting; and inside an Apache document root the
`FilesMatch` denying `.bak .conf .key .pem .sql` is anchored at the end of the name, so `page.php.bak.20200703112437`
does not match it and gets served in clear text, which means public source code

use `va.disk.file.backup.check.sh` to find copies that do not follow this convention

for the historical behaviour (copy next to the original, timestamp appended to the name) export `VA_BAK_LEGACY=1` before
calling; it is a transitional compatibility switch, do not use it in new scripts

#### va.bak.tar.sh
this script creates a compressed archive from a file or a directory

usage:

    va.bak.tar.sh SOURCE [DEST] [z|j] [quiet]

example:

    va.bak.tar.sh /etc /var/backups/ z quiet

this creates a tar archive compressed with gzip in `/var/backups/etc.20200703112437.tar.gz` if launched on 2020/07/03 11:24:37,
without any output on stdout (quiet mode)

### disk script
these scripts are intended to inspect and tidy up what is stored on disk

#### va.disk.file.backup.check.sh
this script lists the files that look like backup copies left around in the given paths, that is copies whose name hides
the real extension behind a suffix (`sshd_config.20200703112437`, `my.cnf.bak`, `site.conf.old.2`); see `va.bak.sh`
above for why those are a problem and not just untidy

usage:

    va.disk.file.backup.check.sh /PATH [/PATH ...]

it exits 1 when it finds something and 0 when it does not, so it can be used from monit or from a cron script:

    #!/bin/bash
    va.disk.file.backup.check.sh /etc

backups created by system tools (`*.dpkg-old`, `*.ucf-dist`, `passwd-`, `shadow-`, ...) and files shipped by packages
with a legitimate tail (`*.conf.example`, `*.yaml.skeleton`, `exim4.conf.template`, `my.cnf.fallback`) are not reported

### wget script
these are script designed to make it easier to use wget in common tasks

#### va.wget.pages.list.sh
this script creates a simple list of all URLs from a web site; it is useful if you want a map of the site or so

usage:

    va.wget.pages.list.sh URL FILE

example:

    va.wget.pages.list.sh https://some.site.tld /tmp/urlsofsomesite.txt

## Acknowledgments
This project was made possible by the contributions of many people. Since it would be impossible to list them all and I would risk forgetting someone,
I want to thank everyone who, with their work, made this project possible. Thank you all!!!
