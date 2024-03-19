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

    wget https://github.com/istricesrl/calabash/blob/master/usr/sbin/va.script.upgrade.sh && ./va.script.upgrade.sh

after doing this, you probably want to remove the spare va.script.upgrade.sh from your home directory, since a copy of
the script will be downloaded in /usr/sbin when you complete the install.

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
this script simply creates a copy of a file by adding a timestamp (created via `va.txt.timestamp.compressed.sh`)
to the name to create a backup copy of it

usage:

    va.bak.sh FILE [PATH]

example:

    va.bak.sh file.txt

will create a file named `file.txt.20200703112437` if launched on 2020/07/03 11:24:37; optionally, a second parameter can be
specifified to save the copy in a custom path, otherwise, the copy will be created in the same folder of the original

#### va.bak.tar.sh
this script creates a compressed archive from a file or a directory

usage:

    va.bak.tar.sh SOURCE [DEST] [z|j] [quiet]

example:

    va.bak.tar.sh /etc /var/backups/ z quiet

this creates a tar archive compressed with gzip in `/var/backups/etc.20200703112437.tar.gz` if launched on 2020/07/03 11:24:37,
without any output on stdout (quiet mode)

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
