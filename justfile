# https://just.systems

version := `Rscript -e "cat(read.dcf('DESCRIPTION')[,'Version'])"`

# Clean deployments
clean:
    rm -rf deploy

# Compile R package into tar.gz
build_r: clean
    mkdir deploy
    R CMD build .
    mv caulobrowser_{{version}}.tar.gz deploy/caulobrowser_{{version}}.tar.gz

# Compile README
build_readme:
    Rscript -e "devtools::build_readme()"

# Build checks
check:
    Rscript -e "devtools::check()"

# Run Unit tests
test:
    Rscript -e "devtools::test(reporter = 'summary')"

# Run the app locally with docker compose (extra flags pass through, e.g. --build)
run_docker *args:
    docker compose --env-file .env up {{args}}

# Stop and remove the local docker compose containers
stop_docker:
    docker compose --env-file .env down

# Bump version in DESCRIPTION and add a NEWS.md heading (major, minor, patch, dev)
bump which="minor":
    Rscript -e "usethis::use_version('{{which}}')"

# Fast-forward main to dev, push main, then tag and push the release
release:
    #!/usr/bin/env bash
    set -euo pipefail
    git diff --quiet && git diff --cached --quiet || { echo "Uncommitted changes"; exit 1; }
    git fetch origin
    git checkout dev && git merge --ff-only origin/dev
    git checkout main && git merge --ff-only origin/main && git merge --ff-only dev
    git push origin main
    just tag_release
    git checkout dev

# Tag release from DESCRIPTION version with NEWS.md entry as message
tag_release:
    #!/usr/bin/env bash
    set -euo pipefail
    [ "$(git branch --show-current)" = "main" ] || { echo "Not on main"; exit 1; }
    git diff --quiet && git diff --cached --quiet || { echo "Uncommitted changes"; exit 1; }
    git fetch origin
    [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "main is not in sync with origin/main"; exit 1; }
    tag="v{{version}}"
    if git rev-parse "$tag" >/dev/null 2>&1; then
        echo "Tag $tag already exists"; exit 1
    fi
    msg=$(awk "/^# caulobrowser {{version}}/{found=1; next} found && /^# /{exit} found{print}" NEWS.md | sed '/./,$!d')
    if [ -z "$msg" ]; then
        echo "No NEWS.md entry found for {{version}}"; exit 1
    fi
    git tag -a "$tag" --cleanup=verbatim -m "caulobrowser {{version}}" -m "$msg"
    git push origin "$tag"

# Create a new release from the latest tag (Requires gh CLI)
create_release:
    gh release create v{{version}} --title "v{{version}}" --notes-from-tag
