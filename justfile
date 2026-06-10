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
    Rscript -e "devtools::test()"

# Build base docker container
build_docker_base:
    docker build --platform linux/amd64,linux/arm64 -f Dockerfile_base -t baldikacti/caulobrowser_base:latest .

# Build runtime docker container
build_docker_runtime:
    docker build --platform linux/amd64,linux/arm64 -f Dockerfile -t baldikacti/caulobrowser:latest -t baldikacti/caulobrowser:{{version}} .

# Push the docker container to DockerHub
push_docker:
    docker push -a baldikacti/caulobrowser

# Runs the Caulobrowser app from docker
run_docker:
    docker run \
        --rm \
        -p 3838:3838 \
        -v /Users/baldikacti/webapp-dev/caulobrowser/caulobrowser.duckdb:/database/caulobrowser.duckdb \
        baldikacti/caulobrowser:{{version}}

# Tag release from DESCRIPTION version with NEWS.md entry as message
tag_release:
    #!/usr/bin/env bash
    set -euo pipefail
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