#!/bin/bash

# resolve links - $0 may be a softlink
PRG="$0"

while [[ -h "$PRG" ]] ; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
        PRG=`dirname "$PRG"`/"$link"
  fi
done

PRGDIR=`dirname "$PRG"`

UTAI_HOME=`cd "$PRGDIR/.." >/dev/null; pwd`
export UTAI_HOME

UTAI_DATA_DIR=${UTAI_HOME}/data
if [[ ! -d ${UTAI_DATA_DIR} ]]; then
  mkdir -p ${UTAI_DATA_DIR} >/dev/null
fi

UTAI_PID_FILE=${UTAI_DATA_DIR}/instance.pid
PID=-1

case $1 in
start)
  echo "Starting Utai server..."
  if [[ -f "$UTAI_PID_FILE" ]]; then
          if [[ -s "$UTAI_PID_FILE" ]]; then
            if [[ -r "$UTAI_PID_FILE" ]]; then
                  PID=`cat "$UTAI_PID_FILE"`
                  kill -0 ${PID} >/dev/null 2>&1
                  if [[ $? -eq 0 ]] ; then
                    echo "Utai server appears to still be running with PID $PID, starting aborted."
                    exit 1
                  else
                    rm -f "$UTAI_PID_FILE" >/dev/null 2>&1
                    if [[ $? != 0 ]]; then
                      if [[ -w "$UTAI_PID_FILE" ]]; then
                        cat /dev/null > "$UTAI_PID_FILE"
                      else
                        echo "Unable to remove or clear state PID file, starting aborted."
                        exit 1
                      fi
                    fi
                  fi
            else
                  echo "Unable to read PID file, starting aborted."
                  exit 1
            fi

          else
            rm -f "$UTAI_PID_FILE" >/dev/null 2>&1
            if [[ $? != 0 ]]; then
                  if [[ ! -w "$UTAI_PID_FILE" ]]; then
                    echo "Unable to remove or write to empty PID file, starting aborted."
                    exit 1
                  fi
            fi
          fi
  fi

  ENV=`cd "$PRGDIR" >/dev/null; pwd`/env.sh
  if [[ -r ${ENV} ]]; then
    . ${ENV}
  else
    echo "cannot find env.sh" >&2
        exit 1
  fi

  HOSTNAME=`hostname`
  TIMESTAMP=`date "+%Y%m%d%H%M%S"`

  # create directory ${ATS_HOME}/log/gc if needed
  GC_LOG_DIR=$UTAI_HOME/log/gc
  if [ ! -d "$GC_LOG_DIR" ]; then
    if [ ! -d "$UTAI_HOME/log" ]; then
      mkdir "$UTAI_HOME/log"
    fi
    mkdir "$GC_LOG_DIR"
  fi
  GC_LOG_FILE=$GC_LOG_DIR/`hostname`-$$-`date "+%Y%m%d%H%M%S"`-GC.log
  # For JDK 1.8+
  JVM_OPTS='-server -Xms4096m -Xmx4096m -XX:MaxDirectMemorySize=4096M -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=./"$HOSTNAME"-$$-"$TIMESTAMP".hprof -XX:+PrintGCDateStamps -verbose:gc  -Xloggc:"$GC_LOG_FILE"'
  BOOTSTRAP_CLASS=com.ytbean.utai.bootstrap.UtaiServerBootstrap
  STARTING_STATE_FILE=$UTAI_DATA_DIR/starting.state
  UTAI_CONFIG_FILE=$UTAI_HOME/conf/utai.yaml
  LOGBACK_CONF_FILE=$UTAI_HOME/conf/logback.xml
  JAVACMD=java

  touch $STARTING_STATE_FILE

  eval \"$JAVACMD\" -classpath \"$CLASSPATH\" \
        -DUTAI_HOME=\"$UTAI_HOME\" \
        -Dstarting.state.file=\"$STARTING_STATE_FILE\" \
        -Dutai.config.file=\"$UTAI_CONFIG_FILE\" \
        -Dlogging.path=\"$UTAI_HOME/log\" \
        -Dlogback.configurationFile=\"$LOGBACK_CONF_FILE\" \
        $JVM_OPTS \
        $BOOTSTRAP_CLASS \
        $ClASS_ARGS "&"

  if [ ! -z "$UTAI_PID_FILE" ]; then
    echo $! > "$UTAI_PID_FILE"
  fi

  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
    do
          sleep 6
          if [ ! -f "$STARTING_STATE_FILE" ]; then
            break
          fi
        done

  sleep 3

  if [ -f "$UTAI_PID_FILE" ]; then
    if [ -s "$UTAI_PID_FILE" ]; then
      if [ -r "$UTAI_PID_FILE" ]; then
        PID=`cat "$UTAI_PID_FILE"`
        kill -0 $PID >/dev/null 2>&1
        if [ $? -eq 0 ] ; then
          echo "Utai server started!"
              echo "========================================"
              echo `date`
          echo "========================================"
              exit 0
            fi
          fi
        fi
  fi
  ;;
stop)
  if [ -f "$UTAI_PID_FILE" ]; then
    if [ -s "$UTAI_PID_FILE" ]; then
      if [ -r "$UTAI_PID_FILE" ]; then
        PID=`cat "$UTAI_PID_FILE"`
        kill -0 $PID >/dev/null 2>&1
        if [ $? != 0 ] ; then
          echo "Utai server is not running"
          exit 0
        fi
      fi
    else
      echo "Pid file is existed but Utai server is not running"
      exit 0
    fi

    rm "$UTAI_PID_FILE"
  else
    echo "Utai server is not running"
  	exit 0
  fi

  echo "Stopping Utai server..."

  # try gracefully kill
  kill -0 $PID >/dev/null 2>&1
  if [ $? -eq 0 ] ; then
	  kill -15 $PID
  fi

  # linux or solaris
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60
  do
    kill -0 $PID >/dev/null 2>&1
    if [ $? != 0 ] ; then
      break
    fi
    echo .......
    sleep 1
  done
  # force kill
  kill -0 $PID >/dev/null 2>&1
  if [ $? -eq 0 ] ; then
        kill -9 $PID
  fi

  echo "Utai server stopped!"
  ;;
restart)
  shift
  "$0" stop ${@}
  sleep 3
  "$0" start ${@}
  ;;
status)
  if [ -f "$UTAI_PID_FILE" ]; then
    if [ -s "$UTAI_PID_FILE" ]; then
      if [ -r "$UTAI_PID_FILE" ]; then
        PID=`cat "$UTAI_PID_FILE"`
        kill -0 $PID >/dev/null 2>&1
        if [ $? != 0 ] ; then
          echo "Utai server is not running"
          exit 0
        else
          echo "Utai server is running with pid $PID"
          exit 0
        fi
      fi
    fi
  fi
  echo "Utai server is not running"
  exit 0
  ;;
*)
  echo "Usage: $0 {start | stop | restart | status}" >&2
esac