# ── search_genes ─────────────────────────────────────────────────────────────

test_that("search_genes finds gene by name", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "CCNA_00090")
  expect_equal(nrow(result), 1)
  expect_equal(result$gene_name, "CCNA_00090")
})

test_that("search_genes finds gene by gene_id (CCNA_ tag)", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "CCNA_00090")
  expect_equal(nrow(result), 1)
  expect_equal(result$gene_id, "CCNA_00090")
})

test_that("search_genes finds gene by cc_tag", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "CC_0092")
  expect_equal(nrow(result), 1)
})

test_that("search_genes accepts comma-separated list of terms", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "CCNA_00090,CCNA_01248")
  expect_equal(nrow(result), 2)
})

test_that("search_genes returns 0 rows for empty query", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "")
  expect_equal(nrow(result), 0)
})

test_that("search_genes returns 0 rows for no match", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "notAGene")
  expect_equal(nrow(result), 0)
})


# ── get_expression_data ───────────────────────────────────────────────────────

test_that("get_expression_data returns correct columns and rows", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_expression_data(con, "CCNA_00090")

  expected_cols <- c(
    "gene_id",
    "experiment_id",
    "experiment_type",
    "display_label",
    "doi",
    "timepoint_minutes",
    "expression_value",
    "condition_label",
    "gene_name",
    "cc_tag"
  )
  expect_true(all(expected_cols %in% colnames(result)))
  expect_gt(nrow(result), 0)
  expect_equal(unique(result$gene_name), "CCNA_00090")
})

test_that("get_expression_data filters by genetic_background", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  all_rows <- get_expression_data(con, "CCNA_00090")
  result <- get_expression_data(
    con,
    "CCNA_00090",
    genetic_background = "wildtype"
  )
  expect_gt(nrow(result), 0)
  expect_lte(nrow(result), nrow(all_rows))

  result_none <- get_expression_data(
    con,
    "CCNA_00090",
    genetic_background = "not_a_background"
  )
  expect_equal(nrow(result_none), 0)
})

test_that("get_expression_data handles multiple gene_ids", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_expression_data(con, c("CCNA_00090", "CCNA_00446"))
  expect_gt(nrow(result), 0)
  expect_equal(length(unique(result$gene_id)), 2)
})


# ── get_timecourse_backgrounds ────────────────────────────────────────────────

test_that("get_timecourse_backgrounds returns timecourse genetic backgrounds", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_timecourse_backgrounds(con)
  expect_type(result, "character")
  expect_true("wildtype" %in% result)
  # de_comparison background must not appear
  expect_false("ctrA knockout" %in% result)
})


# ── get_de_results ────────────────────────────────────────────────────────────

test_that("get_de_results returns correct columns and values", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_de_results(con, "CCNA_00090")

  expected_cols <- c(
    "gene_id",
    "experiment_id",
    "log2fc",
    "stat_value",
    "gene_name",
    "cc_tag",
    "display_label",
    "stat_method"
  )
  expect_true(all(expected_cols %in% colnames(result)))
  expect_gt(nrow(result), 0)
  expect_type(result$log2fc, "double")
  expect_equal(unique(result$gene_name), "CCNA_00090")
})

test_that("get_de_results handles multiple gene_ids", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_de_results(con, c("CCNA_00090", "CCNA_00446"))
  expect_gt(nrow(result), 0)
  expect_setequal(unique(result$gene_name), c("CCNA_00090", "CCNA_00446"))
})


# ── get_de_data_types ─────────────────────────────────────────────────────────

test_that("get_de_data_types returns data types for de_comparison experiments", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_de_data_types(con)
  expect_type(result, "character")
  expect_true("rnaseq" %in% result)
})


# ── get_de_results_for_heatmap ────────────────────────────────────────────────

test_that("get_de_results_for_heatmap returns correct columns with no filter", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_de_results_for_heatmap(con, c("CCNA_00090", "CCNA_00446"))

  expected_cols <- c(
    "gene_id",
    "gene_name",
    "cc_tag",
    "experiment_id",
    "display_label",
    "stat_method",
    "data_type",
    "log2fc",
    "stat_value"
  )
  expect_true(all(expected_cols %in% colnames(result)))
  expect_gt(nrow(result), 0)
})

test_that("get_de_results_for_heatmap filters by data_type", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_de_results_for_heatmap(
    con,
    c("CCNA_00090", "CCNA_00446"),
    data_type = "rnaseq"
  )
  expect_gt(nrow(result), 0)
  expect_true(all(result$data_type == "rnaseq"))

  result_none <- get_de_results_for_heatmap(
    con,
    c("CCNA_00090", "CCNA_00446"),
    data_type = "not_a_data_type"
  )
  expect_equal(nrow(result_none), 0)
})


# ── stubs ─────────────────────────────────────────────────────────────────────

test_that("get_fitness_data returns empty data frame with correct columns", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_fitness_data(con, "CCNA_00090")
  expect_equal(nrow(result), 0)
  expect_true("gene_id" %in% colnames(result))
  expect_true("essentiality_class" %in% colnames(result))
})

test_that("get_localization_data returns empty data frame with correct columns", {
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    test_db_path()
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_localization_data(con, "CCNA_00090")
  expect_equal(nrow(result), 0)
  expect_true("gene_id" %in% colnames(result))
  expect_true("cell_cycle_stage" %in% colnames(result))
  expect_true("localization_zone" %in% colnames(result))
})
