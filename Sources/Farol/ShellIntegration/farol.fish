if not status --is-interactive; or not test -t 1; or not set -q FAROL_INPUT_POSITION_FILE; or not test -r "$FAROL_INPUT_POSITION_FILE"; or set -q TMUX; or set -q STY
    return
end

function __farol_input_position
    read -l position < "$FAROL_INPUT_POSITION_FILE"
    echo $position
end

function __farol_apply_input_position
    set -l position (__farol_input_position)
    set -l size (stty size 2>/dev/null | string split ' ')
    set -l lines $size[1]
    test -n "$lines"; or set lines $LINES
    test -n "$lines"; or set lines 24
    if test "$position" != "$__farol_last_position"
        printf '\e[r'
        set -g __farol_last_position $position
        if test "$position" = bottom; and test $lines -gt 1
            printf '\e[1;%dr' (math $lines - 1)
        end
    end
    switch $position
        case top
            printf '\e[r'
        case bottom
            printf '\e[%d;1H' $lines
        case reverse
            if test $lines -gt 1
                printf '\e[2;%dr\e[1;1H' $lines
            end
    end
end

function __farol_before_command --on-event fish_preexec
    switch (__farol_input_position)
        case reverse
            printf '\e[r\e[2;1H'
        case bottom
            printf '\e[%d;1H' (math $LINES - 1)
        case '*'
            printf '\e[r'
    end
end

function __farol_position_prompt --on-event fish_prompt
    __farol_apply_input_position
end

function __farol_clear_screen
    printf '\e[2J\e[H'
    __farol_apply_input_position
    commandline -f repaint
end

function __farol_resize --on-signal WINCH
    set -g __farol_last_position
    __farol_apply_input_position
end

set -g __farol_last_position
bind \\cl __farol_clear_screen
