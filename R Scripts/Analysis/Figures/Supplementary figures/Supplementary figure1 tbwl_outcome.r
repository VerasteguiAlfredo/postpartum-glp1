# =============================================================================
# postpartum-glp1: Figure 1 — TBWL% Trajectory by Time on Drug
# -----------------------------------------------------------------------------
# Single-panel hero figure: LOESS trajectory of total body weight loss (%) by
# GLP-1 timing stratum, anchored to GLP-1 initiation, with:
#   - vertical reference lines at 3 / 6 / 12 months on drug
#   - Kruskal-Wallis between-strata p-value at each landmark
#   - median TBWL% labels per stratum at each landmark
# 600 dpi. No panel tag (standalone figure).
#
# Source AFTER build_analysis_dataset_v3.R
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
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
      plot.title       = element_text(face = "bold", size = base_size + 2, hjust = 0),
      plot.subtitle    = element_text(size = base_size - 1, color = "#4D4D4D", hjust = 0),
      axis.title       = element_text(size = base_size),
      axis.text        = element_text(size = base_size - 1, color = "#333333"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#E8E8E8", linewidth = 0.3),
      legend.position  = "bottom",
      legend.title     = element_text(size = base_size - 1, face = "bold"),
      legend.text      = element_text(size = base_size - 1),
      plot.margin      = margin(12, 16, 12, 12)
    )
}

# =============================================================================
# DATA PREP — drug-anchored TBWL% trajectory + landmark values
# =============================================================================
traj_df <- vitals_long %>%
  filter(vital == "weight_kg", !is.na(glp1_timing_cat),
         days_from_glp1 >= 0, days_from_glp1 <= 540) %>%
  inner_join(analysis_df %>% select(CURR_CLINIC, weight_kg_baseline_combined),
             by = "CURR_CLINIC") %>%
  filter(!is.na(weight_kg_baseline_combined)) %>%
  mutate(tbwl_pct = (weight_kg_baseline_combined - value) / weight_kg_baseline_combined * 100,
         glp1_timing_cat = factor(glp1_timing_cat, levels = strata_levels))

# Helper: closest measurement to a landmark day, per patient, drug-anchored
closest_post_glp1 <- function(df, target_day, window_days) {
  df %>%
    filter(!is.na(days_from_glp1),
           days_from_glp1 >= target_day - window_days,
           days_from_glp1 <= target_day + window_days,
           days_from_glp1 >= 0) %>%
    group_by(CURR_CLINIC) %>%
    arrange(abs(days_from_glp1 - target_day), .by_group = TRUE) %>%
    slice(1) %>% ungroup()
}

wt_sub <- vitals_long %>%
  filter(vital == "weight_kg", !is.na(glp1_timing_cat)) %>%
  inner_join(analysis_df %>% select(CURR_CLINIC, weight_kg_baseline_combined),
             by = "CURR_CLINIC") %>%
  filter(!is.na(weight_kg_baseline_combined)) %>%
  mutate(tbwl_pct = (weight_kg_baseline_combined - value) / weight_kg_baseline_combined * 100,
         glp1_timing_cat = factor(glp1_timing_cat, levels = strata_levels))

landmarks <- tibble(
  label_mo = c("3 mo", "6 mo", "12 mo"),
  day      = c(90, 180, 365),
  window   = c(30, 45, 60)
)

# Compute, per landmark: KW p-value across strata + per-stratum median TBWL%
landmark_stats <- lapply(seq_len(nrow(landmarks)), function(i) {
  lm_day <- landmarks$day[i]
  lm_win <- landmarks$window[i]
  sub    <- closest_post_glp1(wt_sub, lm_day, lm_win)

  # KW across strata (needs >=2 groups with data)
  kw_p <- NA_real_
  if (n_distinct(sub$glp1_timing_cat) >= 2 && nrow(sub) >= 5) {
    kw_p <- suppressWarnings(
      kruskal.test(sub$tbwl_pct, sub$glp1_timing_cat)$p.value
    )
  }

  med_by_stratum <- sub %>%
    group_by(glp1_timing_cat) %>%
    summarise(median_tbwl = median(tbwl_pct, na.rm = TRUE),
              n = n(), .groups = "drop") %>%
    mutate(day = lm_day, label_mo = landmarks$label_mo[i])

  list(kw_p = kw_p, medians = med_by_stratum,
       day = lm_day, label_mo = landmarks$label_mo[i])
})

# Build a p-value annotation table
pval_tbl <- tibble(
  day      = sapply(landmark_stats, `[[`, "day"),
  label_mo = sapply(landmark_stats, `[[`, "label_mo"),
  kw_p     = sapply(landmark_stats, `[[`, "kw_p")
) %>%
  mutate(p_label = ifelse(is.na(kw_p), "p = NA",
                   ifelse(kw_p < 0.001, "p < 0.001",
                          sprintf("p = %.3f", kw_p))))

# Median labels table (for plotting near each landmark)
med_tbl <- bind_rows(lapply(landmark_stats, `[[`, "medians"))

cat("--- Landmark Kruskal-Wallis p-values (between strata) ---\n")
print(pval_tbl)
cat("\n--- Median TBWL% by stratum at each landmark ---\n")
print(med_tbl)
cat("\n")

# =============================================================================
# FIGURE 1 — LOESS trajectory with landmark stats
# =============================================================================
ymax <- 22

fig1 <- ggplot(traj_df, aes(x = days_from_glp1, y = tbwl_pct,
                            color = glp1_timing_cat, fill = glp1_timing_cat)) +
  # TBWL threshold lines
  geom_hline(yintercept = c(5, 10, 15), linetype = "dotted",
             color = "#888888", linewidth = 0.4) +
  geom_hline(yintercept = 0, color = "#1A1A1A", linewidth = 0.4) +
  # landmark vertical lines
  geom_vline(xintercept = c(90, 180, 365), linetype = "dashed",
             color = "#B0B0B0", linewidth = 0.4) +
  # LOESS curves
  geom_smooth(method = "loess", se = TRUE, span = 0.6, alpha = 0.12, linewidth = 1.0) +
  # threshold labels (right edge)
  annotate("text", x = 535, y = 5,  label = "5%",  hjust = 1, vjust = -0.4,
           size = 3, color = "#666666") +
  annotate("text", x = 535, y = 10, label = "10%", hjust = 1, vjust = -0.4,
           size = 3, color = "#666666") +
  annotate("text", x = 535, y = 15, label = "15%", hjust = 1, vjust = -0.4,
           size = 3, color = "#666666") +
  # landmark p-value annotations (top of plot)
  geom_text(data = pval_tbl,
            aes(x = day, y = ymax, label = paste0(label_mo, "\n", p_label)),
            inherit.aes = FALSE, vjust = 1, hjust = 0.5, size = 3,
            color = "#1A1A1A", lineheight = 0.9, fontface = "plain") +
  scale_color_manual(values = strata_colors, name = "GLP-1 initiation timing") +
  scale_fill_manual(values = strata_colors, name = "GLP-1 initiation timing") +
  scale_x_continuous(breaks = seq(0, 540, 90),
                     labels = c("0", "3", "6", "9", "12", "15", "18")) +
  coord_cartesian(ylim = c(-5, ymax), xlim = c(0, 540)) +
  labs(title = "Supplementary Figure 1. Weight-loss trajectory by time on GLP-1 therapy",
       subtitle = paste0("Total body weight loss (%) from baseline, anchored to GLP-1 initiation. ",
                         "Dashed lines mark 3/6/12-month landmarks; p-values are\n",
                         "Kruskal-Wallis between timing strata at each landmark."),
       x = "Months since GLP-1 initiation", y = "Total body weight loss (%)") +
  theme_pub() +
  guides(color = guide_legend(nrow = 1), fill = guide_legend(nrow = 1))

ggsave(file.path(fig_dir, "SuppFigure1_tbwl_trajectory.png"), fig1,
       width = 9, height = 6.5, dpi = 600, bg = "white")
ggsave(file.path(fig_dir, "SuppFigure1_tbwl_trajectory.pdf"), fig1,
       width = 9, height = 6.5, bg = "white")

cat("================================================================\n")
cat(" SUPPLEMENTARY FIGURE 1 SAVED (600 dpi)\n")
cat("================================================================\n")
cat("  SuppFigure1_tbwl_trajectory.png\n")
cat("  SuppFigure1_tbwl_trajectory.pdf\n")
cat("Location:", fig_dir, "\n")