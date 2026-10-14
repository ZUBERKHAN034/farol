[[ -o interactive && -t 1 && -n ${FAROL_INPUT_POSITION_FILE:-} && -r $FAROL_INPUT_POSITION_FILE && -z ${TMUX:-} && -z ${STY:-} ]] || return

_farol_input_position() { IFS= read -r REPLY < "$FAROL_INPUT_POSITION_FILE"; }

_farol_apply_input_position() {
    local position lines
    _farol_input_position
    position=$REPLY
    lines=${LINES:-24}
    if [[ $position != $_farol_last_position ]]; then
        printf '\e[r'
        _farol_last_position=$position
        case $position in
            bottom) (( lines > 1 )) && printf '\e[1;%dr' "$((lines - 1))" ;;
        esac
    fi
    case $position in
        top) printf '\e[r' ;;
        bottom) printf '\e[%d;1H' "$lines" ;;
        reverse) (( lines > 1 )) && printf '\e[2;%dr\e[1;1H' "$lines" ;;
    esac
}

_farol_before_command() {
    local position
    _farol_input_position
    position=$REPLY
    case $position in
        bottom) printf '\e[%d;1H' "$(( ${LINES:-24} - 1 ))" ;;
        reverse) printf '\e[r\e[2;1H' ;;
        *) printf '\e[r' ;;
    esac
}

_farol_clear_screen() { zle .clear-screen; _farol_apply_input_position; }
_farol_resize() { _farol_last_position=; _farol_apply_input_position; }
_farol_prepare_prompt() { zle -N clear-screen _farol_clear_screen 2>/dev/null; }

if (( $+functions[TRAPWINCH] )); then
    functions[_farol_previous_TRAPWINCH]=$functions[TRAPWINCH]
fi
TRAPWINCH() {
    _farol_resize
    (( $+functions[_farol_previous_TRAPWINCH] )) && _farol_previous_TRAPWINCH "$@"
}

typeset -g _farol_last_position=
typeset -ga precmd_functions preexec_functions
autoload -Uz add-zsh-hook
precmd_functions+=(_farol_apply_input_position _farol_prepare_prompt)
preexec_functions+=(_farol_before_command)
