

def assigned_to(id): id as $id |
  select(.fields.assignee.key == $id);

def status_except(desc): desc as $desc |
  select(.fields.status.name != $desc);

def summary_heading:
  if .fields.flagged then "\u001b[1;33m  \u001b[0m" else " * " end;

def summary:
  summary_heading + .key + " " * (9-(.key|length)) + .fields.summary;

def cnt:
  [.issues[] | .key ] | map(. | length);
