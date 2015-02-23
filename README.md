# homebrew-command-not-found

This project try to reproduce Ubuntu’s `command-not-found` for Homebrew users
on OSX.

On Ubuntu, when you try to use a command that doesn’t exist locally but is
available through a package, Bash will suggest you a command to install it.
Using this script, you can replicate this feature on OSX:

```
# on Ubuntu
$ when
The program 'when' is currently not installed.  You can install it by typing:
sudo apt-get install when

# on OSX with Homebrew
$ when
The program 'when' is currently not installed. You can install it by typing:
  brew install when
```

## Install

Download [`handler.sh`][handler] and source it somewhere in your `.bashrc`:

```sh
. /path/to/handler.sh
```

[handler]: https://raw.github.com/bfontaine/brew-command-not-found/master/handler.sh

### Requirements

This tool only supports Bash for now.

## Contributing

Feel free to make a pull-request if you want to add MacPort or Fink support!
