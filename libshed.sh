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

# the SHED_SESSION_PID, this is hopefully the pid of the process that keeps the
# session alive, aka the session leader, if shed was ran with exec as part of
# the session startup process then it will be the PID of the running shed
# instance, unless a GUI_SESSION_PID exists, meaning another process is the
# session leader
SHED_SESSION_PID="$SHED_SESSION_PID"
# check if GUI_SESSION_PID is set
if [ -n "$GUI_SESSION_PID" ]; then
  # since it exists that will be the SHED_SESSION_PID
  # this way we can reload from an older version of shed
  # otherwise shed will be the one setting this env var
  SHED_SESSION_PID="$GUI_SESSION_PID"
fi

# dir for the pid files
# SHED_SESSION_PID=$$ must be exported in the xinitrc/xsession file
# to have the pid of the running session, otherwise shed will try to determine
# and export said PID, usually the PID of the parent process that started shed
# ${XDG_RUNTIME_DIR}/shed/${SHED_SESSION_PID}
ShedSessionDir=${XDG_RUNTIME_DIR}/shed/${SHED_SESSION_PID}

# ShedSessionDir definition used on shed versions prior to this commit
OldShedSessionDir=${XDG_RUNTIME_DIR}/GUISession${SHED_SESSION_PID}

UsingOldShedDir="$_false"

# the OldShedSessionDir will only exist if an older version of shed was the one
# that started the session and was later reloaded onto a newer one, meaning the
# new dir is not present so we have to use the old one.
if [ -d "$OldShedSessionDir" ]; then
  ShedSessionDir="$OldShedSessionDir"
  UsingOldShedDir="$_true"
fi

# Return type: int bool
# Usage: is_dir_empty directory
# --------------------------------------------------
# Check if directory is empty (no files matching any glob)
# Returns $_true if empty or doesn't exist, $_false if has files
is_dir_empty() {
  dir="$1"
  # Check if directory exists and has files
  if [ -d "$dir" ]; then
    # Use a simple glob test - if the glob doesn't expand, it returns the pattern
    for _ in "$dir"/* ; do
      # If we get here, at least one file exists
      return "$_false"
    done
    # No files found
    return "$_true"
  else
    # Directory doesn't exist
    return "$_true"
  fi
}

# if ShedSessionDir doesn't exist when running shedc, try to detect it
# dynamically
if [ ! -d "$ShedSessionDir" ] &&
   [ "$prog" = "shedc" ] &&
   ! is_dir_empty "${XDG_RUNTIME_DIR}/shed"; then
  for _dir in "${XDG_RUNTIME_DIR}/shed"/*; do
    [ -d "$_dir" ] || continue
    if [ -S "$_dir/socket" ] || [ -f "$_dir/socket" ]; then
      ShedSessionDir="$_dir"
      break
    fi
  done
  unset _dir
fi

# directory where we are loading the user services to start from
# ${XDG_CONFIG_HOME:-${HOME}/.config}/shed/services
ServicesDir="${XDG_CONFIG_HOME:-${HOME}/.config}/shed/services"

# directory where we are loading the session components to start from
# ${XDG_CONFIG_HOME:-${HOME}/.config}/shed/components
ComponentsDir="${XDG_CONFIG_HOME:-${HOME}/.config}/shed/components"

# directory for loadable .env files
# ${XDG_CONFIG_HOME:-${HOME}/.config}/shed/env.d
EnvDir="${XDG_CONFIG_HOME:-${HOME}/.config}/shed/env.d"

# shed start file, contains the pid of the shed process
# ${ShedSessionDir}/shed.started
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

# dir for component pid files
# ${ShedSessionDir}/components
shed_component_pid_dir="${ShedSessionDir}/components"

# defined as: ${XDG_RUNTIME_DIR}/shed/${SHED_SESSION_PID}/socket
msg_socket="${ShedSessionDir}/socket"
# defined as: ${XDG_RUNTIME_DIR}/shed/${SHED_SESSION_PID}/reply
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
  msg="$(date '+%Y-%m-%d-%H:%M:%S') $*"
  case "$prog" in
    shedc*)
      printf '%s\n' "$msg"
      ;;
    shed*)
      printf '%s\n' "$msg" >> "$msg_reply"
      ;;
  esac
}

# Return type: void
#       Usage: serv_start pid_dir service_file nosock nodelay
#         nosock: default $_false, if passed $_true will set
#                 no sock mode and no message is sent to the
#                 reply socket
#        nodelay: default $_false, if passed $_true will set
#                 no delay mode and no delay will be applied
#                 to starting of the service
# --------------------------------------------------
# this function is not expected to have a return value as
# all messages are sent to the reply socket unless specified
serv_start() {
  # No Sock, default $_false
  NSck="$_false"
  # No Delay, default $_false
  NDlay="$_false"
  NAME=""
  EXEC=""
  E_ARGS=""
  DELAY=""
  LOGFILE=""
  TYPE=""
  exit_status=""
  logfile_path=""
  p_dir="$1"
  s_file="$2"
  if [ "${3}" -eq "$_true" ]; then
    NSck="${3}"
  fi
  if [ "${4}" -eq "$_true" ]; then
    NDlay="${4}"
  fi
  # source the file to get the variables: EXEC E_ARGS from the service
  . "$s_file"
  NAME="${s_file##*/}"
  if [ -z "$LOGFILE" ]; then
    LOGFILE="${shed_logs_dir}/${NAME}.log"
  fi
  # check if service is already running
  if [ -f "${p_dir}/${NAME}.pid" ]; then
    message="$NAME running"
    if [ -f "${p_dir}/${NAME}.est" ]; then
      message="$NAME oneshot already ran"
    fi
    msg_send "$message"
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
    case "$TYPE" in
      # guard against possible stupid values
      oneshot|one|ONESHOT|ONE)
        TYPE="oneshot"
        ;;
      *)
        # you're a daemon
        TYPE="daemon"
        ;;
    esac
    # needed for services that got $HOME/path/service in their EXEC def
    EXEC=$(printf '%s\n' "$EXEC" | sed "s@\$HOME@$HOME@")
    # get the full path of the binary
    EXEC=$(command -v "$EXEC")
    if [ -n "$DELAY" ] && [ "$NDlay" -eq "$_false" ]; then
      msg_log "info" "$NAME start delayed by $DELAY seconds"
      sleep "$DELAY"
    fi
    msg_log "info" "starting $TYPE $NAME"
    # run the service command with the arguments
    s_run="exec $EXEC $E_ARGS >> $LOGFILE 2>&1"
    eval "$s_run" &
    # catch the pid of the process
    proc_pid=$!
    # write the pid of the process to the pid file
    printf '%s\n' "$proc_pid" > "${p_dir}/${NAME}.pid"
    [ "$NSck" -eq "$_false" ] && msg_send "$NAME started"
    case "$TYPE" in
      oneshot)
        wait "$proc_pid"
        exit_status=$?
        printf '%s\n' "$exit_status" > "${p_dir}/${NAME}.est"
        ;;
    esac
  fi
}

# Return type: void
#       Usage: start_from_dir def_dir pid_dir name_to_start
#       def_dir: directory with service definitions
#       pid_dir: directory to store pid files
# name_to_start: can be a service name or one of the macros all and firstrun
# --------------------------------------------------
# Generic function to start services from definitions located in a directory
start_from_dir() {
  def_dir="$1"
  pid_dir="$2"
  start_s="$3"
  nodelay="$_true"
  nosock="$_false"
  specific_name=""
  case "$start_s" in
    firstrun)
      nosock="$_true"  # do not write to msg_reply sock
      nodelay="$_false" # have start delays
      ;;
    all) : ;; # do nothing
    *) specific_name="$start_s" ;;
  esac
  if is_dir_empty "$def_dir"; then
    errmsg="no definitions found in '$def_dir'"
    msg_send "$errmsg"
    msg_log "error" "$errmsg"
    return
  fi
  if [ -n "$specific_name" ]; then
    s_file="${def_dir}/${specific_name}"
    if [ -r "$s_file" ]; then
      serv_start "$pid_dir" "$s_file" "$nosock" "$nodelay" &
    else
      msg_send "definition for $start_s not found in $def_dir"
    fi
    return
  fi
  for i in "${def_dir}"/* ; do
    serv_start "$pid_dir" "$i" "$nosock" "$nodelay" &
  done
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
  start_from_dir "${ServicesDir}" "${shed_service_pid_dir}" "$1"
}

# Return type: void
#       Usage: start_components all | firstrun | <component name>
#            all: start all services
#       firstrun: start all services on first run mode
# <component name>: the component name to start
# --------------------------------------------------
# only one argument is acknowledged.
# components are only started once when shed first runs
start_components() {
  case "$prog" in
    shedc*) : ;; # do nothing
    shed*) : > "$msg_reply" ;; # blank msg_reply
  esac
  msg_send "starting components"
  start_from_dir "${ComponentsDir}" "${shed_component_pid_dir}" "$1"
}

# Return type: string
#       Usage: readkeyvalprop "PROPERTY" file
#       property: key name
#      Return: string containing the value of the
#                 PROPERTY key from the passed file.
# --------------------------------------------------
# the specific property keys for service definition
# files are:
#     EXEC
#     E_ARGS
#     DELAY
#     NOHUP
#     LOGFILE
#     TYPE
readkeyvalprop(){
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
  s_nohup=$(readkeyvalprop "NOHUP" "$1")
  if [ -n "$s_nohup" ]; then
    case "$s_nohup" in
      true|TRUE|1|yes|YES|y|Y)
        canhup="$_false"
        ;;
    esac
  fi
  return "$canhup"
}

# Return type: int bool ($_true or $_false)
# Usage: is_oneshot service_file
# ----------------------------------
# Check if service is a oneshot or a daemon, a oneshot will return $_true
is_oneshot() {
  isoneshot="$_false"
  # Read TYPE property from service file
  s_type=$(readkeyvalprop "TYPE" "$1")
  if [ -n "$s_type" ]; then
    case "$s_type" in
      oneshot|one|ONESHOT|ONE)
        isoneshot="$_true"
        ;;
    esac
  fi
  return "$isoneshot"
}

# Return type: void
#       Usage: sig_proc <pids dir> <service dir> <service name> <signal>
# <service name>: service to send signal
#         signal: term kill hup usr1 usr2
# --------------------------------------------------
# this function is not expected to have a return value as
# all messages are sent to the reply socket
sig_proc() {
  p_dir="$1"
  shift
  s_dir="$1"
  shift
  s_name="$1"
  shift
  signal="$1"
  shift
  s_file="${s_dir}/$s_name"
  if [ -f "$s_file" ]; then
    sig_use=$(printf '%s' "$signal" | tr '[:lower:]' '[:upper:]')
    sig_str=$(printf '%s' "$signal" | tr '[:upper:]' '[:lower:]')
    if [ -f "${p_dir}/${s_name}.pid" ]; then
      s_pid=$(read_file "${p_dir}/${s_name}.pid")
      if kill -0 "$s_pid" 2>/dev/null && ! is_oneshot "$s_file"; then
        if [ "hup" = "$sig_str" ] && ! check_hup_allowed "$s_file"; then
          msg_send "cannot hup daemon $s_name"
        else
          msg_send "sending $sig_str to $s_pid $s_name"
          if [ -z "$dry_run" ]; then
            kill "-${sig_use}" "$s_pid"
          fi
        fi
      else
        case "$sig_str" in
          term|kill)
            msg_send "removing oneshot $s_name pid and exit status files"
            ;;
          *)
            msg_send "cannot send signals to oneshots"
            ;;
        esac
      fi
      # remove the pid file even if process is not alive, this needs to be here
      # so that the pid file for term/kill is always removed so long it exists
      if [ -z "$dry_run" ]; then
        case "$sig_str" in
          term|kill)
            rm -f "${p_dir}/${s_name}.pid"
            if [ -f "${p_dir}/${s_name}.est" ]; then
              rm -f "${p_dir}/${s_name}.est"
            fi
            ;;
        esac
      fi
    else
      msg_send "service $s_name not running"
    fi
  else
    msg_send "no service $1 found in $s_dir"
  fi
}

# Return type: void
#       Usage: sig_all <pids dir> <service dir> <signal>
#      signal: term kill hup usr1 usr2
# --------------------------------------------------
# this function calls sig_proc for every pid file in
# the $shed_service_pid_dir
sig_all() {
  p_dir="$1"
  shift
  s_dir="$1"
  shift
  sig="$1"
  shift
  if is_dir_empty "$p_dir"; then
    errmsg="no pid files found in $p_dir"
    msg_send "$errmsg"
    msg_log "error" "$errmsg"
    return
  fi
  for i in "${p_dir}"/*.pid ; do
    s_name="${i##*/}"
    s_name="${s_name%.pid}"
    sig_proc "${p_dir}" "${s_dir}" "$s_name" "$sig"
  done
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
    sig_all "${shed_service_pid_dir}" "${ServicesDir}" "hup"
  else
    sig_proc "${shed_service_pid_dir}" "${ServicesDir}" "$1" "hup"
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
    sig_all "${shed_service_pid_dir}" "${ServicesDir}" "term"
  else
    sig_proc "${shed_service_pid_dir}" "${ServicesDir}" "$1" "term"
  fi
}

# Return type: void or string
#       Usage: killcomps all | <component name>
#            all: kill all services
# <component name>: component to kill
# --------------------------------------------------
# when ran from shedc messages will be output to stdout
# when ran from shed messages will be redirected to $msg_reply
# components are only killed on logout
killcomps() {
  if [ -z "$1" ] || [ "all" = "$1" ]; then
    sig_all "${shed_component_pid_dir}" "${ComponentsDir}" "term"
  else
    sig_proc "${shed_component_pid_dir}" "${ComponentsDir}" "$1" "term"
  fi
}

# Return type: void or string
#       Usage: old_kill_all_procs
# --------------------------------------------------
# special function to handle versions of shed from before
# service pidfiles were stored in $shed_service_pid_dir,
# it sends term to every process with a pidfile in $ShedSessionDir
old_kill_all_procs() {
  for i in "${ShedSessionDir}"/*.pid ; do
    s_pid=$(read_file "$i")
    s_name="${i##*/}"
    msg_send "sending term to $s_pid $s_name"
    if kill -0 "$s_pid" 2>/dev/null; then
      [ -z "$dry_run" ] && kill "$s_pid"
    fi
    [ -z "$dry_run" ] && rm -f "$i"
  done
}
