# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=10000
HISTFILESIZE=9000

shopt -s checkwinsize

IMPORTANT="$HOME/IMPORTANT"

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

#force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    ps1Time="\[\033[38;5;13m\][\[$(tput sgr0)\]\[\033[38;5;11m\]\t\[$(tput sgr0)\]\[\033[38;5;13m\]]\[$(tput sgr0)\]"
    ps1User="\[$(tput sgr0)\]\[\033[38;5;14m\]\u\[$(tput sgr0)\]\[\033[38;5;13m\]"
    ps1Path="\[$(tput sgr0)\]\[\033[38;5;10m\]\w\[$(tput sgr0)\]"
    ps1Dollar="\[$(tput sgr0)\]\[\033[38;5;13m\]\\$\[$(tput sgr0)\]"
    # [22:18:51] myname@~ $ ..command
    export PS1="$ps1Time $ps1User@$ps1Path $ps1Dollar "
else
    export PS1="[\t] \u@\w \\$ \[$(tput sgr0)\] "
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

if [[ -s $(which java) ]]; then
    alias jj="java -jar"
fi

if [[ -s $(which wine) ]]; then
    alias wine32cp1251='export LC_ALL="ru_RU.cp1251"; WINEARCH=win32 wine '
    alias winecp1251='export LC_ALL="ru_RU.cp1251"; wine '
    alias wineutf8='export LC_ALL="ru_RU.utf8"; wine '
fi

if [[ -s $(which notify-send) ]]; then
    alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
fi

# Ленивый гитпуш
# gall commit_name
# gall "commit name"
if [[ -s $(which git) ]]; then
    alias gall='f(){ git add --all .; git commit -m "$@"; git push; }; f '
    alias gitr='git --recursive '
fi

if [[ -s $(which systemctl) ]]; then
    alias running_services='systemctl list-units --type=service --state=running'
fi

if [[ -s $(which globalprotect) ]]; then
    alias global-ui="globalprotect launch-ui"
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


if [[ -d $HOME/go ]]; then
    export GOPATH="$HOME/go"
    export PATH="$PATH:$HOME/go/bin"
fi

# Дополнительные утилиты на разных дисках, в основном разработка
# Каждая новая строка добавляется в $PATH
exportAdditionalTools() {
    DISK=$1;
    BINS="$DISK/.MiscSettings/toolBinsPath";
    if [[ -f "$BINS" ]]; then
        while IFS= read -r lineBin; do
            linePath="$DISK/$lineBin"
            if [[ -d $linePath ]]; then
                export PATH="$PATH:$linePath"
            fi
        done < "$BINS"
    fi
}

. $IMPORTANT/git-tokens.env.sh

if [[ -s $(which docker) ]]; then
    # docker login -u "Docker Pull" -p $GIT_REGISTRY_KEY registry.gitlab.com

    alias docker_run='docker run --rm -it -w /projects/ -v "$(pwd)":/projects '
fi


DISK_1GB="/media/$USER/42c99442-8e5f-4b2b-951a-65eab6f62b6d"
DISK_5GB="/media/$USER/dba5566f-66a9-4684-b2f1-98abb258530c"

if [[ -d $DISK_1GB ]]; then
    ESP_VER=$(head -1 "$DISK_1GB/esp/.esp32-current-env")
    alias idf=". $DISK_1GB/esp/$ESP_VER/export.sh"

    exportAdditionalTools $DISK_1GB    
fi

if [[ -d $DISK_5GB ]]; then
    exportAdditionalTools $DISK_5GB 
fi

# Load Angular CLI autocompletion.
if command -v ng &> /dev/null; then
    source <(ng completion script)
fi

# kubectl shell completion
if command -v kubectl &> /dev/null; then
    source <(kubectl completion bash)
    # Создает алиасы на конфиги для быстрого вызова
    # формат: имя_алиса:путь/до/файла
    KUBECONFIGS="$IMPORTANT/kubeconfigs.list"
    if [[ -s $KUBECONFIGS ]]; then
        KUBECONFIGS_LIST=$(cat $KUBECONFIGS)
        for line in $KUBECONFIGS_LIST; do
            record=($(echo $line | tr ":" " "))
            KUBE_CFG="$IMPORTANT/${record[1]}"
            if [[ -s $KUBE_CFG ]]; then
                alias ${record[0]}="kubectl --kubeconfig $KUBE_CFG"
            fi            
        done
    fi
fi