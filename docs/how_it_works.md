## how

shed has 2 scripts, one is the daemon `shed` itself, the other is the client for
that daemon `shedc`, shed should be ran atop the user session as the session
process, ie the session leader or the process that keeps the session alive, this
is in order to be able to get the pid of the session leader, worry not as altho
shed needs to be ran as the session leader it doesn't need to remain so and can
handoff the session leader pid to a transient program which will then become the
session leader, this is the mechanism that allows us to handle not just x11
sessions but also wayland sessions where the compositor needs to be the session
leader as well as any other type of "user session" there can be like a tty or
even ssh session


## hwat

to shed a session is just a collection of programs to be started, these are:

- transient program: the program that will be the session leader, can be a tmux
  instance, a wayland compositor, an x11 window manager, ssh, doesn't really
  matter so long as it is a program which allows the user interaction with the
  computer, of note is that a transient program is responsible to run an
  instance of shed as a child.

- session components: programs that are intrinsic components of the session, to
  a traditional x11 GUI session those would be window-manager, compositor,
  panel, desktop manager, hotkeys daemon, etc... these programs aren't expected
  to need constant managing nor monitorin.

- session services: like "system level" services, the user services as widely
  known at the init level or user units in systemd terminology, are just
  programs that provide some functionality to the user session but may be
  expected to require managing, for example screensaver, screen auto locker
  daemon, clipboard manager, polkit-agent, settings daemon, etc... anything that
  systemd users rely on user units for is covered by this cathegory


to define the programs to be started is really simple, the transient program is
always expected to be inside a "transient script" named `transient` which is
expected to be located at `$XDG_CONFIG_HOME/shed/transient` with a fallback
script that may be in `/etc/shed/transient`, not every setup and type of session
is going to need a transient script, window manager based x11 sessions certainly
do not need to have their window manager as a transient and it may be better to
instead run it as a session component, that way if for whatever reason it
crashes, dies or is killed shed can just start a new instance, however this
flexibility is not possible in every session type, as example wayland since
there the there's no separation between windowing server, window manager and
compositor to the point that usually the program which does those 3 tasks is
simply called a compositor, yapping aside, this is an example transient script
for the sway wayland compositor, take into consideration the `transient` file
MUST be executable!

`transient`
```sh
#!/bin/sh
exec sway > "$XDG_RUNTIME_DIR/shed/$SHED_SESSION_PID/logs/sway.log"
```

on to sway's responsability to initiate the "transient" instance of shed as it's
child, it can be done as easy as this:

`${XDG_CONFIG_HOME:-${HOME}/.config}/sway/config`
```config
# ... other sway configs above here
# this spawns one instance of shed in a manner in which no attempt will be
# made to spawn more instances upon reloads of sway
exec shed
```

as for how to define session components and services, both files have the same
syntax, that is a set of KEY=val entries separated by newlines, for a session
component take as example my definition file for awesome wm:
`99x11-window-manager`
```sh
EXEC=/usr/bin/awesome
```

as an example of session services to have a working pipewire setup in a debian
based distribution it would require just 3 files:

`pipewire-daemon`
```sh
EXEC=pipewire
```

`pipewire-daemon-pulse`
```sh
EXEC=pipewire-pulse
```

`pipewire-media-session`
```sh
EXEC=wireplumber
```

yes, shed definition files are that simple, altho it is reccomended to use the
full path for any program you intend to launch as a session component or service
it is not necessary, so long as the program is in your executable path `$PATH`
the full executable path is not needed, for convenience shed has the hability to
resolve executable paths which use the `$HOME` var in their path, for example
one of my personal user service files, this is for a dbus proxy program which
takes requests from the "org.freedesktop.ScreenSaver" interface and handles them
with "xdg-screensaver", the program originates from [betterxsecurelock](https://github.com/eylles/betterxsecurelock)

`xscreenlocker-proxy`
```sh
EXEC=$HOME/.local/lib/dbus-screenlock-freedesktop.py
```


### locations for definition files

this table illustrates where definition files are expected to be

| cathegory | location | fallback |
| ---      | ---   | ---   |
| session components | $XDG_CONFIG_HOME/shed/components | /etc/shed/components |
| session services | $XDG_CONFIG_HOME/shed/services | /etc/shed/services |


### the full list of property keys for a shed service (or component) definition

| variable | description |
| ---      | ---   |
| NAME     | obsoleted property used in previous versions, is ignored even if set as the service name is the same as the definition file basename |
| EXEC     | the program to be started as a service |
| E_ARGS   | additional arguments for the daemon program, quote the argument string if it contains spaces |
| DELAY    | delay the startup of the daemon program by the provided seconds, this is passed directly to sleep(1) |
| NOHUP    | to prevent a service from being hupped set this to some of: yes, true, 1 |
| LOGFILE  | file where all program output is redirected to, by default it will be in ${XDG_RUNTIME_DIR}/shed/{$SHED_SESSION_PID}/logs/${NAME}.log |
| TYPE     | if property is not present or set to something other than oneshot or daemon, it will be taken as daemon |


## how to start a shed session

Full disclosure personally i only got first hand experience with x11 sessions,
everything related to wayland is just pure theoretical speculation from my part
informed via the gentoo wiki, arch wiki and manpages.

### x11

With x11 we have 2 tested ways to initiate a shed session, these are:

- from tty: that is leveraging the `startx` command and the `$HOME/.xinitrc`
  file or `$HOME/.xsession` in debian systems.

- from login manager: this requires creating a `.desktop` file in
  `/usr/share/xsessions` and having no .xinitrc file.


#### from tty

from the tty we will type the startx command, out .xinitrc or in debian and
derivates .xsession would be like this:
`.xinitrc`
```sh
#!/bin/sh
exec shed
```

#### from display manager

for this we need NOT to have any xinitrc nor xsession file in our home dir, then
create .desktop entry at `/usr/share/xsessions/` and give it some name, since i
use awesome wm my .desktop file is based off the awesome.desktop file.
`shed-awesome.desktop`
```sh
[Desktop Entry]
Name=shed awesome
Comment=awesome wm on shed
Exec=shed
Type=Application
Icon=/usr/share/pixmaps/awesome.xpm
```


### wayland

as i said i know little of how wayland ticks but this ought to do.

#### from display manager

a display manager that can start wayland sessions and reads them from
`/usr/share/wayland-sessions/` is required, if you use wayland you probably got
a better idea which ones to use than me, next is just a matter of having a
suitable file, since our previous example of the transient script used sway we
will use sway for this too.
`shed-sway.desktop`
```sh
[Desktop Entry]
Name=shed sway
Comment=An i3-compatible Wayland compositor on shed
Exec=shed
Type=Application
DesktopNames=sway;wlroots
```

## lifetime

the way this works is that `shed` is ran atop the user
session, that is so that shed can set it's own PID as the session leader PID,
shed will proceed to setup the environment for what we call the "transient"
program, environment setting is very opt in, the basic env vars are setup in the
config file while additional env vars must be set in .env files inside the
`shallow.d` subdir, the transient script will be ran by shed with exec so that
it inherits the PID, the trainsient script will then run the transient program
with exec so the transient program will have the session leader PID, this is
extremely important for wayland compositors as they need to be the session
leader, from there the transient program has the `responsability` of spawning
shed as a child only once, then shed will load any aditional env vars from
`env.d` and start both session components and session services, shed will
proceed to launch them and create pid files in the dirs
`${XDG_RUNTIME_DIR}/shed/${SHED_SESSION_PID}/components` and
`${XDG_RUNTIME_DIR}/shed/${SHED_SESSION_PID}/services` respectively, then shed
will create the file `socket` in
`${XDG_RUNTIME_DIR}/shed/${SHED_SESSION_PID}/socket` and enter a loop that
listens to changes written to the socket file, through the socket shed can
recieve the instruction to start, stop components and services, hup services,
and reload, to log out the shed client `shedc` is used as:
```sh
shedc logout
```

the shedc program is the standar way to send actions to shed, for details on
usage either consult the shed manpage or run shedc with the `-h` flag
