#!/bin/bash

if [ -z "${1-}" ]
then
    echo "Please run with intended version name, i.e. nmsci-2024.1.1"
    exit 0
fi

regex="^([a-zA-Z]*)-.*"
if [[ $1 =~ $regex ]]
then
    ymlfile=${BASH_REMATCH[1]}.yml
else
    echo "no referenced environment file found."
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && (pwd -W 2> /dev/null || pwd))
ENVDIR="$SCRIPT_DIR/../environments"
RELDIR="$SCRIPT_DIR/../releases"

conda-lock --micromamba -f $ENVDIR/$ymlfile -p linux-64 --lockfile $RELDIR/$1.conda-lock.yml
