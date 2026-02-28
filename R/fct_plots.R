#' Plotting Helper Functions
#'
#' Functions for creating CauloBrowser visualizations.
#'
#' @name fct_plots
#' @noRd

#' Plot time-resolved expression profiles
#'
#' Creates a ggiraph line chart showing gene expression across cell cycle
#' timepoints. Each gene is a separate colored trace. Facets by experiment type
#' if multiple are present.
#'
#' @param expression_df Data frame from `get_expression_data()`.
#'   Expected columns: gene_name, timepoint_minutes, expression_value,
#'   experiment_type, experiment_label
#' @param color_palette Named character vector mapping gene_name to hex color.
#' @return A girafe object.
#' @noRd
plot_expression_timecourse <- function(expression_df, color_palette = NULL) {

  if (is.null(expression_df) || nrow(expression_df) == 0) {
    return(
      ggiraph::girafe(ggobj = ggplot2::ggplot() + ggplot2::theme_void())
    )
  }

  # Default color palette if not provided
  if (is.null(color_palette)) {
    gene_names <- unique(expression_df$gene_name)
    default_colors <- c(
      "#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
      "#FF7F00", "#A65628", "#F781BF", "#999999"
    )
    color_palette <- setNames(
      default_colors[seq_along(gene_names)],
      gene_names
    )
  }

  # Build ggplot with facets by experiment type
  p <- ggplot2::ggplot(
    expression_df,
    ggplot2::aes(
      x = timepoint_minutes,
      y = expression_value,
      color = gene_name,
      group = gene_name
    )
  ) +
    ggiraph::geom_line_interactive(linewidth = 1) +
    ggiraph::geom_point_interactive(
      ggplot2::aes(
        tooltip = paste0(
          "Gene: ", gene_name, "\n",
          "Time: ", timepoint_minutes, " min\n",
          "Value: ", round(expression_value, 3)
        ),
        data_id = paste0(gene_name, "_", timepoint_minutes)
      ),
      size = 2
    ) +
    ggplot2::facet_wrap(
      ~ experiment_type,
      scales = "free_y",
      ncol = 1
    ) +
    ggplot2::scale_color_manual(values = color_palette) +
    ggplot2::labs(
      x = "Cell Cycle Time (min)",
      y = "Expression",
      color = "Gene"
    ) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      strip.text = ggplot2::element_text(face = "bold", size = 12),
      legend.position = "bottom"
    )

  ggiraph::girafe(
    ggobj = p,
    options = list(ggiraph::opts_tooltip(use_fill = TRUE))
  )
}


#' Plot a single experiment type expression profile
#'
#' Simpler version for displaying a single experiment tab.
#'
#' @param expression_df Data frame filtered to one experiment_type.
#' @param title Character title for the plot.
#' @param color_palette Named character vector mapping gene_name to hex color.
#' @return A girafe object.
#' @noRd
plot_single_expression <- function(expression_df, title = "", color_palette = NULL) {

  if (is.null(expression_df) || nrow(expression_df) == 0) {
    return(
      ggiraph::girafe(ggobj = ggplot2::ggplot() + ggplot2::theme_void())
    )
  }

  if (is.null(color_palette)) {
    gene_names <- unique(expression_df$gene_name)
    default_colors <- c(
      "#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
      "#FF7F00", "#A65628", "#F781BF", "#999999"
    )
    color_palette <- setNames(
      default_colors[seq_along(gene_names)],
      gene_names
    )
  }

  p <- ggplot2::ggplot(
    expression_df,
    ggplot2::aes(
      x = timepoint_minutes,
      y = expression_value,
      color = gene_name,
      group = gene_name
    )
  ) +
    ggiraph::geom_line_interactive(linewidth = 1) +
    ggiraph::geom_point_interactive(
      ggplot2::aes(
        tooltip = paste0(
          "Gene: ", gene_name, "\n",
          "Time: ", timepoint_minutes, " min\n",
          "Value: ", round(expression_value, 3)
        ),
        data_id = paste0(gene_name, "_", timepoint_minutes)
      ),
      size = 2.5
    ) +
    ggplot2::scale_color_manual(values = color_palette) +
    ggplot2::labs(
      title = title,
      x = "Cell Cycle Time (min)",
      y = "Expression Level",
      color = "Gene"
    ) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(legend.position = "bottom")

  ggiraph::girafe(
    ggobj = p,
    options = list(ggiraph::opts_tooltip(use_fill = TRUE))
  )
}


#' Generate a cell schematic showing protein localization
#'
#' Creates an SVG-based representation of the Caulobacter cell at a given
#' cell cycle stage, with colored dots indicating protein localization.
#'
#' This returns an HTML tag (SVG) that can be rendered directly in the UI.
#'
#' @param localization_df Data frame from `get_localization_data()` filtered
#'   to one cell cycle stage. Expected columns: gene_name, localization_zone
#'   (e.g., "pole_stalked", "pole_swarmer", "diffuse", "midcell")
#' @param color_palette Named vector mapping gene_name to color.
#' @param stage_label Character label for the cell cycle stage.
#' @return An htmltools::HTML tag containing the SVG.
#' @noRd
render_cell_schematic <- function(localization_df,
                                  color_palette = NULL,
                                  stage_label = "") {

  # Define localization zone positions (x, y) within a 120x50 SVG cell shape
  zone_positions <- list(
    pole_stalked = c(x = 15, y = 25),
    pole_swarmer = c(x = 105, y = 25),
    midcell      = c(x = 60, y = 25),
    diffuse      = c(x = 60, y = 25),  # rendered differently (larger, transparent)
    membrane     = c(x = 60, y = 8)
  )

  # Build SVG elements
  # Cell body: a rounded rectangle representing the Caulobacter cell
  cell_body <- '<ellipse cx="60" cy="25" rx="50" ry="18"
                  fill="#f0f0f0" stroke="#333" stroke-width="1.5"/>'

  # Stalk at left pole
  stalk <- '<line x1="10" y1="25" x2="0" y2="25"
              stroke="#333" stroke-width="1.5"/>'

  # Flagellum at right pole
  flagellum <- '<path d="M 110 25 Q 115 20 120 25 Q 125 30 130 25"
                  fill="none" stroke="#333" stroke-width="1" />'

  # Protein dots
  dots <- ""
  if (!is.null(localization_df) && nrow(localization_df) > 0) {

    if (is.null(color_palette)) {
      gene_names <- unique(localization_df$gene_name)
      default_colors <- c(
        "#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
        "#FF7F00", "#A65628", "#F781BF", "#999999"
      )
      color_palette <- setNames(
        default_colors[seq_along(gene_names)],
        gene_names
      )
    }

    for (i in seq_len(nrow(localization_df))) {
      row <- localization_df[i, ]
      zone <- row$localization_zone
      pos <- zone_positions[[zone]]
      color <- color_palette[[row$gene_name]]

      if (is.null(pos)) pos <- c(x = 60, y = 25)
      if (is.null(color)) color <- "#888888"

      # Add small jitter to avoid overlaps
      jx <- pos["x"] + (i - 1) * 3
      jy <- pos["y"]

      if (zone == "diffuse") {
        # Diffuse: larger semi-transparent circle
        dots <- paste0(dots, sprintf(
          '<circle cx="%s" cy="%s" r="12" fill="%s" opacity="0.25"/>',
          jx, jy, color
        ))
      } else {
        dots <- paste0(dots, sprintf(
          '<circle cx="%s" cy="%s" r="5" fill="%s" opacity="0.85"/>',
          jx, jy, color
        ))
      }
    }
  }

  svg <- sprintf(
    '<div style="text-align:center;">
       <svg width="140" height="60" viewBox="-5 0 140 50">
         %s %s %s %s
       </svg>
       <div style="font-size:11px; color:#555;">%s</div>
     </div>',
    cell_body, stalk, flagellum, dots, stage_label
  )

  htmltools::HTML(svg)
}
