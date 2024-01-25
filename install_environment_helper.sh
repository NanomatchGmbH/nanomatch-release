#!/bin/bash

function execute {
    echo "Executing $1"
}

function targetver {
    regex='^([a-zA-Z]*-[0-9]*\.[0-9]*)\S*'
    if [[ $1 =~ $regex ]]
    then
        echo ${BASH_REMATCH[1]}
    fi
}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && (pwd -W 2> /dev/null || pwd))
ENVDIR="$SCRIPT_DIR/releases"
OFFLINEDIR="$SCRIPT_DIR/offline_releases"
mkdir -p $OFFLINEDIR

echo "Nanomatch release installer helper."
echo "List of available environments:"
echo 
for env in $(find $OFFLINEDIR -name "*.conda-lock.yml" | sort -r )
do
    envname=$(basename $env .conda-lock.yml)
    target=$(targetver $envname)

    echo " --- $envname ---"
    echo "  Offline environment: $envname to be installed to target env: $target"
    echo "  To install this environment run:"
    echo "  micromamba create --name=$target -f $env"
    echo
done

for env in $(find $ENVDIR -name "*.conda-lock.yml" | sort -r )
do
    envname=$(basename $env .conda-lock.yml)
    target=$(targetver $envname)

    echo " --- $envname ---"
    echo "  Environment: $envname to be installed to target env: $target"
    echo "  To install this environment run:"
    echo "  micromamba create --name=$target -f $env"
    echo
done
