# =============================================================================
# postpartum-glp1: Figure 3 — KM Curves, BP Outcomes (HDP subgroup, drug-anchored)
# -----------------------------------------------------------------------------
# Per PI analysis plan. Uses tte_datasets.rds from build_table3_revised.R
# (drug-anchored: time 0 = GLP-1 initiation).
#
# For B1 / B2 / B3 (HDP subgroup) produces:
#   - Stratified KM (early vs late): log-rank p, 95% CI bands, number-at-risk
#       table  ->  Figure 3 (3-panel composite) + individual panels
#   - Overall KM (single curve) with median TTE line  ->  supplementary 3-panel
#
# Event plotted as SURVIVAL (falling): the curve reads "proportion who have NOT
# YET achieved the BP improvement," declining as more patients reach threshold.
#
# X-axis: months (capped at 12), breaks every 3 months.
# 600 dpi. Color-blind-safe palette: Early #E69F00, Late #0072B2.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(survival)
  library(survminer)
  library(ggplot2)
  library(knitr)
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
B1c <- tte$B1; B2c <- tte$B2; B3c <- tte$B3

# --- Convert TTE from days to months (1 month = 30.44 days) ------------------
DAYS_PER_MONTH <- 30.44

to_months <- function(df) {
  df %>% mutate(tte_months = tte / DAYS_PER_MONTH)
}

relevel_timing <- function(df) {
  df %>% mutate(glp1_timing_2cat = factor(glp1_timing_2cat,
                levels = c("Early (< 6 months)", "Late (>= 6 months)")))
}

B1c <- B1c %>% relevel_timing() %>% to_months()
B2c <- B2c %>% relevel_timing() %>% to_months()
B3c <- B3c %>% relevel_timing() %>% to_months()

# --- Shared options ---
pal_strata  <- c("#E69F00", "#0072B2")   # Early, Late
legend_labs <- c("Early (< 6 mo)", "Late (>= 6 mo)")
XCAP   <- 12    # months
XBREAK <- 3     # months

km_theme <- theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 13),
        panel.grid.minor = element_blank())

# =============================================================================
# PANEL BUILDERS — SURVIVAL (falling) curves
# pval.coord moved to lower-left: a falling curve leaves open space there.
# =============================================================================
make_km_strat <- function(df, title_txt, ylab_txt = "Proportion without BP improvement") {
  fit <- surv_fit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  ggsurvplot(
    fit, data = df,
    fun = NULL,                          # survival (falling) — default
    conf.int = TRUE, conf.int.alpha = 0.12,
    pval = TRUE, pval.size = 4, pval.coord = c(0.3, 0.08),
    risk.table = TRUE, risk.table.height = 0.26,
    risk.table.title = "Number at risk", risk.table.fontsize = 3.2,
    tables.theme = theme_cleantable(),
    palette = pal_strata,
    legend.title = "GLP-1 timing", legend.labs = legend_labs, legend = "top",
    xlab = "Months since GLP-1 initiation", ylab = ylab_txt, title = title_txt,
    xlim = c(0, XCAP), break.time.by = XBREAK,
    ggtheme = km_theme, censor.size = 2
  )
}

make_km_overall <- function(df, title_txt, ylab_txt = "Proportion without BP improvement") {
  fit <- surv_fit(Surv(tte_months, event) ~ 1, data = df)
  ggsurvplot(
    fit, data = df,
    fun = NULL,
    conf.int = TRUE, conf.int.alpha = 0.15,
    surv.median.line = "hv",
    risk.table = TRUE, risk.table.height = 0.24,
    risk.table.title = "Number at risk", risk.table.fontsize = 3.2,
    tables.theme = theme_cleantable(),
    palette = "#2C7FB8", legend = "none",
    xlab = "Months since GLP-1 initiation", ylab = ylab_txt, title = title_txt,
    xlim = c(0, XCAP), break.time.by = XBREAK,
    ggtheme = km_theme, censor.size = 2
  )
}

# =============================================================================
# BUILD
# =============================================================================
cat("Building stratified KM panels (BP)...\n")
p_B1 <- make_km_strat(B1c, "A. Time to >=5 mmHg SBP decline")
p_B2 <- make_km_strat(B2c, "B. Time to >=10 mmHg SBP decline")
p_B3 <- make_km_strat(B3c, "C. Time to >=5 mmHg DBP decline")

cat("Building overall KM panels (BP)...\n")
o_B1 <- make_km_overall(B1c, "A. >=5 mmHg SBP decline (overall)")
o_B2 <- make_km_overall(B2c, "B. >=10 mmHg SBP decline (overall)")
o_B3 <- make_km_overall(B3c, "C. >=5 mmHg DBP decline (overall)")

# =============================================================================
# SAVE INDIVIDUAL PANELS — device-based (robust across survminer versions)
# =============================================================================
save_km <- function(p, fname, w = 6.5, h = 6.2, dpi = 600) {
  png(file.path(fig_dir, fname), width = w, height = h, units = "in", res = dpi)
  print(p, newpage = FALSE)
  dev.off()
}

save_km(p_B1, "Figure3A_km_sbp5.png")
save_km(p_B2, "Figure3B_km_sbp10.png")
save_km(p_B3, "Figure3C_km_dbp5.png")

save_km(o_B1, "Figure3_overall_A_sbp5.png")
save_km(o_B2, "Figure3_overall_B_sbp10.png")
save_km(o_B3, "Figure3_overall_C_dbp5.png")

# =============================================================================
# COMPOSITE FIGURE 3 — 3-panel stratified
# =============================================================================
fig3_combined <- arrange_ggsurvplots(
  list(p_B1, p_B2, p_B3),
  ncol = 3, nrow = 1, print = FALSE,
  title = "Figure 3. Time-to-event for BP outcomes by GLP-1 initiation timing (HDP subgroup, drug-anchored)"
)
ggsave(file.path(fig_dir, "Figure3_km_bp_composite.png"),
       fig3_combined, width = 19, height = 6.8, dpi = 600, bg = "white")
ggsave(file.path(fig_dir, "Figure3_km_bp_composite.pdf"),
       fig3_combined, width = 19, height = 6.8, bg = "white")

# Supplementary: overall 3-panel
figS_overall <- arrange_ggsurvplots(
  list(o_B1, o_B2, o_B3),
  ncol = 3, nrow = 1, print = FALSE,
  title = "Supplementary. Overall time-to-event for BP outcomes (HDP subgroup)"
)
ggsave(file.path(fig_dir, "FigureS_km_bp_overall.png"),
       figS_overall, width = 19, height = 6.5, dpi = 600, bg = "white")

# =============================================================================
# MEDIAN TTE + EVENT SUMMARY — knitr::kable markdown output
# =============================================================================
extract_median <- function(df, label) {
  f_all <- survfit(Surv(tte_months, event) ~ 1, data = df)
  f_str <- survfit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)

  m_all <- summary(f_all)$table["median"]
  m_str <- summary(f_str)$table[, "median"]

  fmt <- function(x) ifelse(is.na(x), "NR", sprintf("%.1f", x))

  data.frame(
    Outcome = label,
    N       = nrow(df),
    Events  = sum(df$event),
    `Overall (months)` = fmt(m_all),
    `Early (months)`   = fmt(m_str[1]),
    `Late (months)`    = fmt(m_str[2]),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

median_tbl <- rbind(
  extract_median(B1c, "B1: >=5 mmHg SBP decline"),
  extract_median(B2c, "B2: >=10 mmHg SBP decline"),
  extract_median(B3c, "B3: >=5 mmHg DBP decline")
)

cat("\n")
cat("## Median time-to-event by outcome and stratum (HDP subgroup)\n\n")
cat(kable(median_tbl, format = "pipe", align = "lrrlll"), sep = "\n")

# Cumulative incidence at 3, 6, 12 months (from KM)
# Filter requested timepoints to those within actual follow-up range, otherwise
# survfit::summary() silently drops out-of-range times and row counts mismatch.
extract_ci_at <- function(df, label, times = c(3, 6, 12)) {
  max_fu <- max(df$tte_months, na.rm = TRUE)
  times  <- times[times <= max_fu]

  if (length(times) == 0) {
    return(data.frame(
      Outcome = label, Month = NA_real_, `At risk` = NA_integer_,
      Events = NA_integer_, `Cum. incidence (%)` = "-", `95% CI` = "-",
      check.names = FALSE, stringsAsFactors = FALSE
    ))
  }

  fit <- survfit(Surv(tte_months, event) ~ 1, data = df)
  s   <- summary(fit, times = times)

  data.frame(
    Outcome = c(label, rep("", length(times) - 1)),
    Month   = times,
    `At risk`   = s$n.risk,
    Events  = s$n.event,
    `Cum. incidence (%)` = sprintf("%.1f", (1 - s$surv) * 100),
    `95% CI` = sprintf("%.1f-%.1f", (1 - s$upper) * 100, (1 - s$lower) * 100),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

ci_tbl <- rbind(
  extract_ci_at(B1c, "B1: >=5 mmHg SBP decline"),
  extract_ci_at(B2c, "B2: >=10 mmHg SBP decline"),
  extract_ci_at(B3c, "B3: >=5 mmHg DBP decline")
)

cat("\n\n## Cumulative incidence at landmark timepoints (HDP subgroup, overall)\n\n")
cat(kable(ci_tbl, format = "pipe", align = "lrrrll", row.names = FALSE), sep = "\n")

# Log-rank p by outcome
logrank_tbl <- data.frame(
  Outcome = c("B1: >=5 mmHg SBP decline", "B2: >=10 mmHg SBP decline",
              "B3: >=5 mmHg DBP decline"),
  `Log-rank chi-sq` = NA_real_, df = NA_integer_, `p-value` = NA_character_,
  check.names = FALSE, stringsAsFactors = FALSE
)

for (i in 1:3) {
  d <- list(B1c, B2c, B3c)[[i]]
  lr <- survdiff(Surv(tte_months, event) ~ glp1_timing_2cat, data = d)
  logrank_tbl$`Log-rank chi-sq`[i] <- round(lr$chisq, 2)
  logrank_tbl$df[i] <- length(lr$n) - 1
  p <- pchisq(lr$chisq, df = length(lr$n) - 1, lower.tail = FALSE)
  logrank_tbl$`p-value`[i] <- ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
}

cat("\n\n## Log-rank test, Early vs Late (HDP subgroup)\n\n")
cat(kable(logrank_tbl, format = "pipe", align = "lrrl", row.names = FALSE), sep = "\n")

cat("\n\n================================================================\n")
cat(" FIGURE 3 SAVED (600 dpi)\n")
cat("================================================================\n")
cat("Composite (stratified, with A/B/C titles):\n")
cat("  Figure3_km_bp_composite.png / .pdf\n")
cat("Individual stratified panels:\n")
cat("  Figure3A_km_sbp5.png\n")
cat("  Figure3B_km_sbp10.png\n")
cat("  Figure3C_km_dbp5.png\n")
cat("Overall (supplementary):\n")
cat("  FigureS_km_bp_overall.png  + 3 individual overall panels\n")
cat("Location:", fig_dir, "\n")