
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Caulobrowser <img src="inst/app/www/favicon.ico" align="right" height="50"/>

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Codecov test
coverage](https://codecov.io/gh/baldikacti/caulobrowser/graph/badge.svg)](https://app.codecov.io/gh/baldikacti/caulobrowser)
[![R-CMD-check](https://github.com/baldikacti/caulobrowser/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/baldikacti/caulobrowser/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**CauloBrowser** is an interactive Shiny application for browsing and
visualizing curated high-throughput experimental data for *Caulobacter
crescentus*. It reimplements and extends the original
[CauloBrowser](https://doi.org/10.1093/nar/gkv1050) web resource using
modern R tooling.

The hosted app can be found at: <https://caulobrowser.org>

## Installation

``` r
# Install from GitHub
remotes::install_github("baldikacti/caulobrowser")
```

## Quick Start

### Without Docker (R)

1.  Download the database using
    [Pelican](https://docs.pelicanplatform.org/install):

``` bash
pelican object get 'osdf:///unity-hpc/caulobrowser/caulobrowser.duckdb?directread' .
```

This downloads the app database to the current directory. (Dot
represents current directory)

2.  Run the app:

``` r
# The app has no bundled database; CAULOBROWSER_DB_PATH must point to yours
Sys.setenv("CAULOBROWSER_DB_PATH" = "/path/to/caulobrowser.duckdb")
caulobrowser::run_app()
# Or during development:
golem::run_dev()
```

### With Docker

The app can be launched with Docker without any other dependencies.

1.  Install Docker from
    [docs.docker.com/engine/install](https://docs.docker.com/engine/install/)
    and make sure the Docker daemon is running.

2.  Download the Caulobrowser database into `~/Downloads/` (or any other
    path):

``` bash
docker run --rm \
  -v ~/Downloads:/output \
  ghcr.io/baldikacti/caulobrowser:latest \
  pelican object get 'osdf:///unity-hpc/caulobrowser/caulobrowser.duckdb?directread' /output
```

> The database file will be saved to `~/Downloads/caulobrowser.duckdb`
> on your machine.

3.  Run the app, mounting the downloaded database file:

``` bash
docker run --rm -p 3838:3838 \
  -v ~/Downloads/caulobrowser.duckdb:/database/caulobrowser.duckdb \
  ghcr.io/baldikacti/caulobrowser:latest
```

> Open `http://localhost:3838` in your browser.

## Configuring CauloChat

CauloChat, the AI chat tab, works with any LLM provider that
[ellmer](https://ellmer.tidyverse.org) supports. Examples include a
LiteLLM or other OpenAI-compatible gateway, local Ollama, Anthropic,
OpenAI and Google Gemini. If no provider is configured, the tab shows
setup instructions and the rest of the app works as normal.

Set these environment variables, or put the same settings in a YAML file
and point `CAULOCHAT_CONFIG` at it. An environment variable overrides
the matching field in the file.

| Variable | Meaning |
|----|----|
| `CAULOCHAT_PROVIDER` | `openai_compatible`, `ollama`, `anthropic`, `openai`, `google_gemini`, `vllm`, `openrouter`, … (any `ellmer::chat_*()` suffix). Aliases: `litellm`, `gemini`, `claude`. |
| `CAULOCHAT_MODEL` | Model name as the provider knows it |
| `CAULOCHAT_BASE_URL` | Endpoint URL; required for `openai_compatible`/`litellm` and `vllm` |
| `CAULOCHAT_API_KEY` | API key. If unset, the provider’s own variable is used (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, …) |
| `CAULOCHAT_CONFIG` | Path to a YAML config file (see [`inst/caulochat-config.example.yml`](inst/caulochat-config.example.yml)) |

Examples:

``` bash
# LiteLLM (or any OpenAI-compatible gateway)
CAULOCHAT_PROVIDER=litellm
CAULOCHAT_MODEL=qwen3-8-27b
CAULOCHAT_BASE_URL=https://litellm.example.org/v1
CAULOCHAT_API_KEY=sk-...

# Local Ollama (no key). From inside Docker use http://host.docker.internal:11434
CAULOCHAT_PROVIDER=ollama
CAULOCHAT_MODEL=qwen3:8b

# Anthropic
CAULOCHAT_PROVIDER=anthropic
CAULOCHAT_MODEL=claude-sonnet-5-5
CAULOCHAT_API_KEY=sk-ant-...

# OpenAI
CAULOCHAT_PROVIDER=openai
CAULOCHAT_MODEL=gpt-5
CAULOCHAT_API_KEY=sk-...
```

In a YAML file, use `api_key_env: MY_KEY_VAR` to name the variable that
holds the key, so the key itself stays out of the file. With Docker,
pass the variables with `-e` (or `--env-file`), or mount the YAML file
read-only and set `CAULOCHAT_CONFIG` to its path in the container. The
client is built once when the app starts, so restart the app after
changing the settings.

## Project Structure

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for a full directory
overview.

## Database Schema

See [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for the full schema and
index definitions.

## Development Team

CauloBrowser is developed through a collaboration between:

- **Berent Aldikacti**, Research Computing & Data, University of
  Massachusetts
- **Peter Chien**, Chien Lab, University of Massachusetts
- **Jared Schrader**, Schrader Lab, Indiana University
- **Vincent Ayobami**, Schrader Lab, Indiana University

## References

Lasker, K., Schrader, J.M., Men, Y., Marshik, T., Dill, D.L., McAdams,
H.H., & Shapiro, L. (2016). CauloBrowser: A systems biology resource for
*Caulobacter crescentus*. *Nucleic Acids Research, 44*(D1), D640–D645.
<https://doi.org/10.1093/nar/gkv1050>

## License

MIT

## Code of Conduct

Please note that the caulobrowser project is released with a
[Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
