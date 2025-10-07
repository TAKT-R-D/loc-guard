#!/usr/bin/env zsh
# --------------------------------------------
# mr_collector.sh  ── merged MR の created_at, merged_at, LOC を CSV で出力
# 使い方 : GITLAB_TOKEN=xx ./mr_collector.sh  > mr_loc_merged.csv
#   * deploy*, release*, master* へマージされる MR は除外
#   * 出力形式: iid,created_at,merged_at,loc
# --------------------------------------------
set -euo pipefail

PID="$(glab repo view -F json 2>/dev/null | jq -r .id)"

echo "iid,created_at,merged_at,loc"

glab api --paginate "/projects/${PID}/merge_requests?state=merged&per_page=100" 2>/dev/null |
jq -r '
  .[]
  | select((.target_branch | test("^(deploy|release|master)"; "i")) | not)
  | "\(.iid)\t\(.created_at)\t\(.merged_at)"
' |
while IFS=$'\t' read -r IID CREATED MERGED; do
  loc="$(
    glab api "/projects/${PID}/merge_requests/${IID}/changes" 2>/dev/null |
    jq -r '.changes[].diff' |
    grep -E '^[+-]' | grep -vE '^[+-]{3}' |
    wc -l | tr -d '[:space:]'
  )"
  echo "${IID},${CREATED},${MERGED},${loc}"
done
