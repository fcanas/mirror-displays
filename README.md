mirror-displays
===============

A Mac app and command-line tool for fiddling with display mirroring: on/off/toggle

```
usage: mirror [option]    Only the first option passed will be applied
  -h            Print this usage and exit.
  -t            Toggle mirroring (default behavior)
  -on           Turn Mirroring On
  -off          Turn Mirroring Off
  -q            Query the Mirroring state and write "on" or "off" to stdout
  -l A B        Makes display at index B mirror the display at index A
```

## Installing

The `mirror` command line tool is available via a [Homebrew](https://brew.sh) [tap](https://docs.brew.sh/Taps#the-brew-tap-command):

`brew install fcanas/tap/mirror-displays`

or

```
brew tap fcanas/tap
brew install mirror-displays
```



