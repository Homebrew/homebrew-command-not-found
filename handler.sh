#
# brew-command-not-found script for OS X
#
# Usage: Source it somewhere in your .bashrc(bash) or .zshrc(zsh)
#
# Author: Baptiste Fontaine
# URL: https://github.com/bfontaine/homebrew-command-not-found
# License: MIT
# Version: 0.2.0
#

if ! which brew > /dev/null; then return; fi

homebrew_command_not_found_handle() {

    local cmd="$1"

    # <from Linux Journal>
    #   http://www.linuxjournal.com/content/bash-command-not-found

    # do not run when inside Midnight Commander or within a Pipe
    if test -n "$MC_SID" -o ! -t 1 ; then
        [ -n "$BASH_VERSION" ] && \
            TEXTDOMAIN=command-not-found echo $"$cmd: command not found"
        return 127
    fi

    # </from Linux Journal>

    local txt="$(brew which-formula --explain $cmd 2>/dev/null)"

    if [ -z "$txt" ]; then
        [ -n "$BASH_VERSION" ] && \
            TEXTDOMAIN=command-not-found echo $"$cmd: command not found"
    else
        echo "$txt"
    fi

    return 127
}

if [ -n "$BASH_VERSION" ]; then
    command_not_found_handle() {
        homebrew_command_not_found_handle $*
        return $?
    }
elif [ -n "$ZSH_VERSION" ]; then
    command_not_found_handler() {
        homebrew_command_not_found_handle $*
        return $?
    }
fi
