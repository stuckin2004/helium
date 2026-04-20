#!/usr/bin/env bash

set -e pipefail

FAILS=0

if ! command -v clang++ > /dev/null 2>&1; then
  echo "clang++ is missing, please install!"
  FAILS=$FAILS+1
else
  echo "clang++ OK!"
fi

if ! command -v make --version > /dev/null 2>&1; then
  echo "make is missing, please install!"
  FAILS=$FAILS+1
else
  echo "make OK!"
fi

if ! command -v xorriso --version > /dev/null 2>&1; then
  echo "xorriso is missing, please install!"
  FAILS=$FAILS+1
else
  echo "xorriso OK!"
fi

if [ $FAILS -gt 0 ]; then
  echo "tools are missing, please install/build these with your package manager!"
  exit 1
else
  echo "tools look OK, good to build!"
fi
