#!/bin/bash

# exit whenever a command returns with a non-zero exit code
set -e 
set -o pipefail

# ecto schema migrations
level4 eval "Level4.Release.migrate"

# start application
level4 start
