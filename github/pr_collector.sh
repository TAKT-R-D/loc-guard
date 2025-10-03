#!/usr/bin/env zsh
set -euo pipefail

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)"
OWNER="${REPO%%/*}"
NAME="${REPO##*/}"

echo "id,created_at,merged_at,loc"

AFTER="null"

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
              additions
              deletions
            }
          }
        }
      }
    ' 2>/dev/null
  )"

  echo "$RESP" \
  | jq -r '
      .data.repository.pullRequests.nodes[]
      | select((.baseRefName | test("^(deploy|release|main)"; "i")) | not)
      | [.number, .createdAt, .mergedAt, (.additions + .deletions)]
      | @csv
    ' \
  | sed 's/^"//; s/"$//'

  HAS_NEXT="$(echo "$RESP" | jq -r '.data.repository.pullRequests.pageInfo.hasNextPage')"
  if [ "$HAS_NEXT" != "true" ]; then
    break
  fi
  AFTER="$(echo "$RESP" | jq -r '.data.repository.pullRequests.pageInfo.endCursor' | jq -Rs .)"
done
