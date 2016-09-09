function _common_section
    printf $c1
    printf $argv[1]
    printf $c0
    printf ":"
    printf $c2
    printf $argv[2]
    printf $argv[3]
    printf $cg
    printf " · "
end

function section
    _common_section $argv[1] $c3 $argv[2] $ce
end

function error
    _common_section $argv[1] $ce $argv[2] $ce
end

function git_branch
    set -g git_branch (git rev-parse --abbrev-ref HEAD ^ /dev/null)
    if [ $status -ne 0 ]
        set -ge git_branch
        set -g git_dirty_count 0
    else
        set -g git_dirty_count (git status --porcelain  | wc -l | sed "s/ //g")
    end
end

function fish_prompt --description 'Write out the prompt'
	# $status gets nuked as soon as something else is run, e.g. set_color
    # so it has to be saved asap.
    set -l last_status $status

    # c0 to c4 progress from dark to bright
    # ce is the error colour
	# cg is grey
    set -g c0 (set_color 005284)
    set -g c1 (set_color 0075cd)
    set -g c2 (set_color 009eff)
    set -g c3 (set_color 6dc7ff)
    set -g c4 (set_color ffffff)
    set -g ce (set_color $fish_color_error)
	set -g cg (set_color 666666)

    # Clear the line because fish seems to emit the prompt twice. The initial
    # display, then when you press enter.
    printf "\033[K"
	
	printf "$cg——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————\n"

    if [ $last_status -ne 0 ]
        error last $last_status
        set -ge status
    end

    # Show last execution time if it took long enough
    set taken $CMD_DURATION
    if test $taken
		set units ms
		if test $taken -gt 2000
			set taken (math $taken / 1000)
			set units s
		end
        error taken $taken$units
    end

    # Show loadavg when too high
    set -l load1m (uptime | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
    set -l load1m_test (math $load1m \* 100 / 1)
    if test $load1m_test -gt 500
        error load $load1m
    end

    # Show disk usage when low
    set -l du (df / | tail -n1 | sed "s/  */ /g" | cut -d' ' -f 5 | cut -d'%' -f1)
    if test $du -gt 80
        error du $du%%
    end

    # Git branch and dirty files
    git_branch
    if set -q git_branch
        set out $git_branch
        if test $git_dirty_count -gt 0
            set out "$out$c0:$ce$git_dirty_count"
        end
        section git $out
    end

    # Current Directory
    # 1st sed for colourising forward slashes
    # 2nd sed for colourising the deepest path (the 'm' is the last char in the
    # ANSI colour code that needs to be stripped)
    printf $c1
    printf (pwd | sed "s,/,$c0/$c1,g" | sed "s,\(.*\)/[^m]*m,\1/$c3,")

    # Prompt on a new line
    printf $cg
    printf "\n> "
end
