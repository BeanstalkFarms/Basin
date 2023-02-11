#!/bin/sh

## Usage:
##   . ./export-env.sh ; $COMMAND
##   . ./export-env.sh ; echo ${MINIENTREGA_FECHALIMITE}
##
## Source:
##   https://stackoverflow.com/a/20909045
##   Modified to surpress output of environment to stdout 
###  and to output a message if no .env file present.

if [ ! -f '.env' ]; then

  echo "No .env file found, bypassing loading."
  return 0;

fi

unamestr=$(uname)
if [ "$unamestr" = 'Linux' ]; then

  env $(grep -v '^#' .env | xargs -d '\n') &> /dev/null

elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then

  env $(grep -v '^#' .env | xargs -0) &> /dev/null

fi