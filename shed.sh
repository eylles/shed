#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later

##########################################################################
# This program is free software: you can redistribute it and/or modify   #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# This program is distributed in the hope that it will be useful,        #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with this program.  If not, see <https://www.gnu.org/licenses/>. #
##########################################################################

# source utils library
. ./utils.sh

# Type: int
shed_pid="${$}"

SHED_ENV_EXPORT_LOC=""

# check if GUI_SESSION_PID is set
if [ -n "$GUI_SESSION_PID" ]; then
  # since it exists that will be the SHED_SESSION_PID
  export SHED_SESSION_PID="$GUI_SESSION_PID"
else
  if [ -z "$SHED_SESSION_PID" ]; then
    # it wasnt set, so we will use the shed_pid
    export SHED_SESSION_PID="$shed_pid"
  fi
fi

UserID=""
RootUserID=0
# cuz $UID is not POSIX ¯\_(ツ)_/¯
# but it may be defined in the environment
if [ -z "$UID" ]; then
  # result of: id -u $USER
  UserID=$(id -u "$USER")
  export UID="$UserID"
else
  UserID="$UID"
fi

# define XDG_RUNTIME_DIR if it doesn't exist
if [ -z "${XDG_RUNTIME_DIR}" ]; then
  # test if the usual location is writeable
  if [ -w "/run/user/${UserID}" ]; then
    # we can simply export it now
    export XDG_RUNTIME_DIR="/run/user/${UserID}"
  else
    # welp, gotta define it as something
    export XDG_RUNTIME_DIR=/tmp/"${UserID}"-runtime-dir
    make_dir "${XDG_RUNTIME_DIR}"
    chmod 0700 "${XDG_RUNTIME_DIR}"
  fi
fi

# Return type: string
# Usage: get_fallback_identifier <OsType>
# OsType: expected to be the output from 'uname -s'
# ------------------------------------------------------------------------------
# Description:
# This function returns the first available from a series of possible unique
# identifiers in the form of OsType_uident, where OsType is the passed argument
# suffixed by _uident, where uident is a unique identifier, first we try TTYN
# where TTYN is the basename of the tty path where shed was started from as
# provided by the tty(1) program trimmed to just the string after the last '/',
# if tty(1) gives an error we fallback to dispN where N is the value of the
# 'DISPLAY' env var the ':' separator removed, if that is not set we fallback to
# pidN where N is the PID of shed, so as an example in FreeBSD with shed started
# from tty1 the tty(1) program returns '/dev/tty1' the output would be
# 'FreeBSD_tty1', if tty(1) fails and DISPLAY is set to ':0' then it would be
# 'FreeBSD_disp0', worst case we fallback to something like 'FreeBSD_pid1520'
# if the PID of shed was '1520', this function is for fallbacks only.
get_fallback_identifier() {
  started_tty="$(tty 2>/dev/null || echo 'no_tty')"
  started_tty="${started_tty##*/}"
  if [ "no_tty" != "$started_tty" ]; then
    u_ident="$started_tty"
  elif [ -n "$DISPLAY" ]; then
    use_disp="$(rm_all_char "$DISPLAY" ":")"
    u_ident="disp${use_disp}"
  else
    u_ident="pid${shed_pid}"
  fi
  printf '%s' "${1}_${u_ident}"
}

# Return type: string
# ------------------------------------------------------------------------------
# altho the ps(1) program is a standard unix interface the value it returns may
# not be desirable for usage as an XDG_SESSION_ID
get_shed_ps_s_id() {
  pssid=$(ps -o sid= -p "$shed_pid" 2>/dev/null)
  if [ -n "$pssid" ]; then
    pssid=$(rm_all_char "$pssid" ' ')
    printf '%s' "$pssid"
  else
    return "$_false"
  fi
}

# Return type: string
# ------------------------------------------------------------------------------
# if the XDG_SESSION_COOKIE string is present we assume we are within a
# consolekit session and we can get a usable value from ck-list-sessions
get_consolekit_session_id() {
  if [ -n "$XDG_SESSION_COOKIE" ]; then
    ck-list-sessions | awk '/^Session/{print $2; exit}'
  else
    return "$_false"
  fi
}

# Return type: string
# ------------------------------------------------------------------------------
# if loginctl is available use it to get the XDG_SESSION_ID, loginctl is usually
# only available on linux distributions that use either systemd or elogind
get_loginctl_session_id() {
  if command -v loginctl >/dev/null 2>&1; then
    loginctl session-status | head -n1 | cut -d' ' -f1
  else
    return "$_false"
  fi
}

# Return type: string
# ------------------------------------------------------------------------------
# should return shed's sessionid value, this is a linux specific feature tho
get_shed_proc_sessionid() {
  # maximum unsigned 32 bit integer '4294967295''
  MaxUInt32=$(( (1 << 32) - 1 ))
  proc_sessid="$(cat /proc/"${shed_pid}"/sessionid 2>/dev/null)"
  # Ensure it is a valid ID and not the "no session" unset indicator
  if [ "$MaxUInt32" -eq "$proc_sessid" ]; then
    return "$_false"
  else
    printf '%s' "$proc_sessid"
  fi
}

# Return type: string
# ------------------------------------------------------------------------------
# should return shed's cgroup, cgroup is a linux only feature tho.
# if the content of cgroup is something like "0::/1", we only return the
# value after the "/", so with "0::/1" we output "1"
get_shed_cgroup() {
  sed 's@.*::/@@' /proc/"${shed_pid}"/cgroup 2>/dev/null
}

# Return type: string
# ------------------------------------------------------------------------------
# Gets a unique identifier string to use as XDG_SESSION_ID on linux
get_linux_session_identifier() {
  # Try loginctl first
  uniqid="$(get_loginctl_session_id)"
  if [ -n "$uniq" ]; then
    printf '%s' "$uniq"
    return
  fi

  # try consolekit
  uniqid="$(get_consolekit_session_id)"
  if [ -n "$uniq" ]; then
    printf '%s' "$uniq"
    return
  fi

  # try cgroup
  uniqid="$(get_shed_cgroup)"
  if is_str_valid "$uniqid" ; then
    printf '%s' "$uniqid"
    return
  fi

  # Try /proc/sessionid
  uniqid="$(get_shed_proc_sessionid)"
  if [ -n "$uniqid" ]; then
    printf '%s' "$uniqid"
    return
  fi

  # Try ps(1) SID
  uniqid="$(get_shed_ps_s_id)"
  if [ -n "$uniqid" ]; then
    printf '%s' "$uniqid"
    return
  fi

  # Last resort: generic fallback
  get_fallback_identifier "Linux"
}

# Return type: string
# --------------------------
# this is a best attempt effort
# in linux we use get_linux_session_identifier
# in any other platform we use get_fallback_identifier, if that is not enough
# for your platform/kernel please implement a suitable function that integrates
# with the correct session tracking semantics of your platform/operating
# system/kernel in a logical way.
# ------------------------------------------------------------------------------
# other kernels like the bsd families, illumos, darwin, etc ought to have
# something similar-ish to cgroups or some property with a unique value that
# gets assigned to a processes and propagated to their children that we can get
# and use to define an XDG_SESSION_ID, at least i know bsd got the jails system
# but got no idea if that would be the correct property to use for this, no idea
# if people in other unices and unix-like os even care about something like shed
# to begin with as i'd assume they already got something better and is just we
# linux folk whom are stuck in the obscurantism of systemd...
get_session_identifier() {
  os_type="$(uname -s)"
  case "$os_type" in
    Linux)
      get_linux_session_identifier
      ;;
    *)
      get_fallback_identifier "$os_type"
      ;;
  esac
}

# do we got an XDG_SESSION_ID ?
if [ -z "$XDG_SESSION_ID" ]; then
  XDG_SESSION_ID="$(get_session_identifier)"
  export XDG_SESSION_ID
fi

set_xdg_desktop_vars=""
session_desktop=""
current_desktop=""
use_xdg_session_type=""
set_xdg_home_dirs=""

if [ -z "$SHED_SESSION" ] && [ "$#" -gt 0 ]; then
  if is_str_valid "$1"; then
    export SHED_SESSION="$1"
  else
    export SHED_SESSION="default"
  fi
fi

SESSBASE=""
case "$SHED_SESSION" in
  "default")
    SESSBASE=""
    ;;
  *)
    SESSBASE="/${SHED_SESSION}"
    ;;
esac

if [ -z "$XDG_CONFIG_HOME" ]; then
  export XDG_CONFIG_HOME="${HOME}/.config"
fi

old_conf_dir="${XDG_CONFIG_HOME}/shed/conf"
# directory where we are loading the shed specific config
ConfDir="${XDG_CONFIG_HOME}/shed${SESSBASE}"
if [ -d "$old_conf_dir" ]; then
  ConfDir="$old_conf_dir"
fi
# shed config file
# ${XDG_CONFIG_HOME}/.config}/shed/${SESSBASE}/shed.rc
Config="${ConfDir}/shed.rc"
FallbackConfig="/etc/shed${SESSBASE}/shed.rc"
# the default config template
DefConf="@DOC@/shed.rc"

if [ -r "$Config" ]; then
  . "$Config"
elif [ -r "$FallbackConfig" ]; then
  . "$FallbackConfig"
else
  cp "$DefConf" "$Config"
  . "$Config"
fi

if [ -n "$set_xdg_desktop_vars" ]; then
  export XDG_SESSION_DESKTOP="$session_desktop"
  export XDG_CURRENT_DESKTOP="$current_desktop"
fi

if [ -n "$use_xdg_session_type" ]; then
  export XDG_SESSION_TYPE="$use_xdg_session_type"
fi

if [ -n "$set_xdg_home_dirs" ]; then
  if [ -z "$XDG_DATA_HOME" ]; then
    export XDG_DATA_HOME="$HOME/.local/share"
  fi
  if [ -z "$XDG_CACHE_HOME" ]; then
    export XDG_CACHE_HOME="$HOME/.cache"
  fi
  if [ -z "$XDG_STATE_HOME" ]; then
    export XDG_STATE_HOME="$HOME/.local/state"
  fi
  if [ ! -f "$XDG_CONFIG_HOME/user-dirs.dirs" ]; then
    xdg-user-dirs-update
  fi
  . "$XDG_CONFIG_HOME/user-dirs.dirs"
  export XDG_DESKTOP_DIR
  export XDG_DOWNLOAD_DIR
  export XDG_TEMPLATES_DIR
  export XDG_PUBLICSHARE_DIR
  export XDG_DOCUMENTS_DIR
  export XDG_MUSIC_DIR
  export XDG_PICTURES_DIR
  export XDG_VIDEOS_DIR
  export XDG_PROJECTS_DIR
fi

if [ -n "$make_xdg_home_dirs" ]; then
  for dir in \
    "$XDG_DATA_HOME" \
    "$XDG_CACHE_HOME" \
    "$XDG_STATE_HOME" \
    "$XDG_DESKTOP_DIR" \
    "$XDG_DOWNLOAD_DIR" \
    "$XDG_TEMPLATES_DIR" \
    "$XDG_PUBLICSHARE_DIR" \
    "$XDG_DOCUMENTS_DIR" \
    "$XDG_MUSIC_DIR" \
    "$XDG_PICTURES_DIR" \
    "$XDG_VIDEOS_DIR" \
    "$XDG_PROJECTS_DIR" ;
    do
      make_dir "$dir"
    done
    unset dir
fi

if [ -n "$SHED_ENV_EXPORT_LOC" ]; then
  env_export_dir="${SHED_ENV_EXPORT_LOC%/*}"
  if [ ! -d "$env_export_dir" ]; then
    make_dir "$env_export_dir"
  fi
  cat << __ENV_EXPORT__ >> "$SHED_ENV_EXPORT_LOC"
export XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR"
export XDG_SESSION_ID="$XDG_SESSION_ID"
export SHED_SESSION="$SHED_SESSION"
export SHED_SESSION_PID="$SHED_SESSION_PID"
__ENV_EXPORT__
fi

# source shed library
. ./libshed.sh

# shed
# --------------------------
# the SHell Execution Daemon
prog="${0##*/}"

# werether or not the ShedSessionDir was present at startup
# initial value: $_false
sessdir="$_false"

# check if the session dir exists
if [ -d "$ShedSessionDir" ]; then
  # let the program knows the dir exists
  sessdir="$_true"
else
  # create the session dir if it doesn't exist
  make_dir "$ShedSessionDir"
fi

if [ ! -d "$shed_service_pid_dir" ]; then
  make_dir "$shed_service_pid_dir"
fi
if [ ! -d "$shed_component_pid_dir" ]; then
  make_dir "$shed_component_pid_dir"
fi
if [ ! -d "$shed_logs_dir" ]; then
  make_dir "$shed_logs_dir"
fi

if [ ! -f "$shed_session_file" ]; then
  printf '%s' "$SHED_SESSION" > "$shed_session_file"
fi

# werether shed is a fresh start or a post reload
# default: $_false
reloaded="$_false"

if [ ! -f "$lockfile" ]; then
  printf '%s\n' "$shed_pid" > "$lockfile"
  msg_log "info" "lockfile '$lockfile' written"
else
  # the pid will not change when reloading as we use exec, so if the pid is
  # different then we should not run at all since only one instance should run
  # per session.
  file_pid=$(cat "$lockfile")
  if [ "$file_pid" -eq "$shed_pid" ]; then
    reloaded="$_true"
  else
    printf '%s\n' "${prog}: instance with pid ${file_pid} already running!"
    exit 1
  fi
fi

# create the socket file if necessary
if [ ! -p "$msg_socket" ]; then
  if [ -f "$msg_socket" ]; then
    rm "$msg_socket"
  fi
  mkfifo -m 600 "$msg_socket"
fi

# create the empty reply file if necessary
if [ -f "$msg_reply" ]; then
  : > "$msg_reply"
fi


# shallow execution routine
# we are in shallow mode if the $ShedSessionDir didn't exist when we first ran,
# since no other program outside shed is ever going to create the
# $ShedSessionDir we can be sure of that, so we can simply check if $sessdir is
# _true or _false to know we have to run the shallow mode code.
if [ "$sessdir" -eq "$_false" ]; then
  if ! is_dir_empty "$ShallowEnvDir"; then
    for EnvFile in "$ShallowEnvDir"/*.env; do
      if [ -r "$EnvFile" ]; then
        msg_log "info" "loading env file $EnvFile"
        . "$EnvFile"
      fi
    done
    unset EnvFile
  elif ! is_dir_empty "$FallbackShallowEnvDir"; then
    for EnvFile in "$FallbackShallowEnvDir"/*.env; do
      if [ -r "$EnvFile" ]; then
        msg_log "info" "loading env file $EnvFile"
        . "$EnvFile"
      fi
    done
    unset EnvFile
  fi
  # remove the lockfile before executing the transient
  rm "$lockfile"
  msg_log "info" "shed-shallow lockfile '$lockfile' released"
  # exec transient
  if are_exec_perms_correct "$UseTransient" "$UserID"; then
    msg_log "info" "shed-shallow executing $UseTransient"
    exec "$UseTransient"
  elif are_exec_perms_correct "$FallbackTransient" "$RootUserID" ; then
    msg_log "info" "shed-shallow executing $FallbackTransient"
    exec "$UseTransient"
  else
    msg_log "info" "shed-shallow executing $0"
    exec "$0"
  fi
fi

write_info() {
  printf '%s=%s\n' "VERSION" "$prog_v"
  printf '%s=%s\n' "STARTED" "$(date '+%Y-%m-%d-%H:%M:%S')"
  printf '%s=%s\n' "RUNDIR" "$ShedSessionDir"
}

write_info > "$shed_info"

# write started for when shedc requests a reload
if [ "$reloaded" -eq "$_true" ]; then
  printf '%s\n' "$prog $prog_v started" > "$msg_reply"
fi

if [ "$reloaded" -eq "$_false" ] && ! is_dir_empty "$EnvDir"; then
  for EnvFile in "$EnvDir"/*.env; do
    if [ -r "$EnvFile" ]; then
      msg_log "info" "loading env file $EnvFile"
      . "$EnvFile"
    fi
  done
  unset EnvFile
elif [ "$reloaded" -eq "$_false" ] && ! is_dir_empty "$FallbackEnvDir"; then
  for EnvFile in "$FallbackEnvDir"/*.env; do
    if [ -r "$EnvFile" ]; then
      msg_log "info" "loading env file $EnvFile"
      . "$EnvFile"
    fi
  done
  unset EnvFile
fi

# Return type: void
#       Usage: wait_exit
# --------------------------------------------------
# this function does not return output whatsoever
# sleep 1 second while the ShedSessionDir exists
wait_exit() {
  while ! is_dir_empty "$ShedSessionDir"; do
    sleep 0.25
  done
}

# global var to track daemon cycle reload state
#   0 or unset: continue cycle.
#   1: re-exec daemon.
#   2: exit daemon, set by daemon_cycle when the dir for the msg_socket fifo
#      does not exist.
SHED_RELOAD=""

# Return type: void
#       Usage: process_action "Action Argument"
# --------------------------------------------------
# parse a single input line and run the associated commands
process_action() {
  Input="$1"
  [ -z "$Input" ] && return
  # first column separated by space
  Action="${Input%% *}"
  # second column separated by space
  Argument="${Input##* }"
  case "${Action}" in
    reload)      SHED_RELOAD=1              ;;
    start)       start_services "$Argument" ;;
    stop)        killprocs "$Argument"      ;;
    hup)         hupprocs "$Argument"       ;;
    wait-logout) wait_exit                  ;;
  esac
}

# path for the internal atomic action queue
# ${ShedSessionDir}/queue
QUEUE_FILE="${ShedSessionDir}/queue"
# initialize the QUEUE_FILE
: > "$QUEUE_FILE"

# Return type: void
#       Usage: ipcHandler
# --------------------------------------------------
# process queue file line by line, lines are handled with process_action
ipcHandler() {
  # move the queue file so the loop can keep writing to a clean one
  if [ -s "$QUEUE_FILE" ]; then
    mv "$QUEUE_FILE" "$QUEUE_FILE.work"
    : > "$QUEUE_FILE"
    while read -r Line; do
      process_action "$Line"
      [ -n "$SHED_RELOAD" ] && [ "$SHED_RELOAD" -ne 0 ] && break
    done < "$QUEUE_FILE.work"
    rm -f "$QUEUE_FILE.work"
  fi
}

# Return type: void
#       Usage: daemon_cycle
# --------------------------------------------------
# this function does not return output whatsoever
daemon_cycle() {
  # Ensure queue file is clean before launching background task
  : > "$QUEUE_FILE"
  # Spin up the non-blocking background reader loop
  (
    while [ -d "${ShedSessionDir}" ]; do
      # This read blocks inside a subshell without blocking signals to the main
      # process loop
      if read -r RawInput < "$msg_socket"; then
        if [ -n "$RawInput" ]; then
          # Save command to queue file and issue a localized nudge signal (USR1)
          printf '%s\n' "$RawInput" >> "$QUEUE_FILE"
          kill -USR1 "$shed_pid"
        fi
      fi
    done
  ) &
  READER_PID=$!
  # Event Loop
  while [ -z "$SHED_RELOAD" ] || [ "$SHED_RELOAD" = 0 ] ; do
    # Check that the ShedSessionDir exists
    if [ -d "${ShedSessionDir}" ]; then
      # Posix 'wait' yields control. It unblocks instantly when any trap fires.
      # It returns 128 when interrupted by a signal, which satisfies the loop
      # tick.
      wait "$READER_PID" 2>/dev/null
    else
      # shed must exit
      SHED_RELOAD=2
    fi
  done
  # Cleanup background reader process before dropping out of the cycle
  kill "$READER_PID" 2>/dev/null
}

# Return type: void
#       Usage: sigHandler "SIG"
# Description:
#   Handle signals to terminate or reload the program
sigHandler () {
  msg_log "received signal $1"
  case "$1" in
    HUP|USR*)
      printf '%s\n' "reload" > "$msg_socket"
      ;;
    TERM|INT)
      killprocs "all"
      killcomps "all"
      ;;
    CONT)
      start_components "all"
      start_services "all"
      ;;
    EXIT|QUIT)
      killprocs "all"
      killcomps "all"
      rm -rf "$ShedSessionDir"
      kill "$SHED_SESSION_PID"
      ;;
  esac
}

# start all services on first run
start_str=""
if [ "$reloaded" -eq "$_true" ]; then
  start_str="all"
else
  start_str="firstrun"
fi

msg_log "info" "$prog $prog_v initiated"

if [ "$_true" -eq "$UsingOldShedDir" ]; then
  msg_log "info" "$prog $prog_v using old shed dir $ShedSessionDir"
fi

start_components "$start_str"
start_services "$start_str"

trap 'sigHandler "HUP"'  HUP
trap 'ipcHandler'        USR1 # exclusively for internal background IPC alerts
trap 'sigHandler "USR2"' USR2
trap 'sigHandler "EXIT"' EXIT
trap 'sigHandler "TERM"' TERM
trap 'sigHandler "INT"'  INT
trap 'sigHandler "CONT"' CONT
trap 'sigHandler "QUIT"' QUIT

daemon_cycle

# reload shed
[ "$SHED_RELOAD" = 1 ] && exec shed
