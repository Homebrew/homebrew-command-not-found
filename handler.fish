function __fish_command_not_found_on_interactive --on-event fish_prompt
    functions --erase __fish_command_not_found_handler
    functions --erase __fish_command_not_found_setup

    function fish_command_not_found
        set -l cmd $argv[1]
        set -l txt (brew which-formula --explain $cmd 2> /dev/null)

        if test -z "$txt"
            __fish_default_command_not_found_handler $cmd
        else
            # https://github.com/fish-shell/fish-shell/issues/159
            for var in $txt
                echo $var
            end
        end
    end

    function __fish_command_not_found_handler --on-event fish_command_not_found
        fish_command_not_found $argv
    end

    functions --erase __fish_command_not_found_on_interactive
end
