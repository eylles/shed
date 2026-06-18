# why tho?

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
tty, ssh, etc... thanks to how it was designed and written in portable POSIX
shell with some awk shed should be trivial to port across UNIX-like operating
systems other than linux, if someone on the BSD or Illumos world is interested
check PORTING.md.
