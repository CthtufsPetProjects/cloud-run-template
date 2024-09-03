#!/usr/bin/env bash

#set -o errexit
#set -o nounset
set +x

default_cmd="uvicorn service.main:app --host 0.0.0.0 --port 8080"

cmd="${*:-$default_cmd}"

exec $cmd
