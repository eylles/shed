#!/bin/sh

# unix command line compatible booleans

# Type: int
# value: 0
_true=0
# Type: int
# value: 1
_false=1

# Return type: string
# Usage: rm_char_first_occur <str> <char>
# Description:
#   Removes the first (leftmost) occurrence of <char> from string <str>
rm_char_first_occur() {
    str="$1"
    delim="$2"
    right="${str#*"$delim"}"
    left="${str%"$delim$right"*}"
    out="${left}${right}"
    printf '%s' "$out"
}

# Return type: int bool
# Usage: has_char <str> <char>
has_char() {
    str="$1"
    char="$2"
    retval="$_false"
    case "$str" in
        *"$char"*) retval="$_true" ;;
    esac
    return "$retval"
}

# Return type: string
# Usage: rm_all_char <str> <char>
# Description:
#   Loops until all occurrences of <char> are removed from string <str>
rm_all_char() {
    str="$1"
    delim="$2"
    while has_char "$str" "$delim"; do
        str="$(rm_char_first_occur "$str" "$delim")"
    done
    printf '%s' "$str"
}

# Return type: int bool
# Usage: is_dir directory
# --------------------------------------------------
# Check if directory exists
# Returns $_true if passed directory exists, $_false if it does not
# The function will resolve the given path with realpath(1) so that symlinks
# pointing to directories can be passed
is_dir(){
  if [ -d "$(realpath "$1" 2>/dev/null)" ]; then
    return "$_true"
  else
    return "$_false"
  fi
}

# Return type: void
# Usage: make_dir directory
# --------------------------------------------------
# an utility wrapper around mkdir
# Uses is_dir to check if the given path exists, if it does not
# proceeds to create it with mkdir -p
make_dir() {
  if ! is_dir "$1"; then
    mkdir -p "$1"
  fi
}

# Return type: int bool
# Usage: is_dir_empty directory
# --------------------------------------------------
# Check if directory is empty (no files matching any glob)
# Returns $_true if empty or doesn't exist, $_false if has files
is_dir_empty() {
  dir="$1"
  # Check if directory exists and has files
  if is_dir "$dir"; then
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
      return "$_true"
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

# Return type: int
#       Usage: get_perms <file>
# --------------------------------------------------
# will return the octal permissions of the file ie: 755
get_perms() {
  case "$(uname -s)" in
    Linux)        stat -c '%a'  "$1" ;;
    *BSD*|Darwin) stat -f '%Lp' "$1" ;;
  esac
}

# Return type: int
#       Usage: get_ownerid <file>
# --------------------------------------------------
# will return the UID of the file owner, say for a normal
# user 1000 but for the root user 0
get_ownerid() {
  case "$(uname -s)" in
    Linux)        stat -c '%u' "$1" ;;
    *BSD*|Darwin) stat -f '%u' "$1" ;;
  esac
}

# Return type: int bool
#       Usage: are_exec_perms_correct <e_path> <uid>
#      e_path: executable file path
#         uid: expected owner user id
# --------------------------------------------------
# check if the executable permissions are correct, which is:
#   - the executable file exists and is in fact executable
#   - the actual owner id is the expected owner id
#   - the file is writeable only by the owner
are_exec_perms_correct() {
  executable_path="$1"
  shift
  expected_owner_uid="$1"
  shift
  execut_realpath="$(realpath "$executable_path" 2>/dev/null)"
  [ ! -x "$execut_realpath" ] && return "$_false"
  owner_id="$(get_ownerid "$execut_realpath")"
  [ "$expected_owner_uid" -ne "$owner_id" ] && return "$_false"
  exec_perms="$(get_perms "$execut_realpath")"
  case "$exec_perms" in
    *[2367][0-9]|*[0-9][2367])
      return "$_false"
      ;;
  esac
  return "$_true"
}

# Return type: int bool
#       Usage: is_str_valid <string>
# --------------------------------------------------
# valid strings are those that only contain
# 'alphanums', dots '.' and dashes '_-'
is_str_valid() {
  case "$1" in
    # the class of strings we consider false, this should mean:
    # 'empty' OR those which contain strings that are NOT 'alphanums', '._-'
    ""|*[!A-Za-z0-9._-]*)
      return "$_false"
      ;;
    *)
      return "$_true"
      ;;
  esac
}

# Return type: int bool
#       Usage: is_str_true <string>
# --------------------------------------------------
# if the string is a truthy value returns $_true, otherwise $_false
# truthy strings are case insensitive: [ true, t, yes, y, on ], any
# other string is taken as false
is_str_true() {
  result="$_false"
  case "$1" in
    [Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]|[Yy]|[Tt]|[Oo][Nn]|1)
      result="$_true"
      ;;
  esac
  return "$result"
}


# Return type: int bool
#       Usage: is_program <program>
#     program: name of the program to check if is available
is_program() {
  command -v "$1" >/dev/null || return "$_false"
}

# type: string
# description: usleep path if available
has_usleep=""
has_usleep=$(command -v usleep)
[ -z "$has_usleep" ] && has_usleep=$(command -v busybox)
# type: string
# description: path if available to sleep that supports floats
has_fsleep=""
[ -z "$has_usleep" ] && has_usleep=$(command -v python)
if [ -z "$has_usleep" ] && is_program "python"; then
  has_usleep=""
  has_fsleep=$(command -v python)
fi
if sleep 0.001 2>/dev/null; then
    has_usleep=""
    has_flseep=$(command -v sleep)
fi

# usage: msleep int
# description: sleep for milliseconds
# return type: void
msleep () {
    milisecs="$1"
    if [ -n "$has_usleep" ]; then
        microsecs="${milisecs}000"
        case "$has_usleep" in
            */usleep)
                usleep "$microsecs"
                ;;
            */busybox)
                busybox usleep "$microsecs"
                ;;
        esac
    else
        sec_whole=$(( milisecs / 1000 ))
        sec_decim=$(( milisecs % 1000 ))
        if [ "$sec_decim" -lt 10 ]; then
            sec_decim="00${sec_decim}"
        elif [ "$sec_decim" -lt 100 ]; then
            sec_decim="0${sec_decim}"
        fi
        secs="${sec_whole}.${sec_decim}"
        case "$has_fsleep" in
          */sleep)
            sleep "$secs"
            ;;
          */python)
            python -c 'import time; time.sleep('"$secs"')'
            ;;
        esac
    fi
}

HAS_UTILS=$_true
