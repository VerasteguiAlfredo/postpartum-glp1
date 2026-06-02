# =============================================================================
# postpartum-glp1: Figure 2 — KM Curves, Weight Outcomes (drug-anchored)
# -----------------------------------------------------------------------------
# Per PI analysis plan. Uses tte_datasets.rds from build_table3_revised.R
# (drug-anchored: time 0 = GLP-1 initiation, follow-up capped at 540 days).
#
# For A1 / A2 / A3 produces:
#   - Stratified KM (early vs late): log-rank p, 95% CI bands, number-at-risk
#       table  ->  Figure 2 (3-panel composite) + individual panels
#   - Overall KM (single curve) with median TTE line  ->  supplementary 3-panel
#
# Event plotted as CUMULATIVE INCIDENCE (fun = "event") — curve rises as more
# patients reach the weight-loss goal (intuitive for a desirable outcome).
#
# 600 dpi. Color-blind-safe palette: Early #E69F00, Late #0072B2.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(survival)
  library(survminer)
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
fig_dir  <- file.path(proj_root, "Results", "Analysis", "Figures")
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

tte <- readRDS(file.path(data_dir, "tte_datasets.rds"))
cat("Loaded tte_datasets.rds (anchor =", tte$anchor, ")\n")
A1c <- tte$A1; A2c <- tte$A2; A3c <- tte$A3

relevel_timing <- function(df) {
  df %>% mutate(glp1_timing_2cat = factor(glp1_timing_2cat,
                levels = c("Early (< 6 months)", "Late (>= 6 months)")))
}
A1c <- relevel_timing(A1c); A2c <- relevel_timing(A2c); A3c <- relevel_timing(A3c)

# --- Shared options ---
pal_strata  <- c("#E69F00", "#0072B2")   # Early, Late
legend_labs <- c("Early (< 6 mo)", "Late (>= 6 mo)")
XCAP   <- 540
XBREAK <- 90

km_theme <- theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 13),
        panel.grid.minor = element_blank())

# =============================================================================
# PANEL BUILDERS
# surv_fit() (survminer) keeps data with the fit so ggsurvplot works in a loop.
# =============================================================================
make_km_strat <- function(df, title_txt, ylab_txt = "Cumulative incidence") {
  fit <- surv_fit(Surv(tte, event) ~ glp1_timing_2cat, data = df)
  ggsurvplot(
    fit, data = df,
    fun = "event", conf.int = TRUE, conf.int.alpha = 0.12,
    pval = TRUE, pval.size = 4, pval.coord = c(10, 0.92),
    risk.table = TRUE, risk.table.height = 0.26,
    risk.table.title = "Number at risk", risk.table.fontsize = 3.2,
    tables.theme = theme_cleantable(),
    palette = pal_strata,
    legend.title = "GLP-1 timing", legend.labs = legend_labs, legend = "top",
    xlab = "Days since GLP-1 initiation", ylab = ylab_txt, title = title_txt,
    xlim = c(0, XCAP), break.time.by = XBREAK,
    ggtheme = km_theme, censor.size = 2
  )
}

make_km_overall <- function(df, title_txt, ylab_txt = "Cumulative incidence") {
  fit <- surv_fit(Surv(tte, event) ~ 1, data = df)
  ggsurvplot(
    fit, data = df,
    fun = "event", conf.int = TRUE, conf.int.alpha = 0.15,
    surv.median.line = "hv",
    risk.table = TRUE, risk.table.height = 0.24,
    risk.table.title = "Number at risk", risk.table.fontsize = 3.2,
    tables.theme = theme_cleantable(),
    palette = "#2C7FB8", legend = "none",
    xlab = "Days since GLP-1 initiation", ylab = ylab_txt, title = title_txt,
    xlim = c(0, XCAP), break.time.by = XBREAK,
    ggtheme = km_theme, censor.size = 2
  )
}

# =============================================================================
# BUILD
# =============================================================================
cat("Building stratified KM panels...\n")
p_A1 <- make_km_strat(A1c, "A. Time to \u226510% weight loss")
p_A2 <- make_km_strat(A2c, "B. Time to \u226520% weight loss")
p_A3 <- make_km_strat(A3c, "C. Time to pre-pregnancy weight")

cat("Building overall KM panels...\n")
o_A1 <- make_km_overall(A1c, "A. \u226510% weight loss (overall)")
o_A2 <- make_km_overall(A2c, "B. \u226520% weight loss (overall)")
o_A3 <- make_km_overall(A3c, "C. Pre-pregnancy weight (overall)")

# =============================================================================
# SAVE INDIVIDUAL PANELS — device-based (robust across survminer versions)
# A ggsurvplot object draws plot + risk table via its print method; opening a
# device and printing captures both together.
# =============================================================================
save_km <- function(p, fname, w = 6.5, h = 6.2, dpi = 600) {
  png(file.path(fig_dir, fname), width = w, height = h, units = "in", res = dpi)
  print(p, newpage = FALSE)
  dev.off()
}

save_km(p_A1, "Figure2A_km_10pct_loss.png")
save_km(p_A2, "Figure2B_km_20pct_loss.png")
save_km(p_A3, "Figure2C_km_prepreg.png")

save_km(o_A1, "Figure2_overall_A_10pct.png")
save_km(o_A2, "Figure2_overall_B_20pct.png")
save_km(o_A3, "Figure2_overall_C_prepreg.png")

# =============================================================================
# COMPOSITE FIGURE 2 — 3-panel stratified (arrange_ggsurvplots handles tables)
# =============================================================================
fig2_combined <- arrange_ggsurvplots(
  list(p_A1, p_A2, p_A3),
  ncol = 3, nrow = 1, print = FALSE,
  title = "Figure 2. Time-to-event for weight outcomes by GLP-1 initiation timing (drug-anchored)"
)
ggsave(file.path(fig_dir, "Figure2_km_weight_composite.png"),
       fig2_combined, width = 19, height = 6.8, dpi = 600, bg = "white")
ggsave(file.path(fig_dir, "Figure2_km_weight_composite.pdf"),
       fig2_combined, width = 19, height = 6.8, bg = "white")

# Supplementary: overall 3-panel
figS_overall <- arrange_ggsurvplots(
  list(o_A1, o_A2, o_A3),
  ncol = 3, nrow = 1, print = FALSE,
  title = "Supplementary. Overall time-to-event for weight outcomes (full cohort)"
)
ggsave(file.path(fig_dir, "FigureS_km_weight_overall.png"),
       figS_overall, width = 19, height = 6.5, dpi = 600, bg = "white")

# =============================================================================
# MEDIAN TTE SUMMARY (console — matches Table 3 medians)
# =============================================================================
cat("\n--- Median time-to-event (days) by outcome & stratum ---\n")
med_summary <- function(df, label) {
  f_all <- survfit(Surv(tte, event) ~ 1, data = df)
  f_str <- survfit(Surv(tte, event) ~ glp1_timing_2cat, data = df)
  m_all <- summary(f_all)$table["median"]
  m_str <- summary(f_str)$table[, "median"]
  cat(sprintf("%-26s overall=%s | %s\n", label,
              ifelse(is.na(m_all), "NR", round(m_all)),
              paste(names(m_str), ifelse(is.na(m_str), "NR", round(m_str)),
                    sep = "=", collapse = " | ")))
}
med_summary(A1c, "A1 >=10% weight loss")
med_summary(A2c, "A2 >=20% weight loss")
med_summary(A3c, "A3 pre-pregnancy weight")

cat("\n================================================================\n")
cat(" FIGURE 2 SAVED (600 dpi)\n")
cat("================================================================\n")
cat("Composite (stratified, with A/B/C titles):\n")
cat("  Figure2_km_weight_composite.png / .pdf\n")
cat("Individual stratified panels (no tag):\n")
cat("  Figure2A_km_10pct_loss.png\n")
cat("  Figure2B_km_20pct_loss.png\n")
cat("  Figure2C_km_prepreg.png\n")
cat("Overall (supplementary):\n")
cat("  FigureS_km_weight_overall.png  + 3 individual overall panels\n")
cat("Location:", fig_dir, "\n")