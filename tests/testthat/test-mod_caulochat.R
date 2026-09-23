test_that("mod_caulochat_ui works", {
  # Building the UI creates the QueryChat singleton, which opens the database.
  test_db_path()
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
  qc <- make_caulochat_qc()
  expect_setequal(qc$table_names(), caulochat_tables)

  dict <- yaml::read_yaml(
    system.file("prompts", "data-dict.yaml", package = "caulobrowser")
  )
  expect_setequal(names(dict$tables), caulochat_tables)
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
