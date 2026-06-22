# the shed architecture

The program has 2 components, the daemon atop the session and the control
client, for common functionality and variable definition both shed and shedc
share libshed as well as utils, all 3 are posix shell scripts, in their
"pre-build" form they have the `.sh` extension, upon build the `.sh` extension
is removed and the version number is appended after a `.` to the file name, upon
installation at the static location `$(DESTDIR)$(PREFIX)/lib/shed` symlinks at
`$(DESTDIR)$(PREFIX)/bin` are created for `shed` and `shedc`

- shed: the daemon for the session process, it reads a user config, sets the
  session related environment variables, sets up the pre-transient environment,
  sets the transient environment, starts the session components, starts the user
  services, then listens to the message socket for actions like the logout
  process.

- shedc: the control program for shed, is able to stop user services and send
  requests to the shed daemon for starting user services, logout from the
  session, reload the shed daemon, hup user services, show information about the
  running shed daemon.


The files for the shed configuration are located at:
`XDG_CONFIG_HOME/shed/` with fallback in `/etc/shed`, the file structure for the
default session is as follows:
```tree
shed/
├── components/
├── env.d/
├── shallow.d/
├── services/
├── shed.rc
└── transient·
```

runtime files for shed will be available at
`$XDG_RUNTIME_DIR/shed/$SHED_SESSION_PID/`, structure is as follows:
```tree
$XDG_RUNTIME_DIR/shed/$SHED_SESSION_PID/
├── components/
├── logs/
├── reply
├── services/
├── shed.info
├── shed.started
└── socket|
```

File Key
| symbol | meaning |
| ---- | ---- |
| `/` | directory |
| `·` | executable file |
| `|` | named pipe |

The shed daemon works in shallow then in transient mode
- shed shallow daemon starts, loads utils, exports SHED_SESSION_PID, if needed
  determines ENV (XDG_RUNTIME_DIR, XDG_SESSION_ID), exports SHED_SESSION, if
  needed exports XDG_CONFIG_HOME, loads config file, if options are set then
  sets xdg desktop vars, xdg session type, sets and creates xdg home dirs, the
  SHED_ENV_EXPORT_LOC, loads libshed, initializes the ShedSessionDir, session
  files, lockfile, message socket, loads the shallow.d env files, removes
  lockfile and hands over to transient process
- shed transient, started as either a child of the transient process or as the
  transient process, loads utils and libshed libraries, writes info, loads env.d
  files, sets signal traps, logs initialization, starts components, starts
  services, finally listens to the msg_socket for actions

Shed also supports per session shed config files.
This mechanism allows to have the shed session config files not be limited to
just one set of them, as an example the sets of config files for 2 sessions
named "shed_awesome" and "shed_sway", one of them x11 and the other wayland
would be contained in subdirs within the shed config (or fallback) dir, which
set of configs to use is determined by passing the session name as an argument
to `shed` upon the shallow run, which then exports the `SHED_SESSION` env var
which is assigned to such passed value and tells the transient shed run as
well as reloads which set of config files to use, the file tree would look
something like so:

```tree
shed/
├── shed_awesome/
│   ├── components
│   │   └── 99x11-window-manager
│   ├── env.d
│   │   ├── x11-tearfree.env
│   │   └── gnome-keyring.env
│   ├── services
│   │   ├── compositor
│   │   ├── pipewire-daemon
│   │   ├── pipewire-daemon-pulse
│   │   ├── pipewire-media-session
│   │   ├── polkit-agent
│   │   ├── xscreenlocker
│   │   └── xsettings-daemon
│   └── shed.rc
└── shed_sway/
    ├── components/
    │   ├── swww
    │   └── sway-bar
    ├── env.d/
    │   └── gnome-keyring.env
    ├── shallow.d/
    │   ├── gtk-wayland-backend.env
    │   ├── qt-wayland-backend.env
    │   └── java-options.env
    ├── services/
    │   ├── pipewire-daemon
    │   ├── pipewire-daemon-pulse
    │   ├── pipewire-media-session
    │   └── polkit-agent
    ├── shed.rc
    └── transient·
```

If no argument was passed to shed or the argument was deemed invalid then shed
fallbacks to the "default" session which uses no per session suffix, this also
provides backwards compatibility with previous builds of shed.

This architecture allows potential distributors to ship configurations for their
default sessions, as example a bunsenlabs-like distro which wishes to ship an
x11 openbox setup as well as a wayland waybox setup can just leverage shed and
not have the need to write their own custom session scripts for either setup off
the ground.

## Session Flow & Inheritance

When shed starts with a session argument:
- shed daemon (parent) parses arg, validates with `is_str_valid`, exports
   `SHED_SESSION`, `SHED_SESSION_PID`
- shed writes session name to `$ShedSessionDir/shed.session` (persistence)
- All child processes inherit `SHED_SESSION` env var (bash, services,
   components, shedc)
- libshed.sh fallbacks `SHED_SESSION` to default if not set
- libshed.sh computes `SESSBASE` suffix from inherited `SHED_SESSION`
- All config dirs use session-specific subdirs via `SESSBASE`
- shedc requires shed daemon ancestor (no standalone mode)

# architectures to implement

The following has not been implemented but i intend to eventually do so:


## optional usage of start-stop-daemon and init-d-script

Currently shed has it's own functions to start services and send them signals
via the service PID stored in a pidfile, such paradigm is inspired by sysvinit
but while so far reliable in my usage it is not as reliable as the
`start-stop-daemon` program shipped by debian or the version shipped by openrc
or even the mini version shipped by busybox, not to mention that beyond defining
a command to start the service, execution flags, service type, logfile, nohup
and delay props we have no fine grained control nor options for how the user
services are started, altho some may say that what is in shed is enough it
certainly doesn't feel as feature complete as what debian's init-d-script
library offers, so if possible i'd like to move the functionality to start as
well as send signals to processes be them session services or session components
to another utility, which would check if start-stop-daemon as well as
init-d-script ara available and defer the starting, stopping, reloading, etc...
of services to them after setting the needed vars, if not available just
fallback onto the current functions which work okay enough
