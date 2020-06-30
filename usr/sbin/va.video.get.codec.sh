#!/bin/bash

# leggo il codec
mediainfo --Inform="Video;%Codec%" $1
