# PORTING

By design shed is written to be as portable as possible by using pure posix
shell whenever possible, however due to differnces in options of core utilities
and operating system semantics some functions could not be kept to pure posix
and were built as wrappers with the intention that porters would add the correct
case for their OS, these functions are:

- get_perms
- get_ownerid
- get_session_identifier


## get_perms
From utils.sh, wrapper around stat(1), a file is passed and permissions in octal
are expected as output, the output of uname(1) is used to determine the OS and
options for the stat(1) program, this method is not the best but suggestions on
something better are appreciated. The function is mainly used to check
permissions for the `transient` script.


## get_ownerid
From utils.sh, wrapper around stat(1), a file is passed and the id of the owner
is expected as output, the output of uname(1) is used to determine the OS and
options for the stat(1) program, this method is not the best but suggestions on
something better are appreciated. The function is mainly used to check
the owner id for the `transient` script.

## get_session_identifier
From shed.sh, wrapper function used to get a suitable value for `XDG_SESSION_ID`
when the env var is not set, the output from uname(1) is used to determine the
os kernel type, in linux the wrapper function get_linux_session_identifier is
used to get an identifier, for other unix-like kernels the
get_fallback_identifier function is used, when porting it is adviced to create a
wrapper function that tries to get a suitable identifier in the same way that
get_linux_session_identifier does, from the most desirsable to least desirable
method and using get_fallback_identifier if the desired methods fail.
Worth mentioning that of the functions that may be able to output a suitable
string the get_shed_ps_s_id function can work on any unix-like operating system
with any kernel and any set of utilities, if your OS has consolekit available or
as the main tooling for session tracking then use it, tho consider i have not
tested the function first hand on linux with consolekit so while it should work
in it's current state i cannot guarantee it will.
