#!/bin/sh

clear

echo
echo 'This script will crash if you do not have graphviz for python and firefox installed!!'
echo

echo 'Generate temporary dot file...'
python ./valamap.py ../src/xnoise > ./valamap.dot
echo 'Done'
echo

echo 'Create graph...'
dot ./valamap.dot -Tsvg -o ./valamap.svg
echo 'Done'
echo

echo 'Open svg picture of graph with firefox...'
firefox ./valamap.svg &
echo 'Done'
echo

echo 'Delete temporary dot file...'
rm -f ./valamap.dot &
echo 'Done'
echo

