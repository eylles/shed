# ROADMAP

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
- [x] Add multiple ways to get an `XDG_SESSION_ID` if not set, the existing and
      wrapper functions ease the porting of shed to other unices by providing
      sensible fallbacks and the skeleton to hook OS specific semantics for the
      setting of `XDG_SESSION_ID`
- [x] Remodel daemon cycle to be non blocking
- [x] Improve logging and add configuration for which log levels to log
- [x] Streamline library variable definitions
- [x] Remodel makefile
- [x] Improve documentation
- [x] implement `NOFIRSTRUN` property to prevent a service from being started
upon "firstrun".
- [x] implement `NOSTARTALL` property to prevent a service from being started
when shed reloads or whenever `start_services` is called with "all" arg

### pending
- [ ] implement optional integration with `start-stop-daemon`
- [ ] implement the `XDG_AUTOSTART` spec and provide the option to start and
      manage services from the autostart as regular ones.
- [ ] write bash completion scripts
- [ ] write zsh completion scripts
- [ ] draw a logo/icon for shed to use in the repo

