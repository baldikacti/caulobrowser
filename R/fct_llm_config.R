#' Provider name aliases accepted in CauloChat configuration.
#' @noRd
caulochat_provider_aliases <- c(
  litellm = "openai_compatible",
  gemini = "google_gemini",
  claude = "anthropic"
)

#' Normalise a provider name to the suffix of an `ellmer::chat_*()` function.
#' @noRd
normalise_provider <- function(provider) {
  provider <- nz_string(provider)
  if (is.null(provider)) {
    return(NULL)
  }
  provider <- gsub("-", "_", tolower(provider), fixed = TRUE)
  if (provider %in% names(caulochat_provider_aliases)) {
    provider <- caulochat_provider_aliases[[provider]]
  }
  provider
}

#' Read the CauloChat LLM configuration
#'
#' Resolves each field from, in order of precedence: the `CAULOCHAT_PROVIDER`,
#' `CAULOCHAT_MODEL`, `CAULOCHAT_BASE_URL` and `CAULOCHAT_API_KEY` environment
#' variables, then the YAML file named by `CAULOCHAT_CONFIG`. The API key falls
#' back from `CAULOCHAT_API_KEY` to the env var named by `api_key_env` in the
#' file, then to `api_key` in the file, then to NULL (the provider's own
#' default env var, e.g. `ANTHROPIC_API_KEY`).
#'
#' @param config_path Path to a YAML file; empty for none.
#'
#' @return A list with `provider`, `model`, `base_url`, `api_key` and `params`;
#'   unset fields are NULL.
#' @noRd
caulochat_llm_config <- function(
  config_path = get_golem_config("caulochat_config")
) {
  file_cfg <- list()
  config_path <- nz_string(config_path)
  if (!is.null(config_path)) {
    if (!file.exists(config_path)) {
      stop(
        "CauloChat config file not found: ",
        config_path,
        " (set by CAULOCHAT_CONFIG).",
        call. = FALSE
      )
    }
    file_cfg <- yaml::read_yaml(config_path) %||% list()
    if (!is.list(file_cfg)) {
      stop(
        "CauloChat config file must be a YAML mapping: ",
        config_path,
        call. = FALSE
      )
    }
  }

  env <- function(name) nz_string(Sys.getenv(name))

  key_env_name <- nz_string(file_cfg$api_key_env)
  api_key <- env("CAULOCHAT_API_KEY") %||%
    (if (!is.null(key_env_name)) env(key_env_name)) %||%
    nz_string(file_cfg$api_key)

  params <- file_cfg$params
  if (!is.null(params) && !is.list(params)) {
    stop("`params` in the CauloChat config must be a mapping.", call. = FALSE)
  }

  list(
    provider = normalise_provider(
      env("CAULOCHAT_PROVIDER") %||% file_cfg$provider
    ),
    model = env("CAULOCHAT_MODEL") %||% nz_string(file_cfg$model),
    base_url = env("CAULOCHAT_BASE_URL") %||% nz_string(file_cfg$base_url),
    api_key = api_key,
    params = if (length(params)) params else NULL
  )
}

#' Build an ellmer chat client from a CauloChat configuration
#'
#' @param cfg A list as returned by [caulochat_llm_config()].
#'
#' @return An `ellmer::Chat`, or NULL when no provider is configured.
#' @noRd
caulochat_build_client <- function(cfg) {
  provider <- cfg$provider
  if (is.null(provider)) {
    return(NULL)
  }

  exports <- getNamespaceExports("ellmer")
  fn_name <- paste0("chat_", provider)
  if (!fn_name %in% exports) {
    valid <- sort(sub("^chat_", "", grep("^chat_", exports, value = TRUE)))
    stop(
      "Unknown CauloChat provider '",
      provider,
      "'. Use one of: ",
      paste(c(valid, names(caulochat_provider_aliases)), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  fn <- getExportedValue("ellmer", fn_name)

  key <- cfg$api_key
  args <- list(
    model = cfg$model,
    base_url = cfg$base_url,
    credentials = if (!is.null(key)) function() key,
    params = if (!is.null(cfg$params)) do.call(ellmer::params, cfg$params)
  )
  args <- args[!vapply(args, is.null, logical(1))]

  unsupported <- setdiff(names(args), names(formals(fn)))
  if (length(unsupported)) {
    warning(
      "CauloChat provider '",
      provider,
      "' does not accept: ",
      paste(unsupported, collapse = ", "),
      "; ignoring.",
      call. = FALSE
    )
    args <- args[setdiff(names(args), unsupported)]
  }

  do.call(fn, args)
}

#' Provider and model shown under the chat input, taken from the built client
#' so provider-chosen default models are reported too.
#'
#' @param client An `ellmer::Chat`.
#' @return A list with `provider` (display name) and `model`.
#' @noRd
caulochat_model_info <- function(client) {
  list(
    provider = client$get_provider()@name,
    model = client$get_model()
  )
}

#' One-line, secret-free description of a CauloChat configuration for logs.
#' @noRd
caulochat_describe <- function(cfg) {
  paste0(
    cfg$provider %||% "<none>",
    " / ",
    cfg$model %||% "<provider default model>",
    if (!is.null(cfg$base_url)) paste0(" @ ", cfg$base_url) else ""
  )
}
