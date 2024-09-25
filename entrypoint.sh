#!/bin/bash
set -e


if [ -z "$LD_LIBRARY_PATH" ]; then
  export LD_LIBRARY_PATH=/home/iot_stream/workspace
else
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/iot_stream/workspace
fi

printenv
exec "${@:1}"
