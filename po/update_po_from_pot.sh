#!/bin/bash
# This script can be used to manually update po files from a pot file

if [ -f ./xnoise.pot ] ; then
    echo "found pot file!"
else
    echo "no pot file found"
    exit 1
fi

for file in ./*.po ; do
    msgmerge -U $file xnoise.pot
done
