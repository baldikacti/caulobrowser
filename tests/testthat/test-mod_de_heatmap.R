test_that("mod_de_heatmap_ui works", {
  ui <- mod_de_heatmap_ui(id = "test")
  golem::expect_shinytaglist(ui)
  fmls <- formals(mod_de_heatmap_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_de_heatmap_server has correct formals", {
  fmls <- formals(mod_de_heatmap_server)
  for (i in c("id", "gene_results", "dtype_filter", "db_con")) {
    expect_true(i %in% names(fmls))
  }
})

# de_data returns a data frame with expected columns for a known gene
testServer(
  mod_de_heatmap_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          system.file(
            "extdata",
            "caulobrowser.duckdb",
            package = "caulobrowser"
          )
        ),
        "CCNA_01248"
      )
    ),
    dtype_filter = c("rnaseq"),
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    session$setInputs(filter_sig = FALSE, filter_pheno = TRUE)
    df <- de_data()
    expect_s3_class(df, "data.frame")
    for (col in c(
      "gene_id",
      "log2fc",
      "experiment_id",
      "display_label",
      "data_type"
    )) {
      expect_true(col %in% colnames(df))
    }
    expect_true(nrow(df) > 0)
  }
)

# de_data is filtered to the requested dtype
testServer(
  mod_de_heatmap_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          system.file(
            "extdata",
            "caulobrowser.duckdb",
            package = "caulobrowser"
          )
        ),
        "CCNA_00090"
      )
    ),
    dtype_filter = c("rnaseq"),
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    session$setInputs(filter_sig = FALSE, filter_pheno = TRUE)
    df <- de_data()
    expect_true(all(df$data_type == "rnaseq"))
  }
)

# de_data returns 0 rows when dtype has no data in the demo DB
testServer(
  mod_de_heatmap_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          system.file(
            "extdata",
            "caulobrowser.duckdb",
            package = "caulobrowser"
          )
        ),
        "CCNA_00090"
      )
    ),
    dtype_filter = c("tnseq"),
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    session$setInputs(filter_sig = FALSE, filter_pheno = TRUE)
    df <- de_data()
    expect_equal(nrow(df), 0)
  }
)

# de_data errors (via req) when gene_results has no matches
testServer(
  mod_de_heatmap_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          system.file(
            "extdata",
            "caulobrowser.duckdb",
            package = "caulobrowser"
          )
        ),
        "notAGene"
      )
    ),
    dtype_filter = c("rnaseq"),
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    session$setInputs(filter_sig = FALSE, filter_pheno = TRUE)
    expect_error(de_data())
  }
)

# plot_height_px is at least 200 when DE data is present
testServer(
  mod_de_heatmap_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          system.file(
            "extdata",
            "caulobrowser.duckdb",
            package = "caulobrowser"
          )
        ),
        "CCNA_00090"
      )
    ),
    dtype_filter = c("rnaseq"),
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    session$setInputs(filter_sig = FALSE, filter_pheno = TRUE)
    expect_gte(plot_height_px(), 200)
  }
)

# plot_height_px returns 200 when dtype has no data
testServer(
  mod_de_heatmap_server,
  args = list(
    gene_results = shiny::reactive(
      search_genes(
        DBI::dbConnect(
          duckdb::duckdb(),
          system.file(
            "extdata",
            "caulobrowser.duckdb",
            package = "caulobrowser"
          )
        ),
        "CCNA_01248"
      )
    ),
    dtype_filter = c("tnseq"),
    db_con = shiny::reactiveVal(DBI::dbConnect(
      duckdb::duckdb(),
      system.file("extdata", "caulobrowser.duckdb", package = "caulobrowser")
    ))
  ),
  {
    session$setInputs(filter_sig = FALSE, filter_pheno = TRUE)
    expect_equal(plot_height_px(), 200L)
  }
)
