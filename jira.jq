def digest_issues:
  .issues[] | .key as $key | .fields | {
  "key": $key,
  "summary": .summary,
  "flagged": .flagged,
  "labels": .labels,
  #"issuelinks": .issuelinks,
  "assignee": .assignee,
  "worklog": .worklog,
  "status": .status,
  "subtasks": .subtasks,
  #"issuetype": .issuetype,
  #"description": .description,
};

def assigned_to(id): id as $id |
  select(.assignee.key == $id);

def status_except(desc): desc as $desc |
  select(.status.name != $desc);

def summary_heading:
  if .flagged then "\u001b[1;33m  " else " * " end;

def summary_prefix:
  "\u001b[0m";

def summary_postfix: "\u001b[0m";

def summary_body:
  .key + " " * (9-(.key|length)) + .summary;

def summary:
  summary_heading + summary_prefix + summary_body +  summary_postfix;

#def cnt:
#  [.issues[] | .key ] | map(. | length);
