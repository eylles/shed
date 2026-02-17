#!/bin/sh

# version @VERSION@
prog_v="@VERSION@"

# dir for the pid files
# GUI_SESSION_PID=$$ must be exported in the xinitrc/xsession file
# to have the pid of the running graphical session
GUISessionDir=${XDG_RUNTIME_DIR}/GUISession${GUI_SESSION_PID}

# directory where we are loading the user services to start from
ServicesDir="${XDG_CONFIG_HOME:-${HOME}/.config}/shed/services"

# defined as: ${XDG_RUNTIME_DIR}/GUISession${GUI_SESSION_PID}/socket
msg_socket="${GUISessionDir}/socket"
# defined as: ${XDG_RUNTIME_DIR}/GUISession${GUI_SESSION_PID}/reply
msg_reply="${GUISessionDir}/reply"

# unix command line compatible booleans

# Type: int
# value: 0
_true=0
# Type: int
# value: 1
_false=1

# Return type: void
#       Usage: serv_start service_name nosock nodelay
#         nosock: if the nosock arg is set then
#                 no message is sent to the reply socket
#                 passing 1 will set no sock mode
#        nodelay: if the nodelay arg is set then
#                 no delay is applied to starting the
#                 service passing 1 will set no delay mode
# --------------------------------------------------
# this function is not expected to have a return value as
# all messages are sent to the reply socket unless specified
serv_start() {
  # clean up environment
  NSck=""
  NAME=""
  EXEC=""
  E_ARGS=""
  DELAY=""
  if [ ! "${2}" = 1 ]; then
    NSck=0
  else
    NSck="${2}"
  fi
  if [ ! "${3}" = 1 ]; then
    NDlay=0
  else
    NDlay="${3}"
  fi
  s_file="$1"
  # source the file to get the variables: NAME EXEC E_ARGS from the service
  . "$s_file"
  # check if service is already running
  if [ -f "${GUISessionDir}/${NAME}.pid" ]; then
    start_date=$(date '+%Y-%m-%d-%H:%M:%S')
    printf '%s\n' "$NAME $start_date running" >> "$msg_reply"
  else
    # needed for services that got $HOME/path/service in their EXEC def
    EXEC=$(printf '%s\n' "$EXEC" | sed "s@\$HOME@$HOME@")
    # get the full path of the binary
    EXEC=$(command -v "$EXEC")
    if [ -n "$DELAY" ] && [ "$NDlay" = 0 ]; then
      sleep "$DELAY"
    fi
    # run the service command with the arguments
    s_run="exec $EXEC $E_ARGS"
    eval "$s_run" &
    # catch the pid of the process
    proc_pid=$!
    # start date
    start_date=$(date '+%Y-%m-%d-%H:%M:%S')
    # write the pid of the process to the pid file
    printf '%s\n' "$proc_pid" > "${GUISessionDir}/${NAME}.pid"
    [ -z "$NSck" ] && printf '%s\n' "$NAME $start_date started" >> "$msg_reply"
  fi
}

# Return type: void
#       Usage: start_services all | firstrun | <service name>
#            all: start all services
#       firstrun: start all services on first run mode
# <service name>: the service name to start
# --------------------------------------------------
# only one argument is acknowledged.
# this function is not expected to have a return value.
start_services() {
  # start date
  start_date=$(date '+%Y-%m-%d-%H:%M:%S')
  printf '%s\n' "$start_date starting services" > "$msg_reply"
  # if all the services should be started
  if [ "all" = "$1" ]; then
    # for every service file in the services dir
    for i in "${ServicesDir}"/* ; do
      serv_start "$i" "0" "1" &
    done
  elif [ "firstrun" = "$1" ]; then
    # for every service file in the services dir
    for i in "${ServicesDir}"/* ; do
      serv_start "$i" "1" &
    done
  else
    for i in "${ServicesDir}"/* ; do
      ServiceFileName=$(basename "$i")
      if [ "$ServiceFileName" = "$1" ]; then
        serv_start "$i" "0" "1" &
      fi
    done
  fi
}

# Return type: string
#       Usage: readserviceprop "PROPERTY" service_file
#       property: key name
#      Return: string containing the value of the
#                 PROPERTY key from the passed file.
# --------------------------------------------------
# the service files store properties as key=value
# pairs, pass the name of the key to get the stored
# value, valid key names are:
#     NAME
#     EXEC
#     E_ARGS
#     DELAY
#     NOHUP
readserviceprop(){
  # Setting 'IFS' tells 'read' where to split the string.
  while IFS='=' read -r key val; do
    # Skip over lines containing comments.
    # (Lines starting with '#').
    [ "${key##\#*}" ] || continue

    # '$key' stores the key.
    # '$val' stores the value.
    if [ "$key" = "$1" ]; then
    printf '%s\n' "$val"
    fi
  done < "$2"
}

# Return type: string
#       Usage: read_file file [prefix]
#       [prefix]: if provided the characters here will be used a prefix when
#                 printing the contents of the file.
#      Return: '[prefix]line'
read_file() {
  if [ $# -gt 1 ]; then
    prefix=$2
  else
    prefix=""
  fi
  while read -r FileLine
  do
    printf '%s%s\n' "$prefix" "$FileLine"
  done < "$1"
}

# Return type: void
#       Usage: sig_proc <service name> <signal>
# <service name>: service to send signal
#         signal: term kill hup usr1 usr2
# --------------------------------------------------
# this function is not expected to have a return value as
# all messages are sent to the reply socket
sig_proc() {
  s_file="${ServicesDir}/$1"
  if [ -f "$s_file" ]; then
    sig_use=$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')
    sig_str=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')
    s_name=$(readserviceprop "NAME" "$s_file")
    if [ -f "${GUISessionDir}/${s_name}.pid" ]; then
      s_pid=$(read_file "${GUISessionDir}/${s_name}.pid")
      if kill -0 "$s_pid" 2>/dev/null; then
        printf 'sending %s to %s\t%s\n' \
          "$s_pid" "$sig_str" "$s_name" >> "$msg_reply"
        [ -z "$dry_run" ] && kill "-${sig_use}" "$s_pid"
      fi
    else
      printf 'service %s not running\n' "$s_name" >> "$msg_reply"
    fi
  fi
}

# Return type: void
#       Usage: hupprocs all | <service name>
#            all: hup all services
# <service name>: service to hup
# --------------------------------------------------
# this function is not expected to have a return value as
# all messages are sent to the reply socket
hupprocs() {
  if [ -z "$1" ] || [ "all" = "$1" ]; then
    for i in "${GUISessionDir}"/*.pid ; do
      s_pid=$(read_file "$i")
      # s_name=$(ps -p "$s_pid" -o comm=)
      s_name="${i##*/}"
      printf 'sending hup to %s\t%s\n' "$s_pid" "$s_name" >> "$msg_reply"
      if kill -0 "$s_pid" 2>/dev/null; then
        [ -z "$dry_run" ] && kill -HUP "$s_pid"
      fi
    done
  else
    for i in "${ServicesDir}"/* ; do
      ServiceFileName="${i##*/}"
      if [ "$ServiceFileName" = "$1" ]; then
        s_name=$(readserviceprop "NAME" "$i")
        if [ -f "${GUISessionDir}/${s_name}.pid" ]; then
          s_pid=$(read_file "${GUISessionDir}/${s_name}.pid")
          printf 'sending hup to %s\t%s\n' "$s_pid" "$s_name" >> "$msg_reply"
          if kill -0 "$s_pid" 2>/dev/null; then
          [ -z "$dry_run" ] && kill -HUP "$s_pid"
          fi
        else
          printf 'service %s not running\n' "$s_name" >> "$msg_reply"
        fi
      fi
    done
  fi
}

# Return type: void
#       Usage: killprocs all | <service name>
#            all: kill all services
# <service name>: service to kill
# --------------------------------------------------
# this function is not expected to have a return value as
# all messages are sent to the reply socket
killprocs() {
  if [ -z "$1" ] || [ "all" = "$1" ]; then
    for i in "${GUISessionDir}"/*.pid ; do
      s_pid=$(read_file "$i")
      # s_name=$(ps -p "$s_pid" -o comm=)
      s_name="${i##*/}"
      printf 'sending term to %s\t%s\n' "$s_pid" "$s_name" >> "$msg_reply"
      if kill -0 "$s_pid" 2>/dev/null; then
      [ -z "$dry_run" ] && kill "$s_pid"
      fi
      [ -z "$dry_run" ] && rm -f "$i"
    done
  else
    for i in "${ServicesDir}"/* ; do
      ServiceFileName="${i##*/}"
      if [ "$ServiceFileName" = "$1" ]; then
        s_name=$(readserviceprop "NAME" "$i")
        if [ -f "${GUISessionDir}/${s_name}.pid" ]; then
          s_pid=$(read_file "${GUISessionDir}/${s_name}.pid")
          printf 'sending term to %s\t%s\n' "$s_pid" "$s_name" >> "$msg_reply"
          if kill -0 "$s_pid" 2>/dev/null; then
          [ -z "$dry_run" ] && kill "$s_pid"
          fi
          [ -z "$dry_run" ] && rm -f "${GUISessionDir}/${s_name}.pid"
        else
          printf 'service %s not running\n' "$s_name" >> "$msg_reply"
        fi
      fi
    done
  fi
}

# Return type: string
#       Usage: killchilds all | <service name>
#            all: hup to all services
# <service name>: service to kill
# --------------------------------------------------
# prints to terminal
killchilds() {
  if [ -z "$1" ] || [ "all" = "$1" ]; then
    for i in "${GUISessionDir}"/*.pid ; do
      s_pid=$(read_file "$i")
      # s_name=$(ps -p "$s_pid" -o comm=)
      s_name="${i##*/}"
      printf ' sending term to %s\t%s\n' "$s_pid" "$s_name"
      if kill -0 "$s_pid" 2>/dev/null; then
      [ -z "$dry_run" ] && kill "$s_pid"
      fi
      [ -z "$dry_run" ] && rm -f "$i"
    done
  else
    for i in "${ServicesDir}"/* ; do
      ServiceFileName="${i##*/}"
      if [ "$ServiceFileName" = "$1" ]; then
        s_name=$(readserviceprop "NAME" "$i")
        if [ -f "${GUISessionDir}/${s_name}.pid" ]; then
          s_pid=$(read_file "${GUISessionDir}/${s_name}.pid")
          printf ' sending term to %s\t%s\n' "$s_pid" "$s_name"
          if kill -0 "$s_pid" 2>/dev/null; then
          [ -z "$dry_run" ] && kill "$s_pid"
          fi
          [ -z "$dry_run" ] && rm -f "${GUISessionDir}/${s_name}.pid"
        else
          printf 'service %s not running\n' "$s_name"
        fi
      fi
    done
  fi
}

