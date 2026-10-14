if [[ $- != *i* || ! -t 1 || -z ${FAROL_INPUT_POSITION_FILE:-} || ! -r $FAROL_INPUT_POSITION_FILE || -n ${TMUX:-} || -n ${STY:-} ]]; then
  return 0 2>/dev/null || exit 0
fi

__farol_input_position() { IFS= read -r REPLY < "$FAROL_INPUT_POSITION_FILE"; }

__farol_apply_input_position() {
  local position lines
  __farol_input_position
  position=$REPLY
  lines=${LINES:-24}
  if [[ $position != ${__farol_last_position:-} ]]; then
    printf '\e[r'
    __farol_last_position=$position
    if [[ $position == bottom && $lines -gt 1 ]]; then
      printf '\e[1;%dr' "$((lines - 1))"
    fi
  fi
  case $position in
    top) printf '\e[r' ;;
    bottom) printf '\e[%d;1H' "$lines" ;;
    reverse) (( lines > 1 )) && printf '\e[2;%dr\e[1;1H' "$lines" ;;
  esac
}

__farol_before_command() {
  local position
  __farol_input_position
  position=$REPLY
  case $position in
    bottom) printf '\e[%d;1H' "$(( ${LINES:-24} - 1 ))" ;;
    reverse) printf '\e[r\e[2;1H' ;;
    *) printf '\e[r' ;;
  esac
}

__farol_clear_screen() {
  printf '\e[2J\e[H'
  __farol_apply_input_position
}

__farol_resize() { __farol_last_position=; __farol_apply_input_position; }

if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == "declare -a"* ]]; then
  PROMPT_COMMAND+=(__farol_apply_input_position)
else
  PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }__farol_apply_input_position"
fi
PS0+='$(__farol_before_command)'
bind -x '"\C-l": __farol_clear_screen'

__farol_previous_winch=$(trap -p WINCH)
if [[ -n $__farol_previous_winch ]]; then
  __farol_previous_winch=${__farol_previous_winch#trap -- }
  __farol_previous_winch=${__farol_previous_winch% SIGWINCH}
  eval "__farol_previous_winch=$__farol_previous_winch"
fi
trap '__farol_resize; [[ -n $__farol_previous_winch ]] && eval "$__farol_previous_winch"' WINCH
