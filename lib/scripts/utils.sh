#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

# These utils are taken from
# https://github.com/DataDog/datadog-agent-boshrelease/blob/4.11.2/src/helpers/lib.sh

function wait_pid {
  local pidfile=$1
  local pid=$2
  local try_kill=$3
  local timeout=${4:-0}
  local force=${5:-0}
  local countdown=$(( $timeout * 10 ))
  local ps_out="$(ps ax | grep $pid | grep -v grep)"

  if [ -e /proc/$pid -o -n "$ps_out" ]; then
    if [ "$try_kill" = "1" ]; then
      echo "Killing $pidfile: $pid "
      kill $pid
    fi
    while [ -e /proc/$pid ]; do
      sleep 0.1
      [ "$countdown" != '0' -a $(( $countdown % 10 )) = '0' ] && echo -n .
      if [ $timeout -gt 0 ]; then
        if [ $countdown -eq 0 ]; then
          if [ "$force" = "1" ]; then
            echo
            echo "Kill timed out, using kill -9 on $pid ..."
            kill -9 $pid
            sleep 0.5
          fi
          break
        else
          countdown=$(( $countdown - 1 ))
        fi
      fi
    done
    if [ -e /proc/$pid ]; then
      echo "Timed Out"
    else
      echo "Stopped $pid"
    fi
  else
    echo "Process $pid is not running"
  fi
}

function find_pid {
  local find_command=$1
  local pid=$(pgrep -f $find_command)
  echo $pid
}

function wait_pidfile {
  local pidfile=$1
  local try_kill=$2
  local timeout=${3:-0}
  local force=${4:-0}
  local countdown=$(( $timeout * 10 ))

  if [ -f "$pidfile" ]; then
    pid=$(head -1 "$pidfile")
    if [ -z "$pid" ]; then
      die "Unable to get pid from $pidfile"
    fi
    wait_pid $pidfile $pid $try_kill $timeout $force
    rm -f $pidfile
  else
    printf_log "Pidfile $pidfile doesn't exist"
  fi
}

function kill_and_wait {
  local pidfile=$1
  local timeout=${2:-25}
  local force=${3:-1}

  if [ -f "${pidfile}" ]; then
    wait_pidfile $pidfile 1 $timeout $force
  else
    # TODO assume $1 is something to grep from 'ps ax'
    pid="$(ps auwwx | grep "'$1'" | awk '{print $2}')"
    wait_pid $pidfile $pid 1 $timeout $force
  fi
}


function find_pid_kill_and_wait {
  local find_command=$1
  local pidfile=$2
  local pid=$(find_pid $find_command)
  if [[ ! "$pid" || "$pid" == "" ]]; then
    echo "No such PID $pid exists, skipping the hard kill"
  else
    local timeout=${2:-25}
    local force=${3:-1}
    wait_pid $pidfile $pid 1 $timeout $force
  fi
}
