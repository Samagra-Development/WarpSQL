#!/bin/bash
# 
set -ex

# Find all test script files in the directory
test_scripts=$(find ./test_extentions -type f -name 'test_*.sh')

# If no extensions provided, run all test scripts
if [[ -z $1 ]]; then
    for script in $test_scripts; do
        bash "$script"
    done
else
IFS=',' read -ra EXTENSION_LIST <<< "$1"
    for extension in "${EXTENSION_LIST[@]}"; do
        test_script="./test_extentions/test_${extension}.sh"
        if [[ -f "$test_script" ]]; then
            bash "$test_script"
        else
            echo "Test script for '$extension' not found."
        fi
    done 
fi