# 
# brew-command-not-found script for OS X
#
# Usage: Source it somewhere in your .bashrc
#
# Author: Baptiste Fontaine
# URL: https://github.com/bfontaine/brew-command-not-found
# License: MIT
# Version: 0.1.1
# 

[ ! -z "$(which brew)" ] && command_not_found_handle() {

    # <from Linux Journal>
    #   http://www.linuxjournal.com/content/bash-command-not-found

    export TEXTDOMAIN=command-not-found

    # do not run when inside Midnight Commander or within a Pipe
    if test -n "$MC_SID" -o ! -t 1 ; then
        echo $"$1: command not found"
        return 127
    fi

    # </from Linux Journal>

    local path="$(brew --prefix)/Library/Formula"
    local f=$(\grep -lI -E "bin\.install..*\b$1\b(\"|')" $path/*.rb 2>/dev/null)

    if [ -z "$f" ]; then
        echo $"$1: command not found"
        return 127
    fi

    f=${f##*/}
    f=${f%%.rb}

    echo $"The program '$1' is currently not installed. You can install it by typing:"
    echo $"  brew install $f"

}
