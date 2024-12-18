# SHED

An init and service manager for user services


<p align="center">
<a href="https://github.com/eylles/shed" alt="GitHub"><img src="https://img.shields.io/badge/Github-2B3137?style=for-the-badge&logo=Github&logoColor=FFFFFF"></a>
<a href="https://gitlab.com/eylles/shed" alt="GitLab"><img src="https://img.shields.io/badge/Gitlab-380D75?style=for-the-badge&logo=Gitlab"></a>
<a href="https://codeberg.org/eylles/shed" alt="CodeBerg"><img src="https://img.shields.io/badge/Codeberg-2185D0?style=for-the-badge&logo=codeberg&logoColor=F2F8FC"></a>
<br>
<br>
<a href="./LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-green.svg"></a>
<a href="https://liberapay.com/eylles/donate"><img alt="Donate using Liberapay" src="https://img.shields.io/liberapay/receives/eylles.svg?logo=liberapay"></a>
<a href="https://liberapay.com/eylles/donate"><img alt="Donate using Liberapay" src="https://img.shields.io/liberapay/patrons/eylles.svg?logo=liberapay"></a>
</p>

## what?

Session services, programs that run as part of your graphical session, for example in x11 you have the compositor, keyring, maybe a clipboard daemon and perhaps pulseaudio or pipewire


## dependencies

- a posix compatible shell interpreter
- core unix utilities (date, mkdir, awk, kill, mkfifo, cat)
- ~~inotifywait from the inotify-tools package (i know freebsd got the program but not what to use in other unices)~~ no longer needed, now a named pipe is used.


## why ?

Some programs have the tendency to missbehave when started in a session process in non systemd distros, the prime example right now being pipewire which has spawned this [pipewire #1099](https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/1099) and this [pipewire #1135](https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/1135) as the issue comments say, this problem forced gentoo to write a wrapper and slackware to roll out a custom [daemon](https://github.com/raforg/daemon) program written in C, in my opinion both of these solutions are less than ideal, on gentoo's case they now have to roll out similar wrappers for other missbehaving programs, the slackware program looks unnecessarily overengineered as it still needs more programs to be started correctly.

And the elephant in the room, both these solutions come out as inferior to the likes of systemd units and runit user services as they don't support restarting for reloading configurations nor a correct way for them to be started and stopped by the user.

That is why i came up with this solution that takes a lot of inspiration from the sysvinit architecture with the aim of keeping simple, intuitive and completely agnostic from any window manager and desktop environment, potentially even agnostic to any graphical environment (altho i personally only care or x11)

TODO:

- [ ] rewrite readme
- [x] move the details of how shed works to another .md file
- [x] add check if the service is running in start, kill and hup
- [x] add service status action to shedc
- [x] add service restart action to shedc
- [x] add a shed daemon reply socket, so that shedc can wait that shed is reloaded.
- [x] make shedc tail and read the reply socket
- [ ] write bash completion scripts
- [ ] write zsh completion scripts
- [ ] draw a logo/icon for shed to use in the repo


## DO NOT USE THE GIT MASTER EVER!

The git master is unstable and may break without notice, always use shed from a release tag.
