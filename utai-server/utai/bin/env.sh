#!/bin/bash

if [ -z "$UTAI_HOME" ]; then
  echo "UTAI_HOME variable is not defined"
  exit 1
fi

CLASSPATH=.:$UTAI_HOME/conf:

LIB_DIR=$UTAI_HOME/lib

appendJarToClassPath() {
  if [ -f $1 ]; then
    if echo $1 | grep .jar > /dev/null; then
      CLASSPATH=$CLASSPATH$1:
    fi
  elif [ -d $1 ]; then
    for file in $1/*
    do
      appendJarToClassPath $file
    done
  fi
}

appendJarToClassPath $LIB_DIR