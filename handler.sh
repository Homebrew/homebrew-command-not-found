#
# brew-command-not-found script for OS X
#
# Usage: Source it somewhere in your .bashrc
#
# Author: Baptiste Fontaine
# URL: https://github.com/bfontaine/homebrew-command-not-found
# License: MIT
# Version: 0.2.0
# 

[ ! -z "$(which brew)" ] && command_not_found_handle() {

    local cmd="$1"

    # <from Linux Journal>
    #   http://www.linuxjournal.com/content/bash-command-not-found

    export TEXTDOMAIN=command-not-found

    # do not run when inside Midnight Commander or within a Pipe
    if test -n "$MC_SID" -o ! -t 1 ; then
        echo $"$cmd: command not found"
        return 127
    fi

    # </from Linux Journal>

    local txt=$(brew which-formula --explain $cmd 2>/dev/null)

    if [ -z "$txt" ]; then
        echo $"$cmd: command not found"
        return 127
    fi

    echo "$txt"
}
