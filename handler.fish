function command-not-found
	set -l cmd "$argv[2]"
	set -l txt (brew which-formula --explain $cmd ^/dev/null)
	
	if test -z "$txt"
		__fish_default_command_not_found_handler $cmd
	else
		echo "$txt"
	end
end
