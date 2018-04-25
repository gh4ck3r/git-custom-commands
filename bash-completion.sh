#!/bin/false bash

if [[ $0 == $BASH_SOURCE ]];then
  echo "$0 is meant to be sourced"
  exit 1;
fi

# Main completion routine for git is at
# /usr/share/bash-completion/completions/git
function _git_hooks()
{
  if ! __gitdir >/dev/null;then
    # Not a git repository
    COMPREPLY=""
    return
  fi

  # Fore more detail : http://githooks.com/
  local hooks="applypatch-msg
    pre-applypatch
    post-applypatch
    pre-commit
    prepare-commit-msg
    commit-msg
    post-commit
    pre-rebase
    post-checkout
    post-merge
    pre-receive
    update
    post-receive
    post-update
    pre-auto-gc
    post-rewrite
    pre-push"
  __gitcomp "$hooks"
}

function _git_rebaseall()
{
  if ! __gitdir >/dev/null;then
    # Not a git repository
    COMPREPLY=""
    return
  fi

  __gitcomp_nl "$(__git_heads)"
}
