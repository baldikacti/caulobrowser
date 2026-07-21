test_that("format_chat_transcript shows placeholder when nothing to export", {
  txt <- format_chat_transcript(turns = list())
  expect_true(grepl("No conversation recorded", txt))
  expect_false(grepl("## Assistant", txt))
})

test_that("format_chat_transcript includes greeting when no turns exist", {
  txt <- format_chat_transcript(turns = list(), greeting = "<p>Hi there</p>")
  expect_true(grepl("## Assistant", txt, fixed = TRUE))
  expect_true(grepl("Hi there", txt, fixed = TRUE))
  expect_false(grepl("No conversation recorded", txt))
})

test_that("format_chat_transcript renders user turn before assistant turn", {
  turns <- list(
    ellmer::Turn(
      role = "user",
      contents = list(ellmer::ContentText("What genes are essential?"))
    ),
    ellmer::Turn(
      role = "assistant",
      contents = list(ellmer::ContentText("Here they are."))
    )
  )
  txt <- format_chat_transcript(turns = turns)
  expect_true(grepl("What genes are essential?", txt, fixed = TRUE))
  expect_true(grepl("Here they are.", txt, fixed = TRUE))
  expect_lt(regexpr("## User", txt, fixed = TRUE), regexpr("## Assistant", txt, fixed = TRUE))
})

test_that("format_chat_transcript skips turns with no text content", {
  turns <- list(
    ellmer::Turn(
      role = "assistant",
      contents = list(ellmer::ContentToolRequest(id = "1", name = "foo", arguments = list()))
    )
  )
  txt <- format_chat_transcript(turns = turns)
  expect_true(grepl("No conversation recorded", txt))
  expect_equal(lengths(regmatches(txt, gregexpr("## Assistant", txt, fixed = TRUE))), 0)
})

test_that("format_chat_transcript captures the SQL behind a querychat_update_dashboard tool call", {
  turns <- list(
    ellmer::Turn(
      role = "assistant",
      contents = list(
        ellmer::ContentToolRequest(
          id = "1",
          name = "querychat_update_dashboard",
          arguments = list(query = "SELECT * FROM genes WHERE essential", title = "Essential genes")
        )
      )
    )
  )
  txt <- format_chat_transcript(turns = turns)
  expect_true(grepl("## Assistant", txt, fixed = TRUE))
  expect_true(grepl("**Query:** Essential genes", txt, fixed = TRUE))
  expect_true(grepl("SELECT * FROM genes WHERE essential", txt, fixed = TRUE))
  expect_false(grepl("No conversation recorded", txt))
})

test_that("format_chat_transcript captures the ggsql behind a querychat_visualize tool call", {
  turns <- list(
    ellmer::Turn(
      role = "assistant",
      contents = list(
        ellmer::ContentToolRequest(
          id = "1",
          name = "querychat_visualize",
          arguments = list(ggsql = "SELECT gene_id VISUALISE gene_id DRAW bar", title = "Gene counts")
        )
      )
    )
  )
  txt <- format_chat_transcript(turns = turns)
  expect_true(grepl("**Visualization:** Gene counts", txt, fixed = TRUE))
  expect_true(grepl("VISUALISE gene_id DRAW bar", txt, fixed = TRUE))
})

test_that("format_chat_transcript drops tool-result-only turns entirely", {
  tool_request <- ellmer::ContentToolRequest(
    id = "1", name = "querychat_update_dashboard",
    arguments = list(query = "SELECT 1", title = "x")
  )
  turns <- list(
    ellmer::Turn(
      role = "user",
      contents = list(ellmer::ContentToolResult(value = "ok", request = tool_request))
    )
  )
  txt <- format_chat_transcript(turns = turns)
  expect_true(grepl("No conversation recorded", txt))
  expect_false(grepl("## User", txt, fixed = TRUE))
})

test_that("format_chat_transcript adds dashboard title line only when non-blank", {
  txt_with_title <- format_chat_transcript(turns = list(), title = "Essential genes")
  expect_true(grepl("**Dashboard title:** Essential genes", txt_with_title, fixed = TRUE))

  txt_no_title <- format_chat_transcript(turns = list(), title = "   ")
  expect_false(grepl("Dashboard title", txt_no_title, fixed = TRUE))

  txt_null_title <- format_chat_transcript(turns = list(), title = NULL)
  expect_false(grepl("Dashboard title", txt_null_title, fixed = TRUE))
})

test_that("chat_export_filename falls back to a generic name without a title", {
  fname <- chat_export_filename()
  expect_match(fname, "^caulochat-transcript-\\d{8}-\\d{6}\\.md$")
})

test_that("chat_export_filename slugifies a provided title", {
  fname <- chat_export_filename(title = "My Dashboard!")
  expect_match(fname, "^caulochat-my-dashboard-\\d{8}-\\d{6}\\.md$")
})

test_that("chat_export_filename ignores a whitespace-only title", {
  fname <- chat_export_filename(title = "   ")
  expect_match(fname, "^caulochat-transcript-\\d{8}-\\d{6}\\.md$")
})
