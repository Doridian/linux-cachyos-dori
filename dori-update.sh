#!/usr/bin/env bash
set -xeuo pipefail

git fetch --all
git checkout main
git reset --hard origin/main
git rebase -i upstream/master
git push -f
