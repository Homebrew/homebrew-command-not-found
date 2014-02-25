# brew-command-not-found

This project try to reproduce Ubuntu’s `command-not-found` for homebrew users
on OSX.

On a Ubuntu, when you try to use a command that doesn’t exist locally but is
available through a package, Bash will suggest you a command to install this
package. Using this script, you can replicate this behavior on OSX:

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

Download `handler.sh` and source it somewhere in your `.bashrc`:

```sh
. /path/to/handler.sh
```

## Contributing

Feel free to make a pull-request if you want to add MacPort or Fink support!
