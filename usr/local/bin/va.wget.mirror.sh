#!/bin/bash

# UTILIZZO
# scarica un sito per la navigazione offline

wget --mirror --convert-links --adjust-extension --page-requisites --no-parent $1

# NOTE
# --mirror		Makes (among other things) the download recursive.
# --convert-links	convert all the links (also to stuff like CSS stylesheets) to relative, so it will be suitable for offline viewing.
# --adjust-extension	Adds suitable extensions to filenames (html or css) depending on their content-type.
# --page-requisites	Download things like CSS style-sheets and images required to properly display the page offline.
# --no-parent		When recursing do not ascend to the parent directory. It useful for restricting the download to only a portion of the site.
