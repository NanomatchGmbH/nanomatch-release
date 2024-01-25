#!/bin/bash


SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && (pwd -W 2> /dev/null || pwd))
ENVDIR="$SCRIPT_DIR/../environments"
RELDIR="$SCRIPT_DIR/../releases"

conda-lock --micromamba -f $ENVDIR/simstackserver.yml -p linux-64 --lockfile $RELDIR/simstackserver.conda-lock.yml
