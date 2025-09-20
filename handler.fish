# The user needs to migrate to the Homebrew/brew handler
echo "Warning: Homebrew's command-not-found integration is out of date."
echo "Please update your shell configuration to the new instructions printed by:"
echo "  brew command-not-found-init"

function fish_command_not_found
    set -l cmd $argv[1]
    set -l txt

    if not contains -- "$cmd" "-h" "--help" "--usage" "-?"
        set txt (brew which-formula --explain $cmd 2> /dev/null)
    end

    if test -z "$txt"
        __fish_default_command_not_found_handler $cmd
    else
        string collect $txt
    end
end

function __fish_command_not_found_handler --on-event fish_command_not_found
    fish_command_not_found $argv
end
