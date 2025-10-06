#!/usr/bin/env zsh
set -euo pipefail

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)"
OWNER="${REPO%%/*}"
NAME="${REPO##*/}"

echo "id,created_at,merged_at,loc"

AFTER="null"

# Exclude patterns for files not to be counted in LOC:
# - directories: vendor/**, node_modules/**, public/build/**, storage/**, dist/**
# - minified: *.min.*
# - lock files: composer.lock, package-lock.json, yarn.lock, pnpm-lock.yaml
EXCLUDE_RE='^(vendor/|node_modules/|public/build/|storage/|dist/)|(\.min\.[^/]+$)|(^|/)(composer\.lock|package-lock\.json|yarn\.lock|pnpm-lock\.yaml)$'

while :; do
    # GraphQL Query：get latest 100 MERGED PRs
  RESP="$(
    gh api graphql -F owner="$OWNER" -F name="$NAME" -F after="$AFTER" -f query='
      query($owner:String!, $name:String!, $after:String) {
        repository(owner:$owner, name:$name) {
          pullRequests(states:MERGED, orderBy:{field:UPDATED_AT, direction:DESC}, first:100, after:$after) {
            pageInfo { hasNextPage endCursor }
            nodes {
              number
              createdAt
              mergedAt
              baseRefName
            }
          }
        }
      }
    ' 2>/dev/null
  )"

  echo "$RESP" \
  | jq -r '
      .data.repository.pullRequests.nodes[]
      | select((.baseRefName | test("^(deploy|release|main)($|/)", "i")) | not)
      | "\(.number)\t\(.createdAt)\t\(.mergedAt)"
    ' \
  | while IFS=$'\t' read -r NUM CREATED MERGED; do
      # Paginate PR changed files and sum additions/deletions excluding files matching EXCLUDE_RE
      LOC="$(
        gh api --paginate "/repos/${REPO}/pulls/${NUM}/files?per_page=100" 2>/dev/null \
        | jq -r --arg re "$EXCLUDE_RE" '
            (type=="array" ? . : [.])    # 念のため配列化
            | [ .[] | select( (.filename | test($re)) | not ) ]
            | (map(.additions) | add // 0) + (map(.deletions) | add // 0)
          '
      )"

      echo "${NUM},${CREATED},${MERGED},${LOC}"
    done

  HAS_NEXT="$(echo "$RESP" | jq -r '.data.repository.pullRequests.pageInfo.hasNextPage')"
  if [ "$HAS_NEXT" != "true" ]; then
    break
  fi
  AFTER="$(echo "$RESP" | jq -r '.data.repository.pullRequests.pageInfo.endCursor' | jq -Rs .)"
done
