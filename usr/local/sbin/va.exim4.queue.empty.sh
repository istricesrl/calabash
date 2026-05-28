#!/bin/bash

logger "$0"

exim -bp | exiqgrep -i | xargs exim -Mrm
