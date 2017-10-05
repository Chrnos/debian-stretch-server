#!/bin/bash

# set editor, augment history behavior, enable dynamic resize in visual terminals
export EDITOR=vim
export HISTFILE=~/.bash_history
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize

# colors for enhanced prompt
c_bold="\033[1m"
c_red="\033[31m"
c_green="\033[32m"
c_blue="\033[34m"
c_purple="\033[35m"
c_cyan="\033[36m"
c_sgr0="\033[0m"

# promptify is an updated prompt enhancement enabled by default
promptify() {
	local prompt_string
	prompt_string="${c_blue}${0} ($(date +'%R:%S.%3N')::${timer_show}s) ${c_purple}$(whoami)${c_sgr0}@${c_green}$(hostname) ${c_bold}${c_blue}$(dirs)${c_sgr0}"

	if git rev-parse --git-dir &> /dev/null; then
		git_branch=$(git branch 2> /dev/null | sed -n 's/^\*[ ]*//p')
		git_stats=$(git status --porcelain --untracked-files=all 2> /dev/null)
		if [ $(echo "${git_stats}" | sed '/^\s*$/d' | wc -l) -gt 0 ]; then
			prompt_string="${prompt_string} [${c_red}${git_branch}${c_sgr0}"
			untracked_count=$(echo "${git_stats}" | grep -ce "^??")
			new_file_count=$(echo "${git_stats}" | grep -ce "^A ")
			renamed_count=$(echo "${git_stats}" | grep -ce "^R ")
			modified_staged_count=$(echo "${git_stats}" | grep -ce "^M ")
			modified_unstaged_count=$(echo "${git_stats}" | grep -ce "^ M")
			deleted_staged_count=$(echo "${git_stats}" | grep -ce "^D ")
			deleted_unstaged_count=$(echo "${git_stats}" | grep -ce "^ D")
			[ $(($untracked_count + $new_file_count + $renamed_count + $modified_staged_count + $modified_unstaged_count + $deleted_staged_count + $deleted_unstaged_count)) -gt 0 ] && prompt_string="${prompt_string}:"
			[ $untracked_count -gt 0 ] && prompt_string="${prompt_string} ${c_red}u${untracked_count}${c_sgr0}"
			[ $new_file_count -gt 0 ] && prompt_string="${prompt_string} ${c_green}a${new_file_count}${c_sgr0}"
			[ $renamed_count -gt 0 ] && prompt_string="${prompt_string} ${c_green}r${renamed_count}${c_sgr0}"
			[ $modified_unstaged_count -gt 0 ] || [ $modified_staged_count -gt 0 ] && prompt_string="${prompt_string} ${c_red}m${c_sgr0}"
			[ $modified_unstaged_count -gt 0 ] && prompt_string="${prompt_string}${c_red}${modified_unstaged_count}${c_sgr0}" && [ $modified_staged_count -gt 0 ] && prompt_string="${prompt_string}/"
			[ $modified_staged_count -gt 0 ] && prompt_string="${prompt_string}${c_green}${modified_staged_count}${c_sgr0}"
			[ $deleted_unstaged_count -gt 0 ] || [ $deleted_staged_count -gt 0 ] && prompt_string="${prompt_string} ${c_red}d${c_sgr0}"
			[ $deleted_unstaged_count -gt 0 ] && prompt_string="${prompt_string}${c_red}${deleted_unstaged_count}${c_sgr0}" && [ $deleted_staged_count -gt 0 ] && prompt_string="${prompt_string}/"
			[ $deleted_staged_count -gt 0 ] && prompt_string="${prompt_string}${c_green}${deleted_staged_count}${c_sgr0}"
			prompt_string="${prompt_string}]"
		else
			prompt_string="${prompt_string} [${c_green}${git_branch}${c_sgr0}]"
		fi
	fi
	echo -ne "\n${prompt_string}\n$ "
}

# time every command
timer_start() {
	timer=${timer:-$SECONDS}
}
timer_stop() {
	timer_show=$(($SECONDS - $timer))
	unset timer
}
trap 'timer_start' DEBUG

# apply prompt enhancements
PS2='continue-> '
PS1='$(promptify)'
if [ -z "$PROMPT_COMMAND" ]; then
	PROMPT_COMMAND="timer_stop"
else
	PROMPT_COMMAND="$PROMPT_COMMAND; timer_stop"
fi

# enable bash complation
. /etc/bash_completion

# pretty man pages
man() {
	env \
		LESS_TERMCAP_md=$'\e[1;36m' \
		LESS_TERMCAP_me=$'\e[0m' \
		LESS_TERMCAP_se=$'\e[0m' \
		LESS_TERMCAP_so=$'\e[1;40;92m' \
		LESS_TERMCAP_ue=$'\e[0m' \
		LESS_TERMCAP_us=$'\e[1;32m' \
			man "$@"
}

# explicitly set XDG DATA DIRS
[ -z "$XDG_DATA_DIRS" ] && export XDG_DATA_DIRS="/usr/share:/usr/local/share"
export XDG_DATA_DIRS="$XDG_DATA_DIRS:$HOME/.local/share"

# set aliases with color and performance optimizations
alias ls='ls -vhFA --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias sshfs='sshfs -o cache=yes,compression=yes,large_read,kernel_cache'

# load or synchronize default ssh keys using shared ssh agent socket file (eg. keychain equivalent)
ssh-add -l &> /dev/null; sshout=$?
[ $sshout -eq 0 ] || export SSH_AUTH_SOCK=~/.ssh/socket
if [ $sshout -eq 2 ]; then
	rm -f $SSH_AUTH_SOCK
	eval $(ssh-agent -a $SSH_AUTH_SOCK 2> /dev/null) &> /dev/null
	ssh-add 2> /dev/null
elif [ $sshout -eq 1 ]; then
	ssh-add 2> /dev/null
fi
