# SHED

an init and service manager for user services


<p align="center">
<a href="https://github.com/eylles/shed" alt="GitHub"><img src="https://img.shields.io/badge/Github-2B3137?style=for-the-badge&logo=Github&logoColor=FFFFFF"></a>
<a href="https://gitlab.com/eylles/shed" alt="GitLab"><img src="https://img.shields.io/badge/Gitlab-380D75?style=for-the-badge&logo=Gitlab"></a>
<a href="https://codeberg.org/eylles/shed" alt="CodeBerg"><img src="https://img.shields.io/badge/Codeberg-2185D0?style=for-the-badge&logo=codeberg&logoColor=F2F8FC"></a>
</p>

## what?

session services, programs that run as part of your graphical session, for example in x11 you have the compositor, keyring, maybe a clipboard daemon and perhaps pulseaudio or pipewire


## why ?

some programs have the tendency to missbehave when started in a session process in non systemd distros, the prime example right now being pipewire which has spawned this [pipewire #1099](https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/1099) and this [pipewire #1135](https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/1135) as the issue comments say, this problem forced gentoo to write a wrapper and slackware to roll out a custom [daemon](https://github.com/raforg/daemon) program written in C, in my opinion both of these solutions are less than ideal, on gentoo's case they now have to roll out similar wrappers for other missbehaving programs, the slackware program looks unnecesarily overengineered as it still needs more programs to be started correctly.

and the elephant in the room, both these solutions come out as inferior to the likes of systemd units and runit user services as they don't support restarting for reloading configurations nor a correct way for them to be started and stopped by the user.

that is why i came up with this solution that takes a lot of inspiration from the sysvinit architecture with the aim of keeping simple, intuitive and completely agnostic from any window manager and desktop environment, potentially even agnostic to any graphical environment (altho i personally only care or x11)

## how

shed has 2 scripts, one is the daemon `shed` itself, the other is the client for that daemon `shedc`, the way this works is that `shed` is ran in either the user xinitrc or xsession file (debian and derivates use .xsession while most other distros use .xinitrc), shed needs to recieve the PID of the session through the env var `GUI_SESSION_PID` shed could try to guess it but it ain't reliable as this is the PID that will be killed to log out, then shed will search for the services in `${XDG_CONFIG_HOME}/shed/services/` and proceed to launch them and create pid files in the dir `/tmp/GUISession${GUI_SESSION_PID}/${ServiceName}.pid`, then shed will create the file `socket` in the same dir and enter a loop that listens to changes in the socket file as long as it exists, through the socket shed can recieve the instruction to start services, either an specific one or all of them, the definitions are a simple key=value file with just 3 entries that are NAME, EXEC and E_ARGS, as an example the definition for pipewire:
```sh
NAME=pipewire
EXEC=pipewire
```

shedc meanwhile is intended to hup the services, kill them, signal shed to start them and finally log out, for all of this it uses the pid files in the `/tmp/GUISession${GUI_SESSION_PID}/` dir.


TODO:
-[ ] rewrite readme, perhaps move the details of how shed works to another .md file
-[ ] add checks the service being active in start, kill and hup
-[ ] add service status action to shedc
-[ ] add service restart action to shedc
-[ ] add a shed daemon reply socket, so that shedc can wait that shed is reloaded.
-[ ] write bash and maybe zsh completion scripts
