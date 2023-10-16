## how

shed has 2 scripts, one is the daemon `shed` itself, the other is the client for that daemon `shedc`, the way this works is that `shed` is ran in either the user xinitrc or xsession file (debian and derivates use .xsession while most other distros use .xinitrc), shed needs to recieve the PID of the session through the env var `GUI_SESSION_PID` shed could try to guess it but it ain't reliable as this is the PID that will be killed to log out, then shed will search for the services in `${XDG_CONFIG_HOME}/shed/services/` and proceed to launch them and create pid files in the dir `${GUISessionDir}/${ServiceName}.pid`, then shed will create the file `socket` in the same dir and enter a loop that listens to changes in the socket file as long as it exists, through the socket shed can recieve the instruction to start services, either an specific one or all of them, the definitions are a simple key=value file with just 3 entries that are NAME, EXEC and E_ARGS, as an example the definition for pipewire:
```sh
NAME=pipewire
EXEC=pipewire
```

shedc meanwhile is intended to hup the services, kill them, signal shed to start them and finally log out, for all of this it uses the pid files in the `${GUISessionDir}/` dir.

the directory is defined as `GUISessionDir=/run/user/${UserID}/GUISession${GUI_SESSION_PID}`


## setting up

  there are currently a couple ways to start shed so i will cover that first


  the xsession method:
  for this example we will assume a debian based distro and login through a display manager (sddm, lightdm, etc...)
  we will create a file in the home directory called .xsession, `~/.xsession`
  inside of it we will add this:

  ```sh
  #!/bin/sh
  # your xsession may already contain lines like these
  export "$(/usr/bin/gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg)" &
  export SSH_AUTH_SOCK &
  # export the session PID variable
  export GUI_SESSION_PID=$$
  # start shed
  shed &
  # we will start a window manager for this example i3
  i3
  ```

  this is the reccomended method for now if you are using a window manager


  the xsessionrc method:
  for this example we will assume a debian based distro and login through a display manager (sddm, lightdm, etc...)
  we will create a file in the home directory called .xsessionrc, `~/.xsessionrc`
  inside of it we will add this:

  ```sh
  #!/bin/sh
  shed &
  ```

that is all to get shed to launch, the .xsessionrc file is loaded during the login process in debian, as such shed will be launched early on in the login process and will be a sibling to whatever session is selected on the Display Manager (gnome-session, xfce-session, mate-session), as it's parent shed will have the same parent as the gui session, this is important as it means shed can do modify the global environment, and in fact it will by exporting the env var `GUI_SESSION_PID` containing the PID of i'ts parent, this method is perfectly usable but somewhat defeats the purpose of shed as the aim is to eventually implement xdg-autostart managing in shed, so the ideal would be once shed implements that to request the maintainers of the desktop-session/desktop environment of your choice to implement managing of xdg-autostart too


| variable | descritiop |
| ---      | ---   |
| NAME     | the name for the pid file of the service |
| EXEC     | the program to be started as a service |
| E_ARGS   | additional arguments for the daemon program, quote the argument string if it contains spaces |
| DELAY    | delay the startup of the daemon program by the provided seconds, this is passed directly to sleep(1) |
