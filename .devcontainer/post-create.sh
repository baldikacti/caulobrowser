#!/usr/bin/env bash
set -euo pipefail

# Project library (.rvenv/lib) from rproj.lock, main + dev groups, plus the
# caulobrowser package itself. RIG_MODE=user (set in the image), so if the
# R version rproj.lock names is missing, rig installs it into HOME first.
rig proj sync --frozen
rig library list | grep -qw '^tools' || rig library add tools
rig pkg install --library tools languageserver
