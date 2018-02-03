#/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if [ "true" == "$BTRACE_ENABLED" ] || [ -n "$BTRACE_SCRIPT" ] || [ -n "BTRACE_SCRIPT_URL" ]; then
  plugin-is-active "BTRACE"

  BTRACE_DIR=$DIR/btrace
  #install btrace
  if [ ! -d $BTRACE_DIR ]; then
     wget https://github.com/btraceio/btrace/releases/download/v1.3.9/btrace-bin-1.3.9.tgz -O /tmp/btrace.tgz
     mkdir -p $BTRACE_DIR
     cd $BTRACE_DIR
     tar zxf /tmp/btrace.tgz
     cd -
  fi

  BTRACE_OPTS_VAR=${BTRACE_OPTS_VAR:-JAVA_OPTS}
  export PATH=$PATH:$BTRACE_DIR/bin

  rm  /tmp/btrace.out > /dev/null || true
  touch /tmp/btrace.out
  tail -f /tmp/btrace.out &

  if [ ! -z "$BTRACE_SCRIPT_URL" ]; then
    wget $BTRACE_SCRIPT_URL -O /tmp/btrace.class
    export BTRACE_SCRIPT=/tmp/btrace.class
  fi

  if [ "${BTRACE_SCRIPT:0:1}" != "/" ]; then
     export BTRACE_SCRIPT="$DIR/btrace/$BTRACE_SCRIPT"
  fi

  if [ ! -f "$BTRACE_SCRIPT" ]; then
    echo "ERROR: The defined $BTRACE_SCRIPT does not exist!!!"
    exit -1
  fi

  export RUNTIME_ARGUMENTS="$RUNTIME_ARGUMENTS > /tmp/output.log"
  AGENT_STRING=-javaagent:"$DIR/btrace/build/btrace-agent.jar=$BTRACE_AGENT_ARG,unsafe=true,script=$BTRACE_SCRIPT,scriptOutputFile=/tmp/btrace.out"
  declare -x $BTRACE_OPTS_VAR="$AGENT_STRING $JAVA_OPTS"
  echo "Process is instrumented with setting $BTRACE_OPTS_VAR to $AGENT_STRING"
  echo "Standard output is replaced with btrace output"
fi

call-next-plugin "$@"
