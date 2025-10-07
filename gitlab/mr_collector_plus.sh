#!/usr/bin/env zsh
# --------------------------------------------
# mr_collector.sh  ── merged MR の created_at, merged_at, LOC を CSV で出力
# 使い方 : GITLAB_TOKEN=xx ./mr_collector.sh  > mr_loc_merged.csv
#   * deploy*, release*, master* へマージされる MR は除外
#   * vendor/**, node_modules/**, dist/**, public/build/**, storage/**,
#     *.min.*, 各種 lock ファイル 等を除外
#   * 出力形式: iid,created_at,merged_at,loc
# --------------------------------------------
set -euo pipefail

PID="$(glab repo view -F json 2>/dev/null | jq -r .id)"

# 除外パターン（必要に応じて調整）
# 例: migrations も除外するなら先頭に (database/migrations/|) を追加
EXCLUDE_RE='^(vendor/|node_modules/|public/build/|storage/|dist/)|(\.min\.[^/]+$)|(^|/)(composer\.lock|package-lock\.json|yarn\.lock|pnpm-lock\.yaml)$'

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
    jq -r --arg re "$EXCLUDE_RE" '
      [
        .changes[]
        # new_path / old_path のどちらにも除外パターンが当たらないファイルだけ対象
        | select( (.new_path | test($re) | not) and (.old_path | test($re) | not) )
        # 各ファイルの diff から + / - 行（ただし +++ / --- ヘッダは除外）をカウント
        | ( .diff // ""                          # null セーフ
            | split("\n")
            | map(select(
                (startswith("+") or startswith("-"))
                and (.[0:3] != "+++" and .[0:3] != "---")
              ))
            | length
          )
      ] | add // 0
    '
  )"
  echo "${IID},${CREATED},${MERGED},${loc}"
done
