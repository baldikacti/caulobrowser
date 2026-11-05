# CauloChat env vars, all unset; tests set the ones they need.
caulochat_env_unset <- c(
  CAULOCHAT_CONFIG = NA,
  CAULOCHAT_PROVIDER = NA,
  CAULOCHAT_MODEL = NA,
  CAULOCHAT_BASE_URL = NA,
  CAULOCHAT_API_KEY = NA
)

# Clear every CAULOCHAT_* var and the cached QueryChat for the calling test,
# then apply `...` (named env vars). The cache is cleared again on exit so the
# next test builds its own client.
local_caulochat_env <- function(..., .env = parent.frame()) {
  vars <- caulochat_env_unset
  extra <- c(...)
  vars[names(extra)] <- extra
  withr::local_envvar(vars, .local_envir = .env)
  caulochat_reset()
  withr::defer(caulochat_reset(), envir = .env)
  invisible(NULL)
}

# A configured but offline client: building it makes no network calls.
local_caulochat_config <- function(.env = parent.frame()) {
  local_caulochat_env(
    CAULOCHAT_PROVIDER = "openai_compatible",
    CAULOCHAT_MODEL = "test-model",
    CAULOCHAT_BASE_URL = "http://127.0.0.1:9/v1",
    CAULOCHAT_API_KEY = "dummy-test-key",
    .env = .env
  )
}
