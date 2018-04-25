#!/bin/false bash
# Avoid invoked as subshell. This SHOULD BE sourced
[[ ${BASH_SOURCE[0]} == $0 ]] && exit 1

__SYSLOG_TAG="ANC-githook[${1:-$(basename $SHELL)}]"

# See following for deatils about levels
#   https://en.wikipedia.org/wiki/Syslog#Severity_level

function sysdebug() {
  local msg;if [[ $# == 0 ]];then read -rd '' msg;else msg=$@; fi;
  logger -t "$__SYSLOG_TAG"  -p local0.debug -- $msg
  [[ -v DEBUG ]] || return 0;
  echo -e "\e[90;1m[D] $msg\e[0m" >&2
}

function syslog() {
  local msg;if [[ $# == 0 ]];then read -rd '' msg;else msg=$@; fi;
  logger -t "$__SYSLOG_TAG" -p local0.notice -- $msg
  [[ -v DEBUG ]] || return 0;
  echo -e "\e[99;1m[L] $msg\e[0m" >&2
}

function syserr() {
  local msg;if [[ $# == 0 ]];then read -rd '' msg;else msg=$@; fi;
  logger -t "$__SYSLOG_TAG" -p local0.err -- $msg
  [[ -v DEBUG ]] || [[ $- = *i* ]] || return 0;
  echo -e "\e[91;1m[E] $msg\e[0m" >&2
}

function syswarn() {
  local msg;if [[ $# == 0 ]];then read -rd '' msg;else msg=$@; fi;
  logger -t "$__SYSLOG_TAG" -p local0.warning -- $msg
  [[ -v DEBUG ]] || [[ $- = *i* ]] || return 0;
  echo -e "\e[93;1m[W] $msg\e[0m" >&2
}

