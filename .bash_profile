alias ls='ls -G'
alias dir='ls -Gx'
alias ll='ls -alhG'
alias lt='ls -alhGct'

alias ..='cd ../'
alias cd..='cd ../'
alias cdh="cd $HOME"

alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
alias hostip="curl ip.appspot.com; echo"

# set locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# make Anaconda the default python
export PATH="$HOME/anaconda/bin:$PATH"

# add NAO Python SDK to path
export PYTHONPATH="${PYTHONPATH}:$HOME/pynaoqi"
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}:$HOME/pynaoqi"

# add Go to the path
export PATH=$PATH:/usr/local/opt/go/libexec/bin:/~/gocode/bin
export GOPATH=~/gocode

# for shims and autocompletion
if which jenv > /dev/null; then eval "$(jenv init -)"; fi
if [ -f $(brew --prefix)/etc/bash_completion ]; then
. $(brew --prefix)/etc/bash_completion
fi

# Mac-Setup scripts
MAC_SETUP_PATH="$HOME/repos/mac-setup"
# Save to GitHub
mac-setup-save() {
  pushd "$MAC_SETUP_PATH"
  git add --all
  git commit -m "Automatic update of all changes."
  git pull --commit
  git push
  popd
}

# Upgrade all bottles in brew, cleanup, and save status to mac-setup
mac-setup-update-brew() {
  source activate brew
  brew upgrade
  brew cleanup
  brew bundle dump --force --file="$MAC_SETUP_PATH/.Brewfile"
}

# Upgrade all packages in conda and save status to mac-setup
mac-setup-update-conda() {
  source deactivate
  pip install -U --no-deps pydub python_speech_features kur
  rm -fr "$HOME/Library/Caches/pip"
  conda update -y --all
  conda update -y tensorflow
  conda clean -pty
  conda list > "$MAC_SETUP_PATH/.Condafile"
  cp -f "$HOME/.condarc" "$MAC_SETUP_PATH/.condarc"
}

# Update all system configurations and save to GitHub
mac-setup-update-and-save() {
  cp -f "$HOME/.bash_profile" "$MAC_SETUP_PATH/.bash_profile"
  mac-setup-update-brew
  mac-setup-update-conda
  mac-setup-save
}

# to restore stashed changes in brew
brew-restore() {
  pushd "$(brew --prefix)"
  git stash pop
  popd
}

# for resetting brew
brew-reset() {
  sudo chown -R $(whoami):admin "$(brew --prefix)"
  pushd "$(brew --prefix)"
  git fetch origin
  git reset --hard origin/master
  popd
}

# SSH
eval $(ssh-agent -s) > /dev/null

# build prompt
PROMPT_NORMAL="\[$(tput sgr0)\]"
PROMPT_BODY="\[$(tput setaf 8)\]"
PROMPT_MARK="\[$(tput setaf 15)\]"
PROMPT_ROOT="\[$(tput setaf 124)\]"
PROMPT_USER="\[$(tput setaf 166)\]"
PROMPT_HOST="\[$(tput setaf 136)\]"
PROMPT_DIR="\[$(tput setaf 37)\]"
PROMPT_GIT="\[$(tput setaf 33)\]"
get-user-host() {
  local str=""
  local body_color="${PROMPT_BODY}"
  local host_color="${PROMPT_HOST}"
  local user_color="${PROMPT_USER}"
  [[ ${USER} == "root" ]] && user_color="${PROMPT_ROOT}"
  if [[ ! "${5}" == true ]]; then
    body_color=""
    host_color=""
    user_color=""
  fi
  if [[ ${SSH_TTY} ]] || [[ $(id -u) -ne $(id -ur) ]]; then
    str+="${user_color}${1}"
    [[ ${str} ]] && str="${str}${body_color}${2}"
    str+="${host_color}${3}"
    [[ "${str}" ]] && str="${str}${body_color}${4}"
  fi
  echo -n "${str}"
}
get-git-status() {
  local str=""
  local body_color="${PROMPT_BODY}"
  local git_color="${PROMPT_GIT}"
  if [[ ! "${5}" == true ]]; then
    body_color=""
    git_color=""
  fi
  local text="$(git status --porcelain --ignore-submodules --ignored -b 2> /dev/null)"
  if [[ ${text} ]]; then
    local array
    IFS=$'\n' read -d '' -r -a array <<< "${text}"
    local branch=""
    local sum_mod=0
    local sum_add=0
    local sum_del=0
    local sum_unmerge=0
    local sum_untrack=0
    local sum_ignore=0
    for line in "${array[@]}"
    do
      case "${line:0:2}" in
        "##") branch="${line:3}";;
        "AA") ((sum_add++));;
        "DD") ((sum_del++));;
        "UU") ((sum_unmerge++));;
        "UA") ((sum_unmerge++));;
        "UD") ((sum_unmerge++));;
        "AU") ((sum_add++));;
        "DU") ((sum_del++));;
        "??") ((sum_untrack++));;
        "!!") ((sum_ignore++));;
        *) case "${line:0:1}" in
             "M") ((sum_mod++));;
             "A") ((sum_add++));;
             "D") ((sum_del++));;
             "R") ((sum_mod++));;
             "C") ((sum_mod++));;
             " ") case "${line:1:1}" in
                    "M") ((sum_mod++));;
                    "D") ((sum_del++));;
                    *) echo "Invalid Git status code ${line:0:2}.";;
                  esac;;
             *) echo "Invalid Git status code ${line:0:2}.";;
           esac;;
      esac
    done
    local sum_stage=0
    text="$(git diff --shortstat --ignore-submodules --cached 2> /dev/null)"
    if [[ ${text} ]]; then
      sum_stage="${text:1}"
      sum_stage="${sum_stage%% file*}"
    fi
    local sum_stash=0
    text="$(git diff --shortstat refs/stash -- 2> /dev/null)"
    if [[ ${text} ]]; then
      sum_stash="${text:1}"
      sum_stash="${sum_stash%% file*}"
    fi
    local branch_local="${branch%%...*}"
    local branch_remote=""
    if [[ "${branch_local:0:18}" == "Initial commit on " ]]; then
      branch_local="${branch_local:18}"
    else
      [[ "${branch_local}" != "${branch}" ]] && branch_remote="${branch#*...}"
    fi
    local sum_str=""
    [[ ${sum_mod} -gt 0 ]] && sum_str+="${sum_mod} "
    [[ ${sum_add} -gt 0 ]] && sum_str+="${sum_add}+ "
    [[ ${sum_del} -gt 0 ]] && sum_str+="${sum_del}- "
    [[ ${sum_stage} -gt 0 ]] && sum_str+="${sum_stage}! "
    [[ ${sum_unmerge} -gt 0 ]] && sum_str+="${sum_unmerge}u "
    [[ ${sum_untrack} -gt 0 ]] && sum_str+="${sum_untrack}? "
    [[ ${sum_ignore} -gt 0 ]] && sum_str+="${sum_ignore}i "
    [[ ${sum_stash} -gt 0 ]] && sum_str+="${sum_stash}s "
    sum_str="${sum_str% }"
    str+="${body_color}${1}"
    str+="${git_color}${branch_local}"
    if [[ "${branch_remote}" ]]; then
      str+="${body_color}${2}"
      str+="${git_color}${branch_remote}"
    fi
    str+="${body_color}${3}"
    str+="${git_color}${sum_str}"
    str+="${body_color}${4}"
  fi
  echo -n "${str}"
}
get-conda-env() {
  local str=""
  if [[ ${CONDA_DEFAULT_ENV} ]]; then
    str="${1}${CONDA_DEFAULT_ENV}${2}"
  fi
  echo -n "${str}"
}
set-prompt() {
  export PS1="$(get-user-host '\u\' '@' '\h' ':' true)${PROMPT_DIR}\w$(get-git-status ' = ' '<' '[' ']' true)${PROMPT_NORMAL}$(get-conda-env ' (' ')')\n${PROMPT_MARK}\$ ${PROMPT_NORMAL}"
}
export PROMPT_COMMAND=set-prompt
export PS2="${PROMPT_MARK}> ${PROMPT_NORMAL}"

# iTerm shell integration
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
function iterm2_print_user_vars() {
  iterm2_set_user_var gitStatus "$(get-git-status '' ' < ' '\n' '')"
  #iterm2_set_user_var gitBranch $((git status --porcelain -b 2> /dev/null) | head -n1 | cut -c4- | sed 's/\.\.\./</')
}

# added by Anaconda3 4.3.1 installer
export PATH="/Users/j.ylipaavalniemi/anaconda/bin:$PATH"
