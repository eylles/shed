## how

shed has 2 scripts, one is the daemon `shed` itself, the other is the client for that daemon `shedc`, the way this works is that `shed` is ran in either the user xinitrc or xsession file (debian and derivates use .xsession while most other distros use .xinitrc), shed needs to recieve the PID of the session through the env var `GUI_SESSION_PID` shed could try to guess it but it ain't reliable as this is the PID that will be killed to log out, then shed will search for the services in `${XDG_CONFIG_HOME}/shed/services/` and proceed to launch them and create pid files in the dir `/tmp/GUISession${GUI_SESSION_PID}/${ServiceName}.pid`, then shed will create the file `socket` in the same dir and enter a loop that listens to changes in the socket file as long as it exists, through the socket shed can recieve the instruction to start services, either an specific one or all of them, the definitions are a simple key=value file with just 3 entries that are NAME, EXEC and E_ARGS, as an example the definition for pipewire:
```sh
NAME=pipewire
EXEC=pipewire
```

shedc meanwhile is intended to hup the services, kill them, signal shed to start them and finally log out, for all of this it uses the pid files in the `/tmp/GUISession${GUI_SESSION_PID}/` dir.


