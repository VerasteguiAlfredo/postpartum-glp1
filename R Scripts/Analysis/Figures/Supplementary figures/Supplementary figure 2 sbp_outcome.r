# =============================================================================
# postpartum-glp1: Figure 2 — Weight Loss at 6 Months on Drug (2 panels)
# -----------------------------------------------------------------------------
# Panel A: TBWL% at 6 months on drug by timing stratum (ggbetweenstats)
#          - violins UNTRIMMED (trim = FALSE), box, jittered points
#          - Kruskal-Wallis + significant pairwise (Dunn, BH) p-values on plot
# Panel B: Responder rate (>=5% TBWL) at 6 months on drug (ggbarstats)
#          - proportions with n and %, chi-square/Fisher p-value on plot
# 600 dpi. Composite has A/B tags; individual panels have none.
#
# Source AFTER build_analysis_dataset_v3.R
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
  library(ggstatsplot)
  library(patchwork)
})

# --- Paths ---
sys_name <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}
data_dir <- file.path(proj_root, "data_processed")
fig_dir  <- file.path(proj_root, "Results", "Analysis", "Supplementary Material", "Figures")
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

if (!exists("analysis_df")) analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))
if (!exists("vitals_long")) vitals_long <- readRDS(file.path(data_dir, "vitals_long.rds"))

cat("Loaded analysis_df:", nrow(analysis_df), "rows\n")
cat("Loaded vitals_long:", nrow(vitals_long), "rows\n\n")

# =============================================================================
# PALETTE & THEME
# =============================================================================
strata_levels <- c("< 6 weeks", "6wk-3mo", "3-6mo", "> 6mo")
strata_colors <- c(
  "< 6 weeks" = "#8C6BB1",
  "6wk-3mo"   = "#4292C6",
  "3-6mo"     = "#41AB5D",
  "> 6mo"     = "#D9954B"
)

theme_pub <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      text             = element_text(color = "#1A1A1A", family = "sans"),
      plot.title       = element_text(face = "bold", size = base_size + 1, hjust = 0),
      plot.subtitle    = element_text(size = base_size - 2, color = "#4D4D4D", hjust = 0),
      axis.title       = element_text(size = base_size),
      axis.text        = element_text(size = base_size - 1, color = "#333333"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#E8E8E8", linewidth = 0.3),
      legend.position  = "bottom",
      legend.title     = element_text(size = base_size - 1, face = "bold"),
      legend.text      = element_text(size = base_size - 1),
      plot.margin      = margin(10, 14, 10, 10)
    )
}

# =============================================================================
# DATA PREP — drug-anchored 6-month TBWL%
# =============================================================================
closest_post_glp1 <- function(df, target_day, window_days) {
  df %>%
    filter(!is.na(days_from_glp1),
           days_from_glp1 >= target_day - window_days,
           days_from_glp1 <= target_day + window_days,
           days_from_glp1 >= 0) %>%
    group_by(CURR_CLINIC) %>%
    arrange(abs(days_from_glp1 - target_day), .by_group = TRUE) %>%
    slice(1) %>% ungroup() %>%
    select(CURR_CLINIC, value)
}

wt_sub     <- vitals_long %>% filter(vital == "weight_kg")
wt_m6_glp1 <- closest_post_glp1(wt_sub, 180, 45) %>% rename(weight_kg_m6_glp1 = value)

fig_df <- analysis_df %>%
  left_join(wt_m6_glp1, by = "CURR_CLINIC") %>%
  mutate(
    tbwl_drug_6m = (weight_kg_baseline_combined - weight_kg_m6_glp1) /
                   weight_kg_baseline_combined * 100,
    resp5_6m = if_else(!is.na(tbwl_drug_6m),
                       if_else(tbwl_drug_6m >= 5, ">=5% TBWL", "<5% TBWL"), NA_character_)
  ) %>%
  filter(!is.na(glp1_timing_cat)) %>%
  mutate(glp1_timing_cat = factor(glp1_timing_cat, levels = strata_levels))

# =============================================================================
# PANEL A — TBWL% at 6 months on drug, by stratum (ggbetweenstats)
#           violins UNTRIMMED via violin.args trim = FALSE
# =============================================================================
panela_data <- fig_df %>% filter(!is.na(tbwl_drug_6m))

panel_a <- ggbetweenstats(
  data              = panela_data,
  x                 = glp1_timing_cat,
  y                 = tbwl_drug_6m,
  type              = "nonparametric",
  pairwise.display  = "significant",
  p.adjust.method   = "BH",
  centrality.plotting = TRUE,
  centrality.type   = "nonparametric",
  point.args        = list(alpha = 0.25, size = 1.2,
                           position = ggplot2::position_jitterdodge(dodge.width = 0.6)),
  violin.args       = list(width = 0.6, alpha = 0.18, trim = FALSE),
  ggsignif.args     = list(textsize = 3, tip_length = 0.01),
  xlab              = "GLP-1 initiation timing",
  ylab              = "TBWL (%) at 6 months on drug",
  title             = "Weight loss at 6 months on drug, by timing",
  results.subtitle  = TRUE
) +
  scale_color_manual(values = strata_colors) +
  geom_hline(yintercept = 5, linetype = "dotted", color = "#888888", linewidth = 0.4) +
  theme_pub() +
  theme(legend.position = "none")

# =============================================================================
# PANEL B — Responder rate (>=5% TBWL) at 6 months on drug (ggbarstats)
# =============================================================================
panelb_data <- fig_df %>%
  filter(!is.na(resp5_6m)) %>%
  mutate(resp5_6m = factor(resp5_6m, levels = c(">=5% TBWL", "<5% TBWL")))

panel_b <- ggbarstats(
  data             = panelb_data,
  x                = resp5_6m,
  y                = glp1_timing_cat,
  type             = "nonparametric",
  proportion.test  = TRUE,
  label            = "both",
  perc.k           = 0,
  xlab             = "GLP-1 initiation timing",
  legend.title     = "Response",
  title            = "Responder rate (>=5% TBWL) at 6 months on drug",
  ggtheme          = theme_pub()
) +
  scale_fill_manual(values = c(">=5% TBWL" = "#41AB5D", "<5% TBWL" = "#D9D9D9"))

# =============================================================================
# SAVE INDIVIDUAL PANELS (no tag), 600 dpi
# =============================================================================
ggsave(file.path(fig_dir, "SuppFigure2A_tbwl_by_timing.png"), panel_a,
       width = 7, height = 5.5, dpi = 600, bg = "white")
ggsave(file.path(fig_dir, "SuppFigure2B_responder_rates.png"), panel_b,
       width = 7, height = 5.5, dpi = 600, bg = "white")

# =============================================================================
# COMPOSE FIGURE 2 (A | B) — tags on composite only
# =============================================================================
fig2 <- (panel_a + panel_b) +
  plot_annotation(
    tag_levels = "A",
    title = "Supplementary Figure 2. Weight loss at 6 months on GLP-1 therapy, by initiation timing",
    theme = theme(plot.title = element_text(face = "bold", size = 14,
                                            margin = margin(b = 8)))
  ) &
  theme(plot.tag = element_text(face = "bold", size = 15))

ggsave(file.path(fig_dir, "Figure2_weight_loss_6mo.png"), fig2,
       width = 15, height = 6.5, dpi = 600, bg = "white")
ggsave(file.path(fig_dir, "Figure2_weight_loss_6mo.pdf"), fig2,
       width = 15, height = 6.5, bg = "white")

cat("================================================================\n")
cat(" SUPPLEMENTARY FIGURE 2 SAVED (600 dpi)\n")
cat("================================================================\n")
cat("Composite (with A/B tags):\n")
cat("  SuppFigure2_weight_loss_6mo.png / .pdf\n")
cat("Individual panels (no tags):\n")
cat("  SuppFigure2A_tbwl_by_timing.png\n")
cat("  SuppFigure2B_responder_rates.png\n")