#!/bin/bash

source ~/package_functions.sh

runDry

printf "\nStarting...\n"
waitASec

verifyVersionAndNotes

format

runtests

publish

createGitRelease

printf "\nDone!\n"
