#!/bin/bash# 

# Exit if any of the intermediate steps fail
set -e
# Extrat argument
eval "$(jq -r '@sh "KEY=\(.key) COMMAND=\(.command)"')"
# Create JSON ouput
result=$(eval $COMMAND)
jq -n --arg value "$result" '{ '$KEY':$value }'