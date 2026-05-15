# SHED

A generic session process and init-agnostic user services provider.


<p align="center">
<a href="https://github.com/eylles/shed" alt="GitHub"><img src="https://img.shields.io/badge/Github-2B3137?style=for-the-badge&logo=Github&logoColor=FFFFFF"></a>
<a href="https://gitlab.com/eylles/shed" alt="GitLab"><img src="https://img.shields.io/badge/Gitlab-380D75?style=for-the-badge&logo=Gitlab"></a>
<a href="https://codeberg.org/eylles/shed" alt="CodeBerg"><img src="https://img.shields.io/badge/Codeberg-2185D0?style=for-the-badge&logo=codeberg&logoColor=F2F8FC"></a>
<a href="https://git.devuan.org/eylles/shed" alt="Devuan"><img src="https://img.shields.io/badge/Devuan-6A6578?style=for-the-badge&logo=devuan&logoColor=F2F2F2"></a>
<br>
<br>
<a href="./LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-green.svg"></a>
<a href="https://liberapay.com/eylles/donate"><img alt="Donate using Liberapay" src="https://img.shields.io/liberapay/receives/eylles.svg?logo=liberapay"></a>
<a href="https://liberapay.com/eylles/donate"><img alt="Donate using Liberapay" src="https://img.shields.io/liberapay/patrons/eylles.svg?logo=liberapay"></a>
</p>

Follow the shed development and feedback threads:
<p align="center">
<a href="https://dev1galaxy.org/viewtopic.php?id=5160"><img src="https://img.shields.io/badge/devuan%20forum-00509F?style=for-the-badge"></a>
<a href="https://forum.artixlinux.org/index.php/topic,4410.new.html"><img src="https://img.shields.io/badge/artix%20forum-07A1CD?style=for-the-badge"></a>
<a href="https://devuanusers.com/thread-shed-init-independient-agnostic-user-services--42"><img src="https://img.shields.io/badge/devuan%20users%20forum-800080?style=for-the-badge"></a>
</p>

## what?

A session process, like lxsession or xfce4-session, plasma-workspace, etc... but
completely generic, not tied to any toolkit, desktop, windowing system or even
to a graphical interface at all.

Session services, are programs that run as part of your graphical session, for
example in x11 you have the compositor, keyring, maybe a clipboard daemon and
perhaps pulseaudio or pipewire

## dependencies

- a posix compatible shell interpreter
- core unix utilities (date, mkdir, awk, kill, mkfifo, cat)


## why ?

Some programs have the tendency to missbehave when started in a session process
in non systemd distros, the prime example right now being pipewire which has
spawned this
[pipewire #1099](https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/1099)
and this
[pipewire #1135](https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/1135)
as the issue comments say, this problem forced gentoo to write a wrapper and
slackware to roll out a custom [daemon](https://github.com/raforg/daemon)
program written in C, in my opinion both of these solutions are less than ideal,
on gentoo's case they now have to roll out similar wrappers for other
missbehaving programs, the slackware program looks unnecessarily overengineered
as it still needs more programs to be started correctly.

And the elephant in the room, both these solutions come out as inferior to the
likes of systemd user units and runit user services as they don't support
restarting or reloading configurations nor a correct way for them to be started
and stopped by the user.

That is why i came up with this solution that takes a lot of inspiration from
the sysvinit architecture with the aim of keeping simple, intuitive and
completely agnostic from any window manager, desktop environment, and even to
any graphical environment as it's architecture should have not problem
whatsoever handling x11, wayland, [arcan](https://github.com/letoram/arcan),
tty, ssh, etc... thanks to how it was designed and written in almost exclusively
portable POSIX shell with some awk and just 1 function that relies on a linux
kernel feature.

This program is something that should have been written 10, 15 maybe even 20
years ago by someone much smarter but it was only when i could no longer bear
the situation of there being no generic program with the capabilites of shed
that i forced myself into writing it.

## Quick start

clone the repo and cd

```sh
git clone https://github.com/eylles/shed
cd shed

# check and edit the config.mk file as needed
make
make install
```

using the default locations you should get a series of examples for either x11
or wayland sessions at `/usr/local/share/doc/shed/examples`, take them as
inspiration, the shed_awesome and the xsession shed-awesome.desktop are the
example x11 files, the shed_sway and the wayland-session shed-sway.desktop are
the example wayland files.

the shed files go in `$XDG_CONFIG_HOME/shed/`, the xsession file goes into
`/usr/share/xsessions/`, the wayland session files goes into
`/usr/share/wayland-sessions/`

you can figure out the rest, i believe in you!


## ROADMAP

### done
- [x] move the details of how shed works to another .md file
- [x] add check if the service is running in start, kill and hup
- [x] add service status action to shedc
- [x] add service restart action to shedc
- [x] add a shed daemon reply socket, so that shedc can wait that shed is
      reloaded.
- [x] make shedc tail and read the reply socket
- [x] introduce libshed for shaded code between shed and shedc
- [x] add info action to shedc to show info of the running shed daemon
- [x] move service .pid files to their own subdir inside GUISessionDir
- [x] add support for `oneshot` type services that only run and then exit
- [x] add a `session` cathegory of services that are not affected by actions
      (start, stop, restart) sent to all nor by reloads of shed, so that stuff
      like window managers can be managed on this cathegory
- [x] implement the shed_shallow->transient-shed_instance architecture, where in
      a "shallow" shed instance sets the environment, executes the transient
      process and later on the transient spawns a shed instance as a child
      process, this architecture is required to support wayland sessions.
- [x] added checks for a fallback dir in /etc/shed for configs not present in
      XDG_CONFIG_HOME/shed so they can be loaded from there instead
- [x] Implement per session configs, that is to have the set of files and
      subdirs which currently reside in XDG_CONFIG_HOME/shed and their fallbacks
      at /etc/shed to reside inside a subdir `sessions/session_name` where the
      `session_name` would be akin to the XDG_CURRENT_DESKTOP, to use the
      configs for a given session the session start will require to have `shed`
      called with the shed `session_name` as argument, this will allow users to
      be able to maintain multiple session configuration sets allowing not just
      managing 1 window manager or 1 wayland session but having multiple
      definitions for either, this will also open the door for future
      distributors to provide multiple shed managed sessions for x11 or wayland

### pending
- [ ] implement the `XDG_AUTOSTART` spec and provide the option to start and
      manage services from the autostart as regular ones.
- [ ] write bash completion scripts
- [ ] write zsh completion scripts
- [ ] draw a logo/icon for shed to use in the repo


## use the latest release

As of release v0.3.0 there is no reason whatsoever to use older releases, the
master branch is where development happens, i try to keep it stable but read the
commit history and know why you want to use the master branch rather than a
release, always mention if you are using a release tag or the master branch at
some commit before opening issues.

# LICENSE

All files in the repo are licensed under GPLv3.0 or later
