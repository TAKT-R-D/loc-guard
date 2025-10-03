# LOC Guard Toolkit

Keep your Pull Request Small.

```
└── github
    ├─ loc-guard.yml
    └─ pr_collector.sh
```

## Usage

### pr_collector.sh

Script for easily analyzing LT and LOC from PR, with GitHub API GraphQL.

Place `pr_collector.sh` under your repo.

```bash
$ chmod +x ./pr_collector.sh

$ gh auth login
$ ./pr_collector.sh

## or GITHUB_TOKEN='ghp=xxxx' ./pr_collector.sh
```

Then analyze.

Bi-weekly Frinday checkpoints - 4 weeks sliding window spreadsheet sample is [here](https://docs.google.com/spreadsheets/d/1E8MId7hNxVKRXhJw8MhevY4KTE6ghr8iOZIsu7rpXyM/edit?usp=sharing).

### loc-guard.yml

Place `loc-guard.yml` under your `.github/workflows/`, then GitHub Actions hooks your PR.

#### Configurations

See `on:branches-ignore:` and `env:` sections.
