# GitLab

## LOC Guard

Place `loc-guard.yml` in `.gitlab/ci/loc-guard.yml` or similar, and include it at the beginning of `.gitlab-ci.yml` (before the `stages` section). Alternatively, you can append the contents of `loc-guard.yml` directly to `.gitlab-ci.yml`.

```yml:.gitlab-ci.yml
include:
  - local: '.gitlab/ci/loc_guard.yml'

stages: [check]
...
```

### Configurations

- Warn mode (comment only): `GUARD_LEVEL: "0"` (default).
- Block mode (comment + CI failure): Set `GUARD_LEVEL to "1"`.
- Adjust threshold: Change `LOC_THRESHOLD`.
- Exclude base branches: Change `BASE_EXCLUDE_REGEX` (e.g. to add `main`, use `^(deploy|release|master|main)($|/)`).
- Unified exclusion patterns: `EXCLUDE_RE` matches the same conditions as GitHub. Adjust extensions to include/exclude (e.g. `.ts`, `.vue`) as needed.
- Comment posting: To post comments to MR Conversation, create a **Project Access Token (api scope)** and set it to the `GITLAB_ACCESS_TOKEN` variable. If not set, only logs will be output.
  - For security, it is recommended to save the token as **Masked + Protected**.
- Block merging: Enable "Pipelines must succeed" on protected branches to prevent merging when `exit 1` occurs.

## MR Collector

`mr_collector_plus.sh` excludes lock files, vendor files, compiled files etc, execution cost is higher than `mr_collector.sh` a bit.

Hit following command under your repo.

```bash
$ GITLAB_TOKEN=xx ./mr_collector.sh
```
