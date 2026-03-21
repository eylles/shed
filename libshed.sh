#!/bin/sh

# version @VERSION@
prog_v="@VERSION@"
# empty definition so that the lsp won't complain, this SHOULD be defined by the
# program that loads libshed AFTER loading libshed
prog=""

# unix command line compatible booleans

# Type: int
# value: 0
_true=0
# Type: int
# value: 1
_false=1

# dir for the pid files
# GUI_SESSION_PID=$$ must be exported in the xinitrc/xsession file
# to have the pid of the running session, otherwise shed will try to determine
# and export said PID, usually the PID of the parent process that started shed
ShedSessionDir=${XDG_RUNTIME_DIR}/shed/${GUI_SESSION_PID}

# ShedSessionDir definition used on shed versions prior to this commit
OldShedSessionDir=${XDG_RUNTIME_DIR}/GUISession${GUI_SESSION_PID}

UsingOldShedDir="$_false"

# the OldShedSessionDir will only exist if an older version of shed was the one
# that started the session and was later reloaded onto a newer one, meaning the
# new dir is not present so we have to use the old one.
if [ -d "$OldShedSessionDir" ]; then
  ShedSessionDir="$OldShedSessionDir"
  UsingOldShedDir="$_true"
fi

# directory where we are loading the user services to start from
ServicesDir="${XDG_CONFIG_HOME:-${HOME}/.config}/shed/services"

# shed start file, contains the pid of the shed process
startfile="${ShedSessionDir}/shed.started"

# contains version and start date
# ${ShedSessionDir}/shed.info
shed_info="${ShedSessionDir}/shed.info"

# shed's logs dir, service logs may be redirected to their own file in here
# ${ShedSessionDir}/logs
shed_logs_dir="${ShedSessionDir}/logs"

# logs for shed
# ${shed_logs_dir}/shed.logs
shed_log_file="${shed_logs_dir}/shed.log"

# dir for service pid files
# ${ShedSessionDir}/services
shed_service_pid_dir="${ShedSessionDir}/services"

# defined as: ${XDG_RUNTIME_DIR}/shed/${GUI_SESSION_PID}/socket
msg_socket="${ShedSessionDir}/socket"
# defined as: ${XDG_RUNTIME_DIR}/shed/${GUI_SESSION_PID}/reply
msg_reply="${ShedSessionDir}/reply"

# Return type: void
# Usage: msg_log "level" "message"
# log level can be:
#     info
#     error
#     debug
msg_log() {
    loglevel="$1"
    shift
    message="$*"
    case "$loglevel" in
        info)
          loglevel="inf"
            ;;
        err)
          loglevel="err"
            ;;
        debug)
          loglevel="dbg"
            ;;
    esac
    printf '[%s] %s: %s\n' \
      "$(date '+%Y-%m-%d-%H:%M:%S')" \
      "$loglevel" "$message" >> "$shed_log_file"
}

# Return type: void or string
# Usage: msg_send "message"
# --------------------------------------------------
# This function will print to stdout if called from shedc and redirect the
# message to the $msg_reply file if called from shed
msg_send() {
  case "$prog" in
    shedc*)
      printf '%s %s\n' "$(date '+%Y-%m-%d-%H:%M:%S')" "$*"
      ;;
    shed*)
      printf '%s %s\n' "$(date '+%Y-%m-%d-%H:%M:%S')" "$*" >> "$msg_reply"
      ;;
  esac
}

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
  LOGFILE=""
  logfile_path=""
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
  # source the file to get the variables: EXEC E_ARGS from the service
  . "$s_file"
  NAME="${s_file}"
  if [ -z "$LOGFILE" ]; then
    LOGFILE="${shed_logs_dir}/${NAME}.log"
  fi
  # check if service is already running
  if [ -f "${shed_service_pid_dir}/${NAME}.pid" ]; then
    msg_send "$NAME running"
  else
    logfile_path="${LOGFILE%/*}"
    if [ ! -d "$logfile_path" ]; then
      mkdir -p "$logfile_path" || msg_log "error" \
        "could not create logfile dir for $NAME"
    fi
    if [ ! -d "$logfile_path" ]; then
      msg_log "info" "service $NAME not started"
      return
    fi
    # needed for services that got $HOME/path/service in their EXEC def
    EXEC=$(printf '%s\n' "$EXEC" | sed "s@\$HOME@$HOME@")
    # get the full path of the binary
    EXEC=$(command -v "$EXEC")
    if [ -n "$DELAY" ] && [ "$NDlay" = 0 ]; then
      msg_log "info" "$NAME start delayed by $DELAY seconds"
      sleep "$DELAY"
    fi
    # run the service command with the arguments
    s_run="exec $EXEC $E_ARGS >> $LOGFILE 2>&1"
    eval "$s_run" &
    # catch the pid of the process
    proc_pid=$!
    # write the pid of the process to the pid file
    printf '%s\n' "$proc_pid" > "${shed_service_pid_dir}/${NAME}.pid"
    [ -z "$NSck" ] && msg_send "$NAME started"
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
  case "$prog" in
    shedc*) : ;; # do nothing
    shed*) : > "$msg_reply" ;; # blank msg_reply
  esac
  msg_send "starting services"
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

# Return type: int bool ($_true or $_false)
# Usage: check_hup_allowed service_file
# ----------------------------------
# Check if service allows HUP signal, if service can be hupped the return will
# be $_true, else it will be $_false
check_hup_allowed() {
  canhup="$_true"
  # Read NOHUP property from service file
  s_nohup=$(readserviceprop "NOHUP" "$1")
  if [ -n "$s_nohup" ]; then
    case "$s_nohup" in
      true|TRUE|1|yes|YES|y|Y)
        canhup="$_false"
        ;;
    esac
  fi
  return "$canhup"
}

# Return type: void
#       Usage: sig_proc <service name> <signal>
# <service name>: service to send signal
#         signal: term kill hup usr1 usr2
# --------------------------------------------------
# this function is not expected to have a return value as
# all messages are sent to the reply socket
sig_proc() {
  s_name="$1"
  s_file="${ServicesDir}/$s_name"
  if [ -f "$s_file" ]; then
    sig_use=$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')
    sig_str=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')
    if [ -f "${ShedSessionDir}/${s_name}.pid" ]; then
      s_pid=$(read_file "${ShedSessionDir}/${s_name}.pid")
      if kill -0 "$s_pid" 2>/dev/null; then
        if [ "hup" = "$sig_str" ] && ! check_hup_allowed "$s_file"; then
          msg_send "cannot hup service $s_name"
        else
          msg_send "sending $sig_str to $s_pid $s_name"
          if [ -z "$dry_run" ]; then
            kill "-${sig_use}" "$s_pid"
            case "$sig_str" in
              term|kill)
                rm -f "${ShedSessionDir}/${s_name}.pid"
                ;;
            esac
          fi
        fi
      fi
    else
      msg_send "service $s_name not running"
    fi
  else
    msg_send "no service $1 found in $ServicesDir"
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
    for i in "${shed_service_pid_dir}"/*.pid ; do
      s_pid=$(read_file "$i")
      # s_name=$(ps -p "$s_pid" -o comm=)
      s_name="${i##*/}"
      msg_send "sending hup to $s_pid $s_name"
      if kill -0 "$s_pid" 2>/dev/null; then
        [ -z "$dry_run" ] && kill -HUP "$s_pid"
      fi
    done
  else
    for i in "${shed_service_pid_dir}"/* ; do
      ServiceFileName="${i##*/}"
      s_name="$ServiceFileName"
      if [ "$ServiceFileName" = "$1" ]; then
        if [ -f "${shed_service_pid_dir}/${s_name}.pid" ]; then
          s_pid=$(read_file "${shed_service_pid_dir}/${s_name}.pid")
          msg_send "sending hup to $s_pid $s_name"
          if kill -0 "$s_pid" 2>/dev/null; then
          [ -z "$dry_run" ] && kill -HUP "$s_pid"
          fi
        else
          msg_send "service $s_name not running"
        fi
      fi
    done
  fi
}

# Return type: void or string
#       Usage: killprocs all | <service name>
#            all: kill all services
# <service name>: service to kill
# --------------------------------------------------
# when ran from shedc messages will be output to stdout
# when ran from shed messages will be redirected to $msg_reply
killprocs() {
  if [ -z "$1" ] || [ "all" = "$1" ]; then
    for i in "${shed_service_pid_dir}"/*.pid ; do
      s_pid=$(read_file "$i")
      # s_name=$(ps -p "$s_pid" -o comm=)
      s_name="${i##*/}"
      msg_send "sending term to $s_pid $s_name"
      if kill -0 "$s_pid" 2>/dev/null; then
      [ -z "$dry_run" ] && kill "$s_pid"
      fi
      [ -z "$dry_run" ] && rm -f "$i"
    done
  else
    sig_proc "$1" "term"
  fi
}
