#' Generate an example CauloBrowser database
#'
#' Creates a DuckDB database pre-populated with demo data for six
#' *Caulobacter crescentus* NA1000 genes across two experiments: a
#' cell-cycle RNA-seq timecourse and a CtrA-depletion DE comparison.
#'
#' @param path Path where the `.duckdb` file should be written, or `":memory:"`
#'   to create a transient in-memory database.  Defaults to
#'   `"caulobrowser_example.duckdb"` in the current working directory.
#' @param overwrite Logical. If `TRUE` (default) an existing file at
#'   `path` is removed before creating the new database. Ignored when
#'   `path = ":memory:"`.
#'
#' @return When `path = ":memory:"`, the open `DBI` connection (caller is
#'   responsible for closing it).  Otherwise the resolved `path`, invisibly.
#' @export
generate_example_database <- function(
  path = "caulobrowser_example.duckdb",
  overwrite = TRUE
) {
  in_memory <- identical(path, ":memory:")

  if (!in_memory) {
    path <- normalizePath(path, mustWork = FALSE)

    if (file.exists(path) && !overwrite) {
      stop(
        "File already exists: ",
        path,
        "\n  Use overwrite = TRUE to replace it.",
        call. = FALSE
      )
      file.remove(path)
    }
  }

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
  if (!in_memory) {
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  }

  # ── Schema ──────────────────────────────────────────────────────────────────
  DBI::dbExecute(
    con,
    "
CREATE TABLE genes (
    gene_id                 VARCHAR PRIMARY KEY,
    cc_tag                  VARCHAR,
    gene_name               VARCHAR,
    uniprot_id              VARCHAR,
    start_pos               BIGINT,
    end_pos                 BIGINT,
    strand                  VARCHAR,
    length                  VARCHAR,
    mass                    VARCHAR,
    gene_biotype            VARCHAR,
    product                 VARCHAR,
    description             VARCHAR,
    protein_names           VARCHAR,
    function_cc             VARCHAR,
    protein_families        VARCHAR,
    essential               VARCHAR,
    Dbxref                  VARCHAR,
    existence_ncbi          VARCHAR,
    existence_uniprot       VARCHAR,
    COG                     VARCHAR,
    COGFun                  VARCHAR,
    COGDesc                 VARCHAR,
    TIGRFam                 VARCHAR,
    TIGRRoles               VARCHAR,
    GO                      VARCHAR,
    KEGG                    VARCHAR,
    activity_regulation     VARCHAR,
    rhea_id                 VARCHAR,
    interacts               VARCHAR,
    subcellular_location_cc VARCHAR,
    ptm                     VARCHAR,
    pubmed_id               VARCHAR,
    doi                     VARCHAR,
    EMBL                    VARCHAR,
    protein_id              VARCHAR,
    PDB                     VARCHAR,
    SMR                     VARCHAR,
    sequence_similarities   VARCHAR,
    protein_sequence        VARCHAR
);"
  )

  DBI::dbExecute(
    con,
    "
CREATE TABLE experiments (
    experiment_id       VARCHAR PRIMARY KEY,
    display_label       VARCHAR NOT NULL,
    experiment_class    VARCHAR NOT NULL,
    data_type           VARCHAR NOT NULL,
    strain              VARCHAR,
    genetic_background  VARCHAR,
    treatment           VARCHAR,
    treatment_level     VARCHAR,
    growth_phase        VARCHAR,
    media               VARCHAR,
    ref_strain          VARCHAR,
    ref_treatment       VARCHAR,
    ref_treatment_level VARCHAR,
    ref_growth_phase    VARCHAR,
    ref_media           VARCHAR,
    stat_method         VARCHAR,
    lab_group           VARCHAR,
    doi                 VARCHAR,
    geo_id              VARCHAR,
    date_added          DATE
);"
  )

  DBI::dbExecute(
    con,
    "
CREATE TABLE experiment_conditions (
    experiment_id   VARCHAR NOT NULL REFERENCES experiments(experiment_id),
    condition_label VARCHAR NOT NULL,
    condition_order INTEGER NOT NULL,
    condition_value DOUBLE,
    condition_units VARCHAR,
    display_label   VARCHAR,
    PRIMARY KEY (experiment_id, condition_label)
);"
  )

  DBI::dbExecute(
    con,
    "
CREATE TABLE de_results (
    gene_id       VARCHAR NOT NULL REFERENCES genes(gene_id),
    experiment_id VARCHAR NOT NULL REFERENCES experiments(experiment_id),
    log2fc        DOUBLE NOT NULL,
    stat_value    DOUBLE,
    PRIMARY KEY (gene_id, experiment_id)
);"
  )

  DBI::dbExecute(
    con,
    "
CREATE TABLE timecourse_expression (
    gene_id          VARCHAR NOT NULL REFERENCES genes(gene_id),
    experiment_id    VARCHAR NOT NULL REFERENCES experiments(experiment_id),
    condition_label  VARCHAR NOT NULL,
    expression_value DOUBLE NOT NULL,
    PRIMARY KEY (gene_id, experiment_id, condition_label),
    FOREIGN KEY (experiment_id, condition_label)
        REFERENCES experiment_conditions(experiment_id, condition_label)
);"
  )

  DBI::dbExecute(
    con,
    "
CREATE TABLE gene_viewer_metadata (
    assembly    VARCHAR,
    text_index  VARCHAR[4],
    tracks      STRUCT(
                    experiment_id VARCHAR,
                    track_type    VARCHAR,
                    https_paths   VARCHAR
                )[]
);"
  )

  DBI::dbExecute(
    con,
    "CREATE INDEX idx_de_exp      ON de_results(experiment_id);"
  )
  DBI::dbExecute(con, "CREATE INDEX idx_de_gene     ON de_results(gene_id);")
  DBI::dbExecute(
    con,
    "CREATE INDEX idx_tc_gene     ON timecourse_expression(gene_id);"
  )
  DBI::dbExecute(
    con,
    "CREATE INDEX idx_tc_exp      ON timecourse_expression(experiment_id);"
  )
  DBI::dbExecute(
    con,
    "CREATE INDEX idx_tc_gene_exp ON timecourse_expression(gene_id, experiment_id);"
  )
  DBI::dbExecute(
    con,
    "CREATE INDEX idx_exp_class   ON experiments(experiment_class);"
  )
  DBI::dbExecute(con, "CREATE INDEX idx_exp_type    ON experiments(data_type);")
  DBI::dbExecute(con, "CREATE INDEX idx_exp_lab     ON experiments(lab_group);")

  # ── Genes ───────────────────────────────────────────────────────────────────
  DBI::dbAppendTable(
    con,
    "genes",
    data.frame(
      gene_id = c(
        "CCNA_00090",
        "CCNA_00446",
        "CCNA_02647",
        "CCNA_02761",
        "CCNA_01248"
      ),
      cc_tag = c("CC_0092", "CC_0437", "CC_1190", "CC_2564", "CC_2678"),
      gene_name = c("ctrA", "dnaA", "fliF", "pilA", "rpoD"),
      start_pos = c(101960L, 452915L, 1375993L, 2800802L, 2923673L),
      end_pos = c(102943L, 453304L, 1376628L, 2801722L, 2923918L),
      strand = c("-", "+", "+", "-", "+"),
      Dbxref = c(
        "GeneID:7332344",
        "GeneID:7330573",
        "GeneID:7333641",
        "GeneID:7332750",
        "GeneID:7330923"
      ),
      protein_id = c(
        "YP_002515465.1",
        "YP_002515821.1",
        "YP_002516621.1",
        "YP_002518020.1",
        "YP_002518134.1"
      ),
      gene_biotype = rep("protein_coding", 5),
      product = c(
        "UDP-glucose 4-epimerase",
        "chemotaxis receiver domain protein cheYII",
        "TetR-family transcriptional regulator",
        "PBP2-family ligand-binding transcriptional regulator",
        "hypothetical protein"
      ),
      essential = c(
        NA_character_,
        NA_character_,
        NA_character_,
        NA_character_,
        NA_character_
      ),
      description = c(
        "UDP-glucose 4-epimerase",
        "chemotaxis receiver domain protein cheYII",
        "TetR-family transcriptional regulator",
        "PBP2-family ligand-binding transcriptional regulator",
        "hypothetical protein"
      ),
      existence_ncbi = c(
        "LC-MS,Ribosome profiling",
        "LC-MS,Ribosome profiling",
        "LC-MS,Ribosome profiling",
        NA_character_,
        "Ribosome profiling"
      ),
      COG = c("COG1087", "COG784", "COG1309", "COG583", NA_character_),
      COGFun = c("M", "T", "K", "K", NA_character_),
      COGDesc = c(
        "UDP-glucose 4-epimerase",
        "FOG: CheY-like receiver",
        "Transcriptional regulator",
        "Transcriptional regulator",
        NA_character_
      ),
      TIGRFam = c(
        "TIGR01179 UDP-glucose 4-epimerase [galE]",
        NA_character_,
        NA_character_,
        NA_character_,
        NA_character_
      ),
      TIGRRoles = c(
        "Energy metabolism:Sugars",
        NA_character_,
        NA_character_,
        NA_character_,
        NA_character_
      ),
      GO = c(
        "GO:0045226,GO:0006012,GO:0003978,GO:0050662,GO:0008831",
        "GO:0006355,GO:0000160,GO:0000156",
        "GO:0006355,GO:0016481,GO:0016566,GO:0003700",
        "GO:0006355,GO:0003700",
        NA_character_
      ),
      KEGG = c(
        "ccs00052,ccs00520,ccs01100,ccs01250",
        "ccs02020,ccs02030",
        NA_character_,
        NA_character_,
        NA_character_
      ),
      stringsAsFactors = FALSE
    )
  )

  # ── Experiments ─────────────────────────────────────────────────────────────
  DBI::dbAppendTable(
    con,
    "experiments",
    data.frame(
      experiment_id = c("TC_RNAseq_WT_CC", "DE_ctrA_depl"),
      display_label = c(
        "WT cell cycle timecourse (RNA-seq)",
        "ctrA depletion vs WT (RNA-seq)"
      ),
      experiment_class = c("timecourse", "de_comparison"),
      data_type = c("rnaseq", "rnaseq"),
      strain = c("NA1000", "NA1000"),
      genetic_background = c("wildtype", "ctrA knockout"),
      treatment = c(NA_character_, "vanillate depletion"),
      treatment_level = c(NA_character_, "0 h"),
      growth_phase = c("synchronised swarmer", "exponential"),
      media = c("M2G", "M2G"),
      ref_strain = c(NA_character_, "NA1000"),
      ref_treatment = c(NA_character_, NA_character_),
      ref_treatment_level = c(NA_character_, NA_character_),
      ref_growth_phase = c(NA_character_, "exponential"),
      ref_media = c(NA_character_, "M2G"),
      lab_group = c("Laub lab", "Laub lab"),
      stat_method = c("padj", "padj"),
      doi = c("10.1016/j.cell.2009.01.001", "10.1073/pnas.0407828102"),
      geo_id = c("GSE12345", "GSE67890"),
      date_added = as.Date(c("2024-01-15", "2024-03-20")),
      stringsAsFactors = FALSE
    )
  )

  # ── Experiment conditions (timecourse time points) ───────────────────────────
  DBI::dbAppendTable(
    con,
    "experiment_conditions",
    data.frame(
      experiment_id = rep("TC_RNAseq_WT_CC", 5),
      condition_label = c("t0", "t30", "t60", "t90", "t120"),
      condition_order = 1:5,
      condition_value = c(0, 30, 60, 90, 120),
      condition_units = rep("min", 5),
      display_label = c("0 min", "30 min", "60 min", "90 min", "120 min"),
      stringsAsFactors = FALSE
    )
  )

  # ── DE results ──────────────────────────────────────────────────────────────
  DBI::dbAppendTable(
    con,
    "de_results",
    data.frame(
      gene_id = c(
        "CCNA_00090",
        "CCNA_00446",
        "CCNA_02647",
        "CCNA_02761",
        "CCNA_01248"
      ),
      experiment_id = rep("DE_ctrA_depl", 5),
      log2fc = c(-2.1, -0.4, 1.8, 0.9, -0.2),
      stat_value = c(1e-4, 0.32, 2.3e-3, 0.015, 0.78),
      stringsAsFactors = FALSE
    )
  )

  # ── Timecourse expression ────────────────────────────────────────────────────
  # Biologically plausible cell-cycle profiles (log2 TPM)
  expr_patterns <- list(
    CCNA_00090 = c(5.2, 6.8, 7.1, 5.9, 4.8), # ctrA  – peaks in early S-phase
    CCNA_00446 = c(6.1, 5.8, 5.5, 6.2, 6.4), # dnaA  – relatively constant
    CCNA_02647 = c(4.5, 5.1, 6.3, 7.2, 6.8), # fliF  – late-cell-cycle induction
    CCNA_02761 = c(3.8, 4.2, 5.6, 6.9, 7.4), # pilA  – monotonically increasing
    CCNA_01248 = c(7.0, 6.9, 7.1, 6.8, 7.0) # rpoD  – stable housekeeping
  )
  cond_labels <- c("t0", "t30", "t60", "t90", "t120")

  tc_expr <- do.call(
    rbind,
    lapply(names(expr_patterns), function(g) {
      data.frame(
        gene_id = g,
        experiment_id = "TC_RNAseq_WT_CC",
        condition_label = cond_labels,
        expression_value = expr_patterns[[g]],
        stringsAsFactors = FALSE
      )
    })
  )
  DBI::dbAppendTable(con, "timecourse_expression", tc_expr)

  # ── Gene viewer metadata ─────────────────────────────────────────────────────
  DBI::dbExecute(
    con,
    "INSERT INTO gene_viewer_metadata VALUES (
      'GCF_000022005.1',
      ['ctrA', 'dnaA', 'fliF', 'pilA'],
      [
        {'experiment_id': 'TC_RNAseq_WT_CC', 'track_type': 'bigwig', 'https_paths': 'https://example.com/tc_rnaseq_wt_cc.bw'},
        {'experiment_id': 'DE_ctrA_depl',    'track_type': 'bigwig', 'https_paths': 'https://example.com/de_ctra_depl.bw'}
      ]
    );"
  )

  if (in_memory) {
    return(invisible(con))
  }

  message("Example database written to: ", path)
  invisible(path)
}
