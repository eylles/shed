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

This program is something that should have been written 10, 15 maybe even 20
years ago by someone much smarter but it was only when i could no longer bear
the situation of there being no generic program with the capabilites of shed
that i forced myself into writing it.

## dependencies

- a posix compatible shell interpreter
- core unix utilities (date, mkdir, awk, kill, mkfifo, cat)


## porting

This program is written to target the widest range of unix-like operating
systems, altho i lack the knowledge to properly integrate shed into BSD and
illumos environments wrapper functions are provided in the codebase so that
adding the corresponding cases should be the only modification of shed needed.

For details check [PORTING](docs/porting.md)

## why ?

[Why SHED?](docs/why_shed.md)

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

Check the shed [Roadmap](docs/roadmap.md)

## Contributing

Check the [CONTRIBUTING](CONTRIBUTING.md) guidelines first and please follow
them, if you want to contribute code be sure to read the
[architecture](docs/architecture.md) as well as the
[how it works](docs/how_it_works.md) documents, if leveraging the capabilities
of AI tools please direct your tool of choice to take into consideration the
previously mentioned documents as well as the [internals](docs/internals.md)
document.

## use the latest release

As of release v0.3.0 there is no reason whatsoever to use older releases, the
master branch is where development happens, i try to keep it stable but read the
commit history and know why you want to use the master branch rather than a
release, always mention if you are using a release tag or the master branch at
some commit before opening issues.

# LICENSE

All files in the repo are licensed under GPLv3.0 or later
