test_that("mod_caulochat_ui works", {
  local_caulochat_config()
  # Building the UI must not need the database.
  ui <- mod_caulochat_ui(id = "test")
  golem::expect_shinytaglist(ui)
  fmls <- formals(mod_caulochat_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_caulochat_server has correct formals", {
  fmls <- formals(mod_caulochat_server)
  expect_true("id" %in% names(fmls))
})

test_that("QueryChat registers every data-dict table", {
  test_db_path()
  local_caulochat_config()
  qc <- caulochat_register_tables(make_caulochat_qc())
  expect_setequal(qc$table_names(), caulochat_tables)

  dict <- yaml::read_yaml(
    system.file("prompts", "data-dict.yaml", package = "caulobrowser")
  )
  expect_setequal(names(dict$tables), caulochat_tables)
})

test_that("UI is chat-first with a results drawer and transcript download", {
  local_caulochat_config()
  html <- as.character(mod_caulochat_ui(id = "test"))
  qc_id <- make_caulochat_qc()$id
  expect_match(html, paste0("test-", qc_id, "-chat"), fixed = TRUE)
  for (out in c("test-dt", "test-sql", "test-results_title", "test-download_transcript")) {
    expect_match(html, out, fixed = TRUE)
  }
})

test_that("the model and provider are shown under the chat input", {
  local_caulochat_config()
  html <- as.character(mod_caulochat_ui(id = "test"))
  footer <- regmatches(
    html,
    regexpr("<shiny-chat-footer>.*?</shiny-chat-footer>", html)
  )
  expect_length(footer, 1)
  expect_match(footer, "caulochat-model", fixed = TRUE)
  expect_match(footer, "test-model", fixed = TRUE)
  expect_match(footer, "OpenAI-compatible", fixed = TRUE)
})

test_that("the API key never reaches the UI", {
  local_caulochat_config()
  html <- as.character(mod_caulochat_ui(id = "test"))
  expect_false(grepl("dummy-test-key", html, fixed = TRUE))
})

test_that("chat server starts without a database", {
  local_caulochat_config()
  local_mocked_bindings(get_db_connection = function() stop("no database"))

  expect_no_error(testServer(mod_caulochat_server, session$flushReact()))
  expect_length(.qc_cache$qc$table_names(), 0)
})

test_that("without an LLM provider the chat is disabled with instructions", {
  local_caulochat_env()
  expect_message(qc <- make_caulochat_qc(), "CauloChat disabled")
  expect_null(qc)
  expect_false(.qc_cache$status$enabled)

  html <- as.character(mod_caulochat_ui(id = "test"))
  expect_match(html, "CauloChat is unavailable", fixed = TRUE)
  expect_match(html, "No LLM provider is configured", fixed = TRUE)
  expect_match(html, "CAULOCHAT_PROVIDER", fixed = TRUE)
  expect_no_match(html, "test-download_transcript", fixed = TRUE)

  expect_no_error(testServer(mod_caulochat_server, session$flushReact()))
})

test_that("a bad provider disables the chat and shows the reason", {
  local_caulochat_env(CAULOCHAT_PROVIDER = "not_a_provider")
  html <- suppressMessages(as.character(mod_caulochat_ui(id = "test")))
  expect_match(html, "CauloChat is unavailable", fixed = TRUE)
  expect_match(html, "Unknown CauloChat provider", fixed = TRUE)
})

test_that("a failed client build is retried on the next call", {
  local_caulochat_env(CAULOCHAT_PROVIDER = "not_a_provider")
  expect_null(suppressMessages(make_caulochat_qc()))

  withr::local_envvar(
    CAULOCHAT_PROVIDER = "openai_compatible",
    CAULOCHAT_MODEL = "test-model",
    CAULOCHAT_BASE_URL = "http://127.0.0.1:9/v1"
  )
  expect_false(is.null(suppressMessages(make_caulochat_qc())))
})

test_that("filtering a table opens the results drawer", {
  test_db_path()
  local_caulochat_config()
  invisible(make_caulochat_qc())
  opened <- character(0)
  local_mocked_bindings(
    chat_drawer_show = function(id, ...) opened <<- c(opened, id),
    .package = "shinychat"
  )
  testServer(mod_caulochat_server, {
    session$flushReact()
    expect_length(opened, 0)

    # Stand-in for the LLM's filter tool call (the public accessor is
    # read-only; querychat's own app sets queries the same way).
    qc_vals$.tables$genes$sql("SELECT * FROM genes WHERE gene_name = 'ftsZ'")
    session$flushReact()
    expect_equal(opened, paste0(make_caulochat_qc()$id, "-chat"))
    expect_equal(nrow(current_table()$df()), 1)
  })
})

test_that("download_transcript produces a markdown file before any conversation", {
  test_db_path()
  local_caulochat_config()
  # mod_caulochat_ui() populates the process-level QueryChat singleton used by
  # mod_caulochat_server(); mirror that startup order here.
  invisible(make_caulochat_qc())
  testServer(
    mod_caulochat_server,
    {
      session$flushReact()
      path <- output$download_transcript
      expect_match(basename(path), "^caulochat-.*\\.md$")

      transcript <- paste(readLines(path), collapse = "\n")
      expect_true(grepl("# CauloChat Transcript", transcript, fixed = TRUE))
      expect_true(grepl("## Assistant", transcript, fixed = TRUE))
      expect_false(grepl("No conversation recorded", transcript, fixed = TRUE))
    }
  )
})
