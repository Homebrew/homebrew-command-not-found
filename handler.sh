#
# brew-command-not-found script for macOS
#
# Usage: Source it somewhere in your .bashrc (bash) or .zshrc (zsh)
#
# Author: Baptiste Fontaine
# URL: https://github.com/Homebrew/homebrew-command-not-found
# License: MIT
# Version: 0.2.0
#

if ! which brew >/dev/null; then return; fi

homebrew_command_not_found_handle() {

  local cmd="$1"

  # The code below is based off this Linux Journal article:
  #   http://www.linuxjournal.com/content/bash-command-not-found

  # do not run when inside Midnight Commander or within a Pipe, except if CI
  if test -z "${CONTINUOUS_INTEGRATION}" && test -n "${MC_SID}" -o ! -t 1
  then
    [[ -n "${BASH_VERSION}" ]] &&
      TEXTDOMAIN=command-not-found echo $"${cmd}: command not found"
    # Zsh versions 5.3 and above don't print this for us.
    [[ -n "${ZSH_VERSION}" ]] && [[ "${ZSH_VERSION}" > "5.2" ]] &&
      echo "zsh: command not found: ${cmd}" >&2
    return 127
  fi

  if [[ "${cmd}" != "-h" ]] && [[ "${cmd}" != "--help" ]] && [[ "${cmd}" != "--usage" ]] && [[ "${cmd}" != "-?" ]]
  then
    local txt="$(brew which-formula --explain "${cmd}" 2>/dev/null)"
  fi

  if [[ -z "${txt}" ]]
  then
    [[ -n "${BASH_VERSION}" ]] &&
      TEXTDOMAIN=command-not-found echo $"${cmd}: command not found"

    # Zsh versions 5.3 and above don't print this for us.
    [[ -n "${ZSH_VERSION}" ]] && [[ "${ZSH_VERSION}" > "5.2" ]] &&
      echo "zsh: command not found: ${cmd}" >&2
  else
    echo "${txt}"
  fi

  return 127
}

if [[ -n "${BASH_VERSION}" ]]
then
  command_not_found_handle() {
    homebrew_command_not_found_handle "$*"
    return $?
  }
elif [[ -n "${ZSH_VERSION}" ]]
then
  command_not_found_handler() {
    homebrew_command_not_found_handle "$*"
    return $?
  }
fi
