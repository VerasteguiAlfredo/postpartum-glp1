# =============================================================================
# postpartum-glp1: CONSORT-style Attrition Table & Diagram
# -----------------------------------------------------------------------------
# Reconstructs the cohort-derivation flow from what analysis_df can support,
# plus build-time counts. Some UPSTREAM counts are only emitted to the console
# when build_analysis_dataset_v3.R runs; this script captures the ones that are
# recoverable and flags the rest with [FILL FROM BUILD LOG] so you can paste the
# exact numbers from your build run.
#
# Produces:
#   consort_attrition.md / .html  (table)
#   consort_diagram.png / .pdf    (flow diagram, 600 dpi)
#
# Run AFTER build_analysis_dataset_v3.R (uses analysis_df).
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(gt); library(ggplot2); library(glue)
})

# --- Paths ---
sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}
data_dir <- file.path(proj_root, "data_processed")
md_dir   <- file.path(proj_root, "Results", "Analysis", "Tables", "MD Files")
html_dir <- file.path(proj_root, "Results", "Analysis", "Tables", "HTML Files")
fig_dir  <- file.path(proj_root, "Results", "Analysis", "Figures")
for (d in c(md_dir, html_dir, fig_dir)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

if (!exists("analysis_df")) analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))

# =============================================================================
# DERIVABLE COUNTS (from analysis_df — the final analytic cohort)
# =============================================================================
n_final <- nrow(analysis_df)   # 704

# HDP subgroup (BP analysis denominator)
n_hdp <- analysis_df %>%
  mutate(bp_baseline_stage2 = (!is.na(sbp_baseline_combined) & sbp_baseline_combined >= 140) |
                              (!is.na(dbp_baseline_combined) & dbp_baseline_combined >= 90),
         hdp_cohort = (preg_htn_any == TRUE) | bp_baseline_stage2) %>%
  summarise(n = sum(hdp_cohort, na.rm = TRUE)) %>% pull(n)

# Analysis-ready denominators per outcome (non-missing baseline)
n_wt_baseline   <- sum(!is.na(analysis_df$weight_kg_baseline_combined))
n_sbp_baseline  <- sum(!is.na(analysis_df$sbp_baseline_combined))
n_prepreg       <- sum(!is.na(analysis_df$PREGRAVID_BMI))

# Timing split
n_early <- sum(analysis_df$glp1_timing_2cat == "Early (< 6 months)", na.rm = TRUE)
n_late  <- sum(analysis_df$glp1_timing_2cat == "Late (>= 6 months)", na.rm = TRUE)

cat("--- Derivable counts from analysis_df ---\n")
cat("Final analytic cohort:        ", n_final, "\n")
cat("  Early (<6mo):               ", n_early, "\n")
cat("  Late (>=6mo):               ", n_late, "\n")
cat("HDP subgroup (BP analyses):   ", n_hdp, "\n")
cat("Weight baseline available:    ", n_wt_baseline, "\n")
cat("SBP baseline available:       ", n_sbp_baseline, "\n")
cat("Pre-pregnancy weight avail.:  ", n_prepreg, "\n\n")

# =============================================================================
# UPSTREAM COUNTS — paste from build_analysis_dataset_v3.R console output.
# The build prints these lines; fill them in here for an exact CONSORT.
# Defaults are NA so they render as [FILL FROM BUILD LOG] until provided.
# =============================================================================
# From build log line: "Cohort after auth/privacy filter: N patients"
n_auth_privacy   <- NA_integer_      # e.g. <total screened post auth/privacy>
# From "filter(!is.na(delv_date), !is.na(glp1_start))"
n_valid_dates    <- NA_integer_      # patients with valid delivery + GLP-1 dates
# Patients excluded for GLP-1 BEFORE delivery (pre-delivery exposure)
n_predelivery    <- NA_integer_      # excluded: GLP-1 start < delivery
# Patients with GLP-1 on/after delivery (= postpartum exposed, pre-data-filters)
n_postpartum_exp <- NA_integer_

fill <- function(x) if (is.na(x)) "[FILL FROM BUILD LOG]" else format(x, big.mark = ",")

# =============================================================================
# ATTRITION TABLE
# =============================================================================
attrition <- tibble::tribble(
  ~Step, ~`N remaining`, ~`N excluded (reason)`,
  "Source: postpartum patients screened (auth/privacy-cleared)", fill(n_auth_privacy), "-",
  "Valid delivery and GLP-1 initiation dates",                   fill(n_valid_dates),  "Missing/invalid dates",
  "GLP-1 initiated on or after delivery",                        fill(n_postpartum_exp), glue("GLP-1 before delivery (n={fill(n_predelivery)})"),
  "Final analytic cohort (>=1 postpartum vital, baseline derivable)", format(n_final, big.mark=","), "No usable postpartum measurement",
  "  -- Early initiators (< 6 months)",                          format(n_early, big.mark=","), "-",
  "  -- Late initiators (>= 6 months)",                          format(n_late,  big.mark=","), "-",
  "Weight-outcome analytic set (A1/A2)",                         format(n_wt_baseline, big.mark=","), "No weight baseline",
  "Pre-pregnancy-weight subset (A3)",                            format(n_prepreg, big.mark=","), "Pre-pregnancy weight not documented",
  "HDP subgroup for BP outcomes (B1-B3)",                        format(n_hdp, big.mark=","), "Not meeting HDP criteria"
)

attrition_md <- knitr::kable(attrition, format = "pipe",
  caption = "Table. Cohort derivation and attrition.") %>% paste(collapse = "\n")
writeLines(attrition_md, file.path(md_dir, "consort_attrition.md"))

nejm_style <- function(gt_tbl) {
  n_rows <- nrow(gt_tbl[["_data"]])
  gt_tbl %>%
    tab_options(table.font.names = "Georgia, 'Times New Roman', serif",
      table.font.size = px(12), heading.title.font.size = px(14),
      heading.title.font.weight = "bold", heading.align = "left",
      data_row.padding = px(4), column_labels.font.weight = "bold",
      table_body.hlines.style = "none", table_body.vlines.style = "none",
      column_labels.border.bottom.style = "none", column_labels.border.top.style = "none") %>%
    tab_style(cell_borders(sides = "top", color = "#000000", weight = px(2)), cells_column_labels()) %>%
    tab_style(cell_borders(sides = "bottom", color = "#000000", weight = px(1)), cells_column_labels()) %>%
    tab_style(cell_borders(sides = "bottom", color = "#000000", weight = px(2)), cells_body(rows = n_rows))
}
gt::gtsave(nejm_style(gt(attrition)), file.path(html_dir, "consort_attrition.html"))

# =============================================================================
# CONSORT FLOW DIAGRAM (box-and-arrow, base grid via ggplot)
# =============================================================================
box <- function(x, y, w, h, label, fill = "#F4F4F4") {
  list(geom_rect(aes(xmin = x - w/2, xmax = x + w/2, ymin = y - h/2, ymax = y + h/2),
                 fill = fill, color = "#333333", linewidth = 0.4),
       annotate("text", x = x, y = y, label = label, size = 3.1, lineheight = 0.95))
}

# Build label strings (use derivable + placeholders)
lbl_source <- glue("Postpartum patients screened\n(auth/privacy-cleared): {fill(n_auth_privacy)}")
lbl_dates  <- glue("Valid delivery + GLP-1 dates: {fill(n_valid_dates)}")
lbl_pp     <- glue("GLP-1 on/after delivery: {fill(n_postpartum_exp)}")
lbl_final  <- glue("Final analytic cohort: {format(n_final, big.mark=',')}")
lbl_split  <- glue("Early (<6mo): {n_early}      Late (>=6mo): {n_late}")
lbl_hdp    <- glue("HDP subgroup (BP): {n_hdp}")
lbl_prepreg<- glue("Pre-preg-weight subset (A3): {n_prepreg}")

p <- ggplot() +
  box(0, 10, 7, 1.1, lbl_source) +
  box(0, 8,  7, 1.0, lbl_dates) +
  box(0, 6,  7, 1.0, lbl_pp) +
  box(0, 4,  7, 1.0, lbl_final, fill = "#E3EEF7") +
  box(0, 2,  9, 0.9, lbl_split, fill = "#FFFFFF") +
  box(-3.2, 0.2, 4.2, 0.9, lbl_hdp, fill = "#FBEEE6") +
  box( 3.2, 0.2, 4.2, 0.9, lbl_prepreg, fill = "#FBEEE6") +
  # arrows down the main spine
  annotate("segment", x = 0, xend = 0, y = 9.45, yend = 8.5, arrow = arrow(length = unit(0.15,"cm"))) +
  annotate("segment", x = 0, xend = 0, y = 7.5,  yend = 6.5, arrow = arrow(length = unit(0.15,"cm"))) +
  annotate("segment", x = 0, xend = 0, y = 5.5,  yend = 4.55, arrow = arrow(length = unit(0.15,"cm"))) +
  annotate("segment", x = 0, xend = 0, y = 3.5,  yend = 2.5, arrow = arrow(length = unit(0.15,"cm"))) +
  annotate("segment", x = 0, xend = -3.2, y = 1.55, yend = 0.7, arrow = arrow(length = unit(0.15,"cm"))) +
  annotate("segment", x = 0, xend =  3.2, y = 1.55, yend = 0.7, arrow = arrow(length = unit(0.15,"cm"))) +
  coord_cartesian(xlim = c(-6, 6), ylim = c(-0.6, 11)) +
  theme_void() +
  labs(title = "Figure 1. Cohort derivation (CONSORT-style flow)") +
  theme(plot.title = element_text(face = "bold", size = 13, hjust = 0.5))

ggsave(file.path(fig_dir, "consort_diagram.png"), p, width = 8, height = 9, dpi = 600, bg = "white")
ggsave(file.path(fig_dir, "consort_diagram.pdf"), p, width = 8, height = 9, bg = "white")

# =============================================================================
# CONSOLE
# =============================================================================
cat("================================================================\n")
cat(" CONSORT ATTRITION TABLE\n")
cat("================================================================\n\n")
cat(attrition_md, "\n\n")
cat("NOTE: lines marked [FILL FROM BUILD LOG] need the upstream counts that\n")
cat("build_analysis_dataset_v3.R prints. Look for these console lines in your\n")
cat("build run and paste the numbers into the UPSTREAM COUNTS block:\n")
cat("  - 'Cohort after auth/privacy filter: N patients'  -> n_auth_privacy\n")
cat("  - count after filter(!is.na(delv_date), !is.na(glp1_start)) -> n_valid_dates\n")
cat("  - sum(exposure_df$glp1_postpartum_exposed)        -> n_postpartum_exp\n")
cat("  - sum(exposure_df$glp1_predelivery_any)           -> n_predelivery\n\n")
cat("FILES CREATED:\n")
cat("  ", file.path(md_dir,  "consort_attrition.md"), "\n")
cat("  ", file.path(html_dir,"consort_attrition.html"), "\n")
cat("  ", file.path(fig_dir, "consort_diagram.png / .pdf"), "\n")