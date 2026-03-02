# https://just.systems

version := `Rscript -e "cat(read.dcf('DESCRIPTION')[,'Version'])"`

# Compile R package into tar.gz
build_r:
    R CMD build .

build_readme:
    Rscript -e "devtools::build_readme()"

# Build base docker container
build_docker_base: build_r
    docker build --platform linux/amd64,linux/arm64 -f Dockerfile_base -t baldikacti/caulobrowser_base:latest .

# Build runtime docker container
build_docker_runtime: build_docker_base
    docker build --platform linux/amd64,linux/arm64 -f Dockerfile -t baldikacti/caulobrowser:latest -t baldikacti/caulobrowser:{{version}} .

# Push the docker container to DockerHub
push_docker: build_docker_runtime
    docker push -a baldikacti/caulobrowser

# Runs the Caulobrowser app from docker
run_docker:
    docker run \
        --rm \
        -p 3838:3838 \
        -v /Users/baldikacti/webapp-dev/caulobrowser_data/caulobrowser.duckdb:/database/caulobrowser.duckdb \
        baldikacti/caulobrowser:latest