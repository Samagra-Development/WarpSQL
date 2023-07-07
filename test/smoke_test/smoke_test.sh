#!/bin/bash
# 
set -ex
# get the base dir of the script 
scriptDir=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
echo $scriptDir/extentions_test
# Find all test script files in the directory
test_scripts=$(find $scriptDir/extentions_test -type f -name 'test_*.sh')

# If no extensions provided, run all test scripts
if [[ -z $1 ]]; then
    for script in $test_scripts; do
        bash "$script"
    done
else
IFS=',' read -ra EXTENSION_LIST <<< "$1"
    for extension in "${EXTENSION_LIST[@]}"; do
        test_script="$scriptDir/extentions_test/test_${extension}.sh"
        if [[ -f "$test_script" ]]; then
            bash "$test_script"
        else
            echo "Test script for '$extension' not found."
        fi
    done 
fi