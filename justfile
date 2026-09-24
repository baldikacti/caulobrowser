# https://just.systems

version := `Rscript -e "cat(read.dcf('DESCRIPTION')[,'Version'])"`
r_version := `Rscript -e "cat(renv::lockfile_read()\$R\$Version)"`
image := "ghcr.io/baldikacti/caulobrowser"
base_image := "ghcr.io/baldikacti/caulobrowser-base"

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

# Build base docker container
build_docker_base:
    docker build --platform linux/arm64,linux/amd64 --build-arg R_VERSION={{r_version}} -f Dockerfile_base -t {{base_image}}:latest .

# Build runtime docker container
build_docker_runtime arg: build_r
    docker build --platform linux/arm64,linux/amd64 --build-arg BASE_IMAGE={{arg}} -f Dockerfile -t {{image}}:latest -t {{image}}:{{version}} .

# Push the docker container to GHCR (requires `docker login ghcr.io`)
push_docker:
    docker push -a {{image}}

# Runs the Caulobrowser app from docker
run_docker database_path:
    docker run \
        --rm \
        -p 3838:3838 \
        -v {{database_path}}:/database/caulobrowser.duckdb \
        {{image}}:{{version}}

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
    msg=$(awk "/^# caulobrowser {{version}}/{found=1; next} found && /^# /{exit} found{print}" NEWS.md | sed '/^$/d')
    if [ -z "$msg" ]; then
        echo "No NEWS.md entry found for {{version}}"; exit 1
    fi
    git tag -a "$tag" -m "$msg"
    git push origin "$tag"

# Create a new release from the latest tag (Requires gh CLI)
create_release:
    gh release create v{{version}} --notes-from-tag
