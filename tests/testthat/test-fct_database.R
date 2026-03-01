# ── search_genes ─────────────────────────────────────────────────────────────

test_that("search_genes finds gene by name", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "ctrA")
  expect_equal(nrow(result), 1)
  expect_equal(result$gene_name, "ctrA")
})

test_that("search_genes finds gene by gene_id (CCNA_ tag)", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "CCNA_00090")
  expect_equal(nrow(result), 1)
  expect_equal(result$gene_id, "CCNA_00090")
})

test_that("search_genes finds gene by cc_tag", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "CC_0001")
  expect_equal(nrow(result), 1)
})

test_that("search_genes accepts comma-separated list of terms", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "ctrA,dnaA")
  expect_equal(nrow(result), 2)
})

test_that("search_genes returns 0 rows for empty query", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "")
  expect_equal(nrow(result), 0)
})

test_that("search_genes returns 0 rows for no match", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- search_genes(con, "notAGene")
  expect_equal(nrow(result), 0)
})


# ── get_expression_data ───────────────────────────────────────────────────────

test_that("get_expression_data returns correct columns and rows", {
  con <- generate_example_database(":memory:")
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
  expect_equal(nrow(result), 5) # 5 timepoints in the demo dataset
  expect_equal(unique(result$gene_name), "ctrA")
})

test_that("get_expression_data filters by genetic_background", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_expression_data(
    con,
    "CCNA_00090",
    genetic_background = "wildtype"
  )
  expect_equal(nrow(result), 5)

  result_none <- get_expression_data(
    con,
    "CCNA_00090",
    genetic_background = "mutant"
  )
  expect_equal(nrow(result_none), 0)
})

test_that("get_expression_data handles multiple gene_ids", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_expression_data(con, c("CCNA_00090", "CCNA_00446"))
  expect_equal(nrow(result), 10) # 2 genes × 5 timepoints
  expect_equal(length(unique(result$gene_id)), 2)
})


# ── get_timecourse_backgrounds ────────────────────────────────────────────────

test_that("get_timecourse_backgrounds returns timecourse genetic backgrounds", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_timecourse_backgrounds(con)
  expect_type(result, "character")
  expect_true("wildtype" %in% result)
  # de_comparison background must not appear
  expect_false("ctrA knockout" %in% result)
})


# ── get_de_results ────────────────────────────────────────────────────────────

test_that("get_de_results returns correct columns and values", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_de_results(con, "CCNA_00090")

  expected_cols <- c(
    "gene_id",
    "experiment_id",
    "log2fc",
    "padj",
    "gene_name",
    "cc_tag",
    "display_label"
  )
  expect_true(all(expected_cols %in% colnames(result)))
  expect_equal(nrow(result), 1)
  expect_equal(result$log2fc, -2.1)
  expect_equal(result$gene_name, "ctrA")
})

test_that("get_de_results handles multiple gene_ids", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_de_results(con, c("CCNA_00090", "CCNA_00446"))
  expect_equal(nrow(result), 2)
  expect_setequal(result$gene_name, c("ctrA", "dnaA"))
})


# ── get_de_data_types ─────────────────────────────────────────────────────────

test_that("get_de_data_types returns data types for de_comparison experiments", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_de_data_types(con)
  expect_type(result, "character")
  expect_true("rnaseq" %in% result)
})


# ── get_de_results_for_heatmap ────────────────────────────────────────────────

test_that("get_de_results_for_heatmap returns correct columns with no filter", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_de_results_for_heatmap(con, c("CCNA_00090", "CCNA_00446"))

  expected_cols <- c(
    "gene_id",
    "gene_name",
    "cc_tag",
    "experiment_id",
    "display_label",
    "data_type",
    "log2fc",
    "padj"
  )
  expect_true(all(expected_cols %in% colnames(result)))
  expect_equal(nrow(result), 2)
})

test_that("get_de_results_for_heatmap filters by data_type", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_de_results_for_heatmap(
    con,
    c("CCNA_00090", "CCNA_00446"),
    data_type = "rnaseq"
  )
  expect_equal(nrow(result), 2)

  result_none <- get_de_results_for_heatmap(
    con,
    c("CCNA_00090", "CCNA_00446"),
    data_type = "microarray"
  )
  expect_equal(nrow(result_none), 0)
})


# ── stubs ─────────────────────────────────────────────────────────────────────

test_that("get_fitness_data returns empty data frame with correct columns", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_fitness_data(con, "CCNA_00090")
  expect_equal(nrow(result), 0)
  expect_true("gene_id" %in% colnames(result))
  expect_true("essentiality_class" %in% colnames(result))
})

test_that("get_localization_data returns empty data frame with correct columns", {
  con <- generate_example_database(":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  result <- get_localization_data(con, "CCNA_00090")
  expect_equal(nrow(result), 0)
  expect_true("gene_id" %in% colnames(result))
  expect_true("cell_cycle_stage" %in% colnames(result))
  expect_true("localization_zone" %in% colnames(result))
})
