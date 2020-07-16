# calabash
this is a simple Bash script collection to make some Debian administration task more easy :)

## installation
just clone or download the repository and merge the `usr` folder from the repository with the `usr` folder on your Linux box

### installation from web

    apt-get install wget && wget http://calabash.videoarts.it/va.current.tar
    tar -xvf ./va.current.tar --overwrite -C /

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
