function fish_command_not_found
    set -l cmd $argv[1]
    set -l txt (brew which-formula --explain $cmd 2> /dev/null)

    if test -z "$txt"
        __fish_default_command_not_found_handler $cmd
    else
        string collect $txt
    end
end

function __fish_command_not_found_handler --on-event fish_command_not_found
    fish_command_not_found $argv
end
