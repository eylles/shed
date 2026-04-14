## how

shed has 2 scripts, one is the daemon `shed` itself, the other is the client for
that daemon `shedc`, the way this works is that `shed` is ran atop the user
session be it through a session.desktop file from a display manager, a script or
directly from the command line for wayland users, inside the xsession main
script with exec (on debian and derivates that is .xsession while other distros
like arch and void that is .xinitrc), that is so that shed can set it's own PID
as the session leader PID, shed will proceed to setup the environment for what
we call the "transient" program, environment setting is very opt in, the basic
env vars are setup in the config file while additional env vars must be set in
.env files inside the `shallow.d` subdir, the transient script will be ran by
shed with exec so that it inherits the PID, the trainsient script will then run
the transient program with exec so the transient program will have the session
leader PID, this is extremely important for wayland compositors as they need to
be the session leader, from there the transient program has the responsability
of spawning shed as a child only once, then shed will load any aditional env
vars from `env.d` and start both session components and session services,
session component definition files are to be stored at the `components` subdir
while services are stored at the `services` subdir, both components and services
have the same format, shed will proceed to launch them and create pid files in
the dirs `${XDG_RUNTIME_DIR}/shed/${SHED_SESSION_PID}/components` and
`${XDG_RUNTIME_DIR}/shed/${SHED_SESSION_PID}/services` respectively, then shed
will create the file `socket` in
`${XDG_RUNTIME_DIR}/shed/${SHED_SESSION_PID}/socket` and enter a loop that
listens to changes written to the socket file, through the socket shed can
recieve the instruction to start, stop components and services, hup services,
and reload, the definitio format is a simple key=value file with just some
entries, as an example the definition for pipewire can be as simple as:
pipewire-daemon
```sh
EXEC=pipewire
```

shedc meanwhile is intended to hup the services, kill them, signal shed to start
them, show the status of services, show information about the daemon and log out.

### the full list of property keys for a shed service (or component) definition

| variable | descritiop |
| ---      | ---   |
| NAME     | obsoleted property used in previous versions, is ignored even if set as the service name is the same as the definition file basename |
| EXEC     | the program to be started as a service |
| E_ARGS   | additional arguments for the daemon program, quote the argument string if it contains spaces |
| DELAY    | delay the startup of the daemon program by the provided seconds, this is passed directly to sleep(1) |
| NOHUP    | to prevent a service from being hupped set this to some of: yes, true, 1 |
| LOGFILE  | file where all program output is redirected to, by default it will be in ${XDG_RUNTIME_DIR}/shed/{$SHED_SESSION_PID}/logs/${NAME}.log |
| TYPE     | if property is not present or set to something other than oneshot or daemon, it will be taken as daemon |
