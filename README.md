# calabash
this is a simple Bash script collection to make some Debian administration task more easy :)

## installation
just clone or download the repository and merge the usr folder from the repository with the usr folder on your Linux box

### installation from web

    apt-get install wget && wget http://calabash.videoarts.it/va.current.tar
    tar -xvf ./va.current.tar --overwrite -C /

## script

### wget script
these are script designed to make it easier to use wget in common tasks

#### va.wget.pages.list.sh
this script creates a simple list of all URLs from a web site; it is useful if you want a map of the site or so

usage:

`va.wget.pages.list.sh sourceSiteAddress listFileWithPath`

example:

`va.wget.pages.list.sh https://some.site.tld /tmp/urlsofsomesite.txt`