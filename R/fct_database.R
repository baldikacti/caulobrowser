#' Get a DuckDB connection
#'
#' Returns a DBI connection to the CauloBrowser DuckDB database.
#' Uses the path from golem-config.yml.
#'
#' @param db_path Optional path override; defaults to config value.
#' @return A DBI connection object.
#' @noRd
get_db_connection <- function() {
  db_path <- get_golem_config("db_path")

  # No database ships with the package; the path comes from the environment
  if (!nzchar(db_path)) {
    stop(
      "Database path could not be resolved.\n",
      "  Set the CAULOBROWSER_DB_PATH environment variable to an existing .duckdb file.",
      call. = FALSE
    )
  }

  if (!file.exists(db_path)) {
    stop(
      "Database file not found: ",
      db_path,
      "\n",
      "  Set the CAULOBROWSER_DB_PATH environment variable to an existing .duckdb file.",
      call. = FALSE
    )
  }

  message("Connecting to DuckDB: ", db_path)

  con <- DBI::dbConnect(
    duckdb::duckdb(),
    dbdir = db_path,
    read_only = TRUE
  )

  # Verify the database has the expected tables
  tables <- DBI::dbListTables(con)
  required <- c(
    "genes",
    "experiments",
    "experiment_conditions",
    "de_results",
    "timecourse_expression",
    "gene_viewer_metadata"
  )
  missing <- setdiff(required, tables)

  if (length(missing) > 0) {
    close_db_connection(con)
    stop(
      "Database is missing required tables: ",
      paste(missing, collapse = ", "),
      "\n",
      "  Database path: ",
      db_path,
      call. = FALSE
    )
  }

  return(con)
}

#' Disconnect from DuckDB
#' @param con A DBI connection object.
#' @noRd
close_db_connection <- function(con) {
  DBI::dbDisconnect(con, shutdown = TRUE)
}


#' Search genes by name, CC tag, or gene ID
#'
#' @param con DBI connection
#' @param query Character string: gene name, CC tag (e.g. CCNA_00090), gene ID,
#'   or a comma/semicolon-separated list of any of the above.
#' @return A data.frame of matching gene records.
#' @noRd
search_genes <- function(con, query) {
  terms <- trimws(unlist(strsplit(query, "[,;]+")))
  terms <- terms[nchar(terms) > 0]
  terms <- tolower(terms)

  if (length(terms) == 0) {
    return(data.frame())
  }

  placeholders <- paste(rep("?", length(terms)), collapse = ", ")

  sql <- glue::glue(
    "SELECT *
   FROM genes
   WHERE LOWER(gene_name) IN ({placeholders})
      OR LOWER(cc_tag)    IN ({placeholders})
      OR LOWER(gene_id)   IN ({placeholders})"
  )

  # Same terms bound three times (one per IN clause)
  result <- DBI::dbGetQuery(con, sql, params = rep(terms, 3))

  if (nrow(result) == 0) {
    return(result)
  }

  # Preserve input order: find the earliest matching term position per row
  pos <- pmin(
    match(tolower(result$gene_name), terms),
    match(tolower(result$cc_tag), terms),
    match(tolower(result$gene_id), terms),
    na.rm = TRUE
  )
  result[order(pos), ]
}


#' Retrieve Gene Viewever Metadata from the Duckdb database connection
#'
#' @param con DBI connection
#' @return LIST with the following fields.
#' assembly: CHARACTER,
#' text_index: CHARACTER[4],
#' tracks: DATAFRAME(experiment_id: CHARACTER, track_type: CHARACTER, https_paths: CHARACTER)
#' @noRd
get_gene_viewer_metadata <- function(con) {
  json <- DBI::dbGetQuery(
    con,
    "SELECT to_json(gene_viewer_metadata) AS j FROM gene_viewer_metadata"
  )
  jsonlite::fromJSON(json$j)
}


#' Get timecourse expression data for given gene IDs
#'
#' Joins `timecourse_expression` with `experiment_conditions`, `experiments`,
#' and `genes`.  Returns column names that match the plotting layer:
#'   - `experiment_type`   (aliased from `experiments.data_type`)
#'   - `timepoint_minutes` (aliased from `experiment_conditions.condition_value`)
#'   - `experiment_id`, `display_label`, `doi` for per-experiment plot cards
#'
#' @param con DBI connection
#' @param gene_ids Character vector of gene IDs.
#' @param genetic_background Optional filter on `experiments.genetic_background`
#'   (e.g. `"wildtype"`).
#' @return A data.frame with columns `gene_id`, `experiment_id`, `experiment_type`,
#'   `display_label`, `doi`, `timepoint_minutes`, `expression_value`,
#'   `condition_label`, `gene_name`, `cc_tag`.
#' @noRd
get_expression_data <- function(con, gene_ids, genetic_background = NULL) {
  placeholders <- paste(rep("?", length(gene_ids)), collapse = ", ")

  base_sql <- "
    SELECT
      tc.gene_id,
      exp.experiment_id,
      exp.data_type        AS experiment_type,
      exp.display_label,
      exp.treatment_level,
      exp.media,
      exp.strain,
      exp.doi,
      ec.condition_value   AS timepoint_minutes,
      tc.expression_value,
      tc.condition_label,
      g.gene_name,
      g.cc_tag
    FROM timecourse_expression tc
    JOIN genes g
      ON tc.gene_id        = g.gene_id
    JOIN experiments exp
      ON tc.experiment_id  = exp.experiment_id
    JOIN experiment_conditions ec
      ON tc.experiment_id  = ec.experiment_id
     AND tc.condition_label = ec.condition_label
    WHERE tc.gene_id IN ({placeholders})
      AND exp.experiment_class = 'timecourse'"

  if (!is.null(genetic_background)) {
    sql <- glue::glue(paste0(
      base_sql,
      "
      AND exp.genetic_background = ?
    ORDER BY exp.data_type, ec.condition_value"
    ))
    params <- c(gene_ids, genetic_background)
  } else {
    sql <- glue::glue(paste0(
      base_sql,
      "
    ORDER BY exp.data_type, ec.condition_value"
    ))
    params <- gene_ids
  }

  DBI::dbGetQuery(con, sql, params = params)
}


#' Get distinct genetic backgrounds for timecourse experiments
#'
#' @param con DBI connection
#' @return Character vector of distinct `genetic_background` values.
#' @noRd
get_timecourse_backgrounds <- function(con) {
  DBI::dbGetQuery(
    con,
    "SELECT DISTINCT genetic_background
     FROM experiments
     WHERE experiment_class = 'timecourse'
       AND genetic_background IS NOT NULL
     ORDER BY genetic_background"
  )$genetic_background
}


#' Get DE results for given gene IDs
#'
#' @param con DBI connection
#' @param gene_ids Character vector of gene IDs.
#' @return A data.frame with columns `gene_id`, `experiment_id`, `log2fc`,
#'   `stat_value`, `gene_name`, `cc_tag`, `display_label`, `stat_method`.
#' @noRd
get_de_results <- function(con, gene_ids) {
  placeholders <- paste(rep("?", length(gene_ids)), collapse = ", ")

  sql <- glue::glue(
    "SELECT
       dr.gene_id,
       dr.experiment_id,
       dr.log2fc,
       dr.stat_value,
       g.gene_name,
       g.cc_tag,
       exp.display_label,
       exp.stat_method
     FROM de_results dr
     JOIN genes g         ON dr.gene_id       = g.gene_id
     JOIN experiments exp ON dr.experiment_id = exp.experiment_id
     WHERE dr.gene_id IN ({placeholders})
     ORDER BY exp.experiment_id, dr.gene_id"
  )

  DBI::dbGetQuery(con, sql, params = gene_ids)
}


#' Get distinct data_type values for DE comparison experiments
#'
#' Used to populate the filter dropdown in the DE heatmap module.
#'
#' @param con DBI connection
#' @return Character vector of distinct `data_type` values, ordered alphabetically.
#' @noRd
get_de_data_types <- function(con) {
  DBI::dbGetQuery(
    con,
    "SELECT DISTINCT data_type
     FROM experiments
     WHERE experiment_class = 'de_comparison'
       AND data_type IS NOT NULL
     ORDER BY data_type"
  )$data_type
}


#' Get DE results for the heatmap, with optional data_type filter
#'
#' @param con DBI connection
#' @param gene_ids Character vector of gene IDs (CCNA_XXXXX).
#' @param data_type Optional character scalar to filter `experiments.data_type`.
#'   Pass NULL to include all types.
#' @return A data.frame with columns: `gene_id`, `gene_name`, `cc_tag`,
#'   `experiment_id`, `display_label`, `data_type`, `strain`, `treatment`,
#'   `treatment_level`, `media`, `growth_phase`, `stat_method`, `lab_group`, `doi`,
#'   `log2fc`, `stat_value`.
#' @noRd
get_de_results_for_heatmap <- function(con, gene_ids, data_type = NULL) {
  gene_placeholders <- paste(rep("?", length(gene_ids)), collapse = ", ")

  base_sql <- glue::glue(
    "SELECT
       dr.gene_id,
       g.gene_name,
       g.cc_tag,
       dr.experiment_id,
       exp.display_label,
       exp.data_type,
       exp.strain,
       exp.genetic_background,
       exp.treatment,
       exp.treatment_level,
       exp.media,
       exp.growth_phase,
       exp.ref_strain,
       exp.ref_treatment,
       exp.ref_treatment_level,
       exp.ref_media,
       exp.ref_growth_phase,
       exp.stat_method,
       exp.lab_group,
       exp.doi,
       exp.geo_id,
       exp.notes,
       dr.log2fc,
       dr.stat_value
     FROM de_results dr
     JOIN genes g         ON dr.gene_id       = g.gene_id
     JOIN experiments exp ON dr.experiment_id = exp.experiment_id
     WHERE dr.gene_id IN ({gene_placeholders})
       AND exp.experiment_class = 'de_comparison'"
  )

  if (!is.null(data_type) && length(data_type) > 0) {
    type_placeholders <- paste(rep("?", length(data_type)), collapse = ", ")
    sql <- paste0(
      base_sql,
      glue::glue("\n       AND exp.data_type IN ({type_placeholders})"),
      "\n     ORDER BY exp.data_type, exp.display_label, g.gene_name"
    )
    params <- c(gene_ids, data_type)
  } else {
    sql <- paste0(
      base_sql,
      "\n     ORDER BY exp.data_type, exp.display_label, g.gene_name"
    )
    params <- gene_ids
  }

  DBI::dbGetQuery(con, sql, params = params)
}


# ── Stubs future additions ──────────────────────────────────────────────────
# fitness and protein_localization are not in the current schema.
# These stubs keep existing UI code from crashing; callers already handle
# empty results gracefully (showing "—").

#' @noRd
get_fitness_data <- function(con, gene_ids) {
  data.frame(
    gene_id = character(),
    essentiality_class = character(),
    stringsAsFactors = FALSE
  )
}

#' @noRd
get_localization_data <- function(con, gene_ids) {
  data.frame(
    gene_id = character(),
    cell_cycle_stage = character(),
    localization_zone = character(),
    stringsAsFactors = FALSE
  )
}
