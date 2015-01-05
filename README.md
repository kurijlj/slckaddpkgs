slckaddpkgs
===========

Simple system for managing dependencies and retrieval of various unofficial software packages for Slackware. System is built on top of the [SlackBuilds.org](http://www.slackbuilds.org/) build scripts.

To install it, first create folder `./.slckaddpkgs` in your home folder, and copy following file there:
```
slckaddpkgsrc
```

Then in the same directory create file with name:
```
packages.cfg
```

File packages.cfg should be populated with data in a way described with sample files:
```
packages_guest.cfg
packages_host.cfg
```

After all beeing set copy slckaddpkgs.sh to desired place (e.g. `/usr/local/bin`), and make it executable.

