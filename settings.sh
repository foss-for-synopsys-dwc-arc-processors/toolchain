#!/bin/sh

#Depending of the OS pick the right tools
export UNAME=uname
export SED=sed
if [ "`uname -s`" == "Darwin" ]; then
  #guname and gsed is included as part of coreutils and gnu-sed respectively, you can install it with homebrew
  #brew install coreutils gnu-sed
  export UNAME=guname
  export SED=gsed
fi
