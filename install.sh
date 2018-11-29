#!/bin/bash

function setup_git_custom_commands()
{
  local git_custom_cmds=($(dirname $BASH_SOURCE)/git-*);
  if [[ $git_custom_cmds == */git-\* ]];then
    echo "No git custom command found" >&2
    return;
  fi

  local git_exec_path_proxy=$HOME/.git-exec-path-proxy;
  if [[ -d $git_exec_path_proxy ]];then
    if [[ $0 == $BASH_SOURCE ]];then
      cat <<MSG
$0 should be sourced rather than executed to use GIT_EXEC_PATH environment variable
MSG
      return 254
    fi
    export GIT_EXEC_PATH=$git_exec_path_proxy
  fi
  local git_exec_path=$(git --exec-path)

  # Remove already planted commands
  local i;
  local cmd_cnt=${#git_custom_cmds[@]}
  for ((i=0;i<$cmd_cnt;++i));do
    local cmd=${git_custom_cmds[$i]}
    [[ $(readlink -e "$git_exec_path/$(basename $cmd)") = $(readlink -e $cmd) ]] &&
      unset git_custom_cmds[$i];
  done
  ((${#git_custom_cmds[@]})) || return 0;

  local cmd_prefix;
  if [[ -w $git_exec_path ]]; then
    :
  elif sudo -l id >&- 2>&- ;then
    cmd_prefix="sudo"
  elif [[ $git_exec_path_proxy != $GIT_EXEC_PATH ]]; then
    echo "Make Git exec-path proxy : $git_exec_path_proxy"
    [[ -d $git_exec_path_proxy ]] || mkdir -p $git_exec_path_proxy
    for f in $git_exec_path/*; do
      if [[ $(readlink -e $git_exec_path_proxy/$(basename $f)) = $f ]];then continue;fi
      ln -s $f $git_exec_path_proxy/
    done
    unset f
    git_exec_path=$git_exec_path_proxy
    export GIT_EXEC_PATH=$git_exec_path_proxy
  fi

  # Cache sudo password first if necessary
  [[ $cmd_prefix = "sudo" ]] &&
    sudo -p "[sudo] enter password to plant ${#git_custom_cmds[@]} git custom command(s) to $git_exec_path : " [ ]

  echo "Planting ${#git_custom_cmds[@]} git custom command(s) into $git_exec_path"
  for cmd in ${git_custom_cmds[@]};do
    echo -en "  * \033[91;1m$(basename $cmd)\033[0m"
    $cmd_prefix ln -s $(readlink -e $cmd) $git_exec_path/ 2>&- && echo " -- Ok" || echo " -- Failed"
  done
  unset cmd
}
setup_git_custom_commands
unset setup_git_custom_commands
