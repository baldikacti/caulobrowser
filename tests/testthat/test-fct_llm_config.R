write_config <- function(lines, .env = parent.frame()) {
  path <- withr::local_tempfile(fileext = ".yml", .local_envir = .env)
  writeLines(lines, path)
  path
}

test_that("nothing configured gives an empty config and no client", {
  local_caulochat_env()
  cfg <- caulochat_llm_config()
  expect_null(cfg$provider)
  expect_null(cfg$model)
  expect_null(cfg$base_url)
  expect_null(cfg$api_key)
  expect_null(caulochat_build_client(cfg))
})

test_that("the YAML file alone configures the client", {
  local_caulochat_env(LLM_TEST_KEY = "file-env-key")
  path <- write_config(c(
    "provider: litellm",
    "model: qwen3-8-27b",
    "base_url: https://gateway.example.org/v1",
    "api_key_env: LLM_TEST_KEY",
    "params:",
    "  temperature: 0.2"
  ))
  cfg <- caulochat_llm_config(path)
  expect_equal(cfg$provider, "openai_compatible")
  expect_equal(cfg$model, "qwen3-8-27b")
  expect_equal(cfg$base_url, "https://gateway.example.org/v1")
  expect_equal(cfg$api_key, "file-env-key")
  expect_equal(cfg$params, list(temperature = 0.2))

  chat <- caulochat_build_client(cfg)
  expect_s3_class(chat, "Chat")
  expect_equal(chat$get_model(), "qwen3-8-27b")
})

test_that("CAULOCHAT_CONFIG is read through golem config", {
  path <- write_config(c("provider: ollama", "model: qwen3:8b"))
  local_caulochat_env(CAULOCHAT_CONFIG = path)
  cfg <- caulochat_llm_config()
  expect_equal(cfg$provider, "ollama")
  expect_equal(cfg$model, "qwen3:8b")
})

test_that("env vars override the YAML file field by field", {
  local_caulochat_env(
    CAULOCHAT_MODEL = "env-model",
    CAULOCHAT_API_KEY = "env-key",
    LLM_TEST_KEY = "file-env-key"
  )
  path <- write_config(c(
    "provider: openai_compatible",
    "model: file-model",
    "base_url: https://file.example.org/v1",
    "api_key_env: LLM_TEST_KEY",
    "api_key: file-key"
  ))
  cfg <- caulochat_llm_config(path)
  expect_equal(cfg$provider, "openai_compatible")
  expect_equal(cfg$model, "env-model")
  expect_equal(cfg$base_url, "https://file.example.org/v1")
  expect_equal(cfg$api_key, "env-key")
})

test_that("the API key falls back from api_key_env to api_key", {
  local_caulochat_env()
  path <- write_config(c(
    "provider: anthropic",
    "api_key_env: UNSET_CAULOCHAT_TEST_KEY",
    "api_key: file-key"
  ))
  expect_equal(caulochat_llm_config(path)$api_key, "file-key")
})

test_that("provider names are normalised and aliases resolve", {
  expect_equal(normalise_provider("LiteLLM"), "openai_compatible")
  expect_equal(normalise_provider("gemini"), "google_gemini")
  expect_equal(normalise_provider("claude"), "anthropic")
  expect_equal(normalise_provider("google-gemini"), "google_gemini")
  expect_null(normalise_provider(""))
  expect_null(normalise_provider(NULL))
})

test_that("an unknown provider errors and lists the valid ones", {
  expect_error(
    caulochat_build_client(list(provider = "nope")),
    "Unknown CauloChat provider 'nope'.*anthropic.*ollama"
  )
})

test_that("common providers build without network access", {
  cases <- list(
    list(provider = "openai_compatible", model = "m1", base_url = "http://127.0.0.1:9/v1"),
    list(provider = "anthropic", model = "claude-test"),
    list(provider = "openai", model = "gpt-test")
  )
  for (cfg in cases) {
    cfg$api_key <- "dummy"
    chat <- caulochat_build_client(cfg)
    expect_s3_class(chat, "Chat")
    expect_equal(chat$get_model(), cfg$model)
  }
})

test_that("an unreachable Ollama server is reported", {
  # chat_ollama() checks the server while building the client.
  expect_error(
    caulochat_build_client(list(
      provider = "ollama",
      model = "llama-test",
      base_url = "http://127.0.0.1:9"
    )),
    "ollama"
  )
})

test_that("arguments a provider does not take are dropped with a warning", {
  expect_warning(
    chat <- caulochat_build_client(list(
      provider = "openrouter",
      model = "some/model",
      base_url = "https://ignored.example.org",
      api_key = "dummy"
    )),
    "does not accept: base_url"
  )
  expect_s3_class(chat, "Chat")
})

test_that("a missing or malformed config file errors clearly", {
  local_caulochat_env()
  expect_error(
    caulochat_llm_config(file.path(tempdir(), "no-such-file.yml")),
    "config file not found"
  )
  expect_error(
    caulochat_llm_config(write_config("just a string")),
    "must be a YAML mapping"
  )
  expect_error(
    caulochat_llm_config(write_config(c("provider: openai", "params: 3"))),
    "`params`.*mapping"
  )
})

test_that("model info comes from the built client", {
  chat <- caulochat_build_client(list(
    provider = "anthropic",
    model = "claude-test",
    api_key = "dummy"
  ))
  expect_equal(
    caulochat_model_info(chat),
    list(provider = "Anthropic", model = "claude-test")
  )
})

test_that("the log description never contains the key", {
  cfg <- list(
    provider = "openai_compatible",
    model = "m",
    base_url = "https://x.example.org/v1",
    api_key = "secret-key"
  )
  desc <- caulochat_describe(cfg)
  expect_equal(desc, "openai_compatible / m @ https://x.example.org/v1")
  expect_false(grepl("secret-key", desc, fixed = TRUE))
})
