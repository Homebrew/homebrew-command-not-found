#! /bin/bash

__test_homebrew_command_not_found() {

  local homebrew_root="$HOME/homebrew"
  local ret=
  local output=

  export PATH="${homebrew_root}/bin:$PATH"

  echo "Installing Homebrew"
  git clone --depth 1 https://github.com/Homebrew/homebrew.git $homebrew_root

  echo "which brew:"
  which brew
  if [ "$?" -ne "0" ]; then
    echo "Failure: can't find Homebrew"
    exit 1
  fi

  echo "Installing homebrew-command-not-found"
  mkdir -p $homebrew_root/Library/Taps/homebrew
  cp -r . $homebrew_root/Library/Taps/homebrew/homebrew-command-not-found

  for sh in bash zsh; do
    echo "Testing with $sh"

    # -e: exit on first error
    # -x: trace
    # -c: execute the command
    $sh -exc 'eval "$(brew command-not-found-init)"; when' 2>&1 \
      | tee .out \
      | grep -q "brew install when"
    ret="$?"
    cat .out
    if [ "$ret" -ne "0" ]; then
      exit 1
    fi
    rm -f .out
  done
}

__test_homebrew_command_not_found $*
