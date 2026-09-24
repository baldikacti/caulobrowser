test_that("mod_caulochat_ui works", {
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
  qc <- caulochat_register_tables(make_caulochat_qc())
  expect_setequal(qc$table_names(), caulochat_tables)

  dict <- yaml::read_yaml(
    system.file("prompts", "data-dict.yaml", package = "caulobrowser")
  )
  expect_setequal(names(dict$tables), caulochat_tables)
})

test_that("UI is chat-first with a results drawer and transcript download", {
  html <- as.character(mod_caulochat_ui(id = "test"))
  qc_id <- make_caulochat_qc()$id
  expect_match(html, paste0("test-", qc_id, "-chat"), fixed = TRUE)
  for (out in c("test-dt", "test-sql", "test-results_title", "test-download_transcript")) {
    expect_match(html, out, fixed = TRUE)
  }
})

test_that("chat server starts without a database", {
  # Fresh QueryChat with no tables, restored afterwards.
  old_qc <- .qc_cache$qc
  .qc_cache$qc <- NULL
  on.exit(.qc_cache$qc <- old_qc, add = TRUE)
  local_mocked_bindings(get_db_connection = function() stop("no database"))

  expect_no_error(testServer(mod_caulochat_server, session$flushReact()))
  expect_length(.qc_cache$qc$table_names(), 0)
})

test_that("filtering a table opens the results drawer", {
  test_db_path()
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
