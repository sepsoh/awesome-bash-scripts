#!/bin/bash
# See More github.com/sepsoh/awesome-bash-scripts


if [ -z ${1} ]; then
    echo -e "Enter the input file path !"
else
    curl -F "file=@$1" 0x0.st
fi
