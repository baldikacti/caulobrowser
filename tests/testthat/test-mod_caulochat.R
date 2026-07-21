test_that("mod_caulochat_ui works", {
  ui <- mod_caulochat_ui(id = "test")
  golem::expect_shinytaglist(ui)
  fmls <- formals(mod_caulochat_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_caulochat_server has correct formals", {
  fmls <- formals(mod_caulochat_server)
  for (i in c("id", "db_con")) {
    expect_true(i %in% names(fmls))
  }
})

# mod_caulochat_ui() populates the process-level QueryChat singleton used by
# mod_caulochat_server(); mirror that startup order here.
invisible(make_caulochat_qc())

test_that("download_transcript produces a markdown file before any conversation", {
  testServer(
    mod_caulochat_server,
    args = list(
      db_con = shiny::reactiveVal(DBI::dbConnect(
        duckdb::duckdb(),
        system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
      ))
    ),
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
