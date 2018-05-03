#!/bin/false bash
# Avoid invoked as subshell. This SHOULD BE sourced
[[ ${BASH_SOURCE[0]} == $0 ]] && exit 1

if ! [[ "$(type -t secret-tool)" == "file" ]];then
  echo "It can be possible to fetch password from stored credential(gnome-keyring)" >&2
  sudo apt install libsecret-tools
fi

ROOT_DIR=${ROOT_DIR:-$(dirname "${BASH_SOURCE[0]}")}
if ! type -t syslog >/dev/null 2>&1;then
  SYSLOG_TAG=${SYSLOG_TAG:-jira}
  . $ROOT_DIR/log.sh
fi

jira_url=${jira_url:-$(git config jira.url)}
if [[ -z $jira_url ]];then
  syserr <<ERROR
Set jira url to git config with "git config jira.url <url>"
ERROR
return 1
fi

function fetch_username()
{
  secret-tool search --unlock signon_realm $jira_url/ 2>&1 | grep username_value
}

if [[ "$(type -t secret-tool)" == "file" ]];then
  username_value=$(fetch_username)
  if [[ $username_value == attribute.gkr:compat:hashed:username_value* ]];then
    username_value=$(fetch_username)
  fi
  IFS=' =' read username_value jira_id <<<$username_value
  unset username_value
  jira_password=$(secret-tool lookup signon_realm $jira_url/ username_value $jira_id)
fi
jira_password=${jira_password:+:${jira_password}}
jira_credential=$jira_id$jira_password
unset jira_password

function CURL() {
  sysdebug <<COMMAND
curl -su $jira_credential -H 'Content-Type: application/json' $@;
COMMAND
  if [[ $- = *i* ]] && [[ -t 1 ]];then
    curl -su $jira_credential -H 'Content-Type: application/json' $@ | jq .;
  else
    curl -su $jira_credential -H 'Content-Type: application/json' $@;
  fi
}

function GET() {
  CURL -X GET $jira_url"$@"
}

function PUT() {
  CURL -X PUT $jira_url"$@"
}

function POST() {
  CURL -X POST $jira_url"$@"
}

function jira-issue() {
  [[ $# == 0 ]] && return;

  local temp_prefix=$(mktemp -u)
  GET /rest/api/2/issue/{$(IFS=,;echo "$*")}?expand=transitions -o "$temp_prefix-#1.json"

  local issue;
  for issue in $@;do
    issue=$temp_prefix-$issue.json;
    cat $issue && rm -f $issue >/dev/null 2>&1
  done
}

# https://docs.atlassian.com/software/jira/docs/api/REST/7.6.1/?_ga=2.246577092.1959139811.1523341361-766559685.1496031775#api/2/issue-assign
function jira-assign()
{
  local data=$(jq -c . <<DATA
{
  "name": "$1"
}
DATA
);

  local issues=(${@:2});
  syslog "Assign $1 to jira issues : ${issues[@]}"

  # DON'T CHANGE "*" to "@" -- https://stackoverflow.com/a/9429887
  http_code=$(PUT /rest/api/2/issue/{$(IFS=,;echo "${issues[*]}")}/assignee -d "$data" -w "%{http_code}")

  # http_code is concatenated when multiple assign is requested
  if ! [[ $http_code =~ ^(204){${#issues[@]}}$ ]];then
    syserr <<ERROR
issues cnt : ${#issues[@]}
Failed to assign $1 to ${@:2} [http_code: $http_code]
ERROR
    return 1;
  fi
  return 0;
}

function jira-transition() {
  if [[ $# < 2 ]];then
    syserr "[jira-transition] Insufficient parameter"
    return 22;  # EINVAL
  fi
  local issue;
  for issue in ${@:2};do
    sysdebug "jira issue transition for $issue"
    local tr_id=$(GET /rest/api/2/issue/$issue/transitions | jq -r ".transitions[] | select(.to.name==\"$1\") | .id");
    sysdebug "  transition id : $tr_id"
    [[ -z $tr_id ]] && continue;
    local data=$(jq -c . <<DATA
{
  "transition": {
    "id":"$tr_id"
  }
}
DATA
);
    local http_code=$(POST /rest/api/2/issue/$issue/transitions -d "$data" -w "%{http_code}")
    [[ $http_code != 204 ]] && syswarn "Failed to transition $issue to \"$1\" [http_code : $http_code]"
  done
}

