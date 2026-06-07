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
A1c <- tte$A1; A2c <- tte$A2; A3c <- tte$A3

# --- Convert TTE from days to months (1 month = 30.44 days) ------------------
DAYS_PER_MONTH <- 30.44

to_months <- function(df) {
  df %>% mutate(tte_months = tte / DAYS_PER_MONTH)
}

relevel_timing <- function(df) {
  df %>% mutate(glp1_timing_2cat = factor(glp1_timing_2cat,
                levels = c("Early (< 6 months)", "Late (>= 6 months)")))
}

A1c <- A1c %>% relevel_timing() %>% to_months()
A2c <- A2c %>% relevel_timing() %>% to_months()
A3c <- A3c %>% relevel_timing() %>% to_months()

# --- Shared options ---
pal_strata  <- c("#E69F00", "#0072B2")   # Early, Late
legend_labs <- c("Early (< 6 mo)", "Late (>= 6 mo)")
XCAP   <- 12    # months
XBREAK <- 3     # months

km_theme <- theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 13),
        panel.grid.minor = element_blank())

# =============================================================================
# PANEL BUILDERS
# surv_fit() (survminer) keeps data with the fit so ggsurvplot works in a loop.
# =============================================================================
make_km_strat <- function(df, title_txt, ylab_txt = "Cumulative incidence") {
  fit <- surv_fit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  ggsurvplot(
    fit, data = df,
    fun = "event", conf.int = TRUE, conf.int.alpha = 0.12,
    pval = TRUE, pval.size = 4, pval.coord = c(0.3, 0.92),
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

make_km_overall <- function(df, title_txt, ylab_txt = "Cumulative incidence") {
  fit <- surv_fit(Surv(tte_months, event) ~ 1, data = df)
  ggsurvplot(
    fit, data = df,
    fun = "event", conf.int = TRUE, conf.int.alpha = 0.15,
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
cat("Building stratified KM panels...\n")
p_A1 <- make_km_strat(A1c, "A. Time to >=10% weight loss")
p_A2 <- make_km_strat(A2c, "B. Time to >=20% weight loss")
p_A3 <- make_km_strat(A3c, "C. Time to pre-pregnancy weight")

cat("Building overall KM panels...\n")
o_A1 <- make_km_overall(A1c, "A. >=10% weight loss (overall)")
o_A2 <- make_km_overall(A2c, "B. >=20% weight loss (overall)")
o_A3 <- make_km_overall(A3c, "C. Pre-pregnancy weight (overall)")

# =============================================================================
# SAVE INDIVIDUAL PANELS — device-based (robust across survminer versions)
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
# COMPOSITE FIGURE 2 — 3-panel stratified
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
  extract_median(A1c, "A1: >=10% weight loss"),
  extract_median(A2c, "A2: >=20% weight loss"),
  extract_median(A3c, "A3: Pre-pregnancy weight")
)

cat("\n")
cat("## Median time-to-event by outcome and stratum\n\n")
cat(kable(median_tbl, format = "pipe", align = "lrrlll"), sep = "\n")

# Event rates at 3, 6, 12 months (cumulative incidence from KM)
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
  extract_ci_at(A1c, "A1: >=10% weight loss"),
  extract_ci_at(A2c, "A2: >=20% weight loss"),
  extract_ci_at(A3c, "A3: Pre-pregnancy weight")
)

cat("\n\n## Cumulative incidence at landmark timepoints (overall)\n\n")
cat(kable(ci_tbl, format = "pipe", align = "lrrrll", row.names = FALSE), sep = "\n")

# Log-rank p by outcome
logrank_tbl <- data.frame(
  Outcome = c("A1: >=10% weight loss", "A2: >=20% weight loss", "A3: Pre-pregnancy weight"),
  `Log-rank chi-sq` = NA_real_, df = NA_integer_, `p-value` = NA_character_,
  check.names = FALSE, stringsAsFactors = FALSE
)

for (i in 1:3) {
  d <- list(A1c, A2c, A3c)[[i]]
  lr <- survdiff(Surv(tte_months, event) ~ glp1_timing_2cat, data = d)
  logrank_tbl$`Log-rank chi-sq`[i] <- round(lr$chisq, 2)
  logrank_tbl$df[i] <- length(lr$n) - 1
  p <- pchisq(lr$chisq, df = length(lr$n) - 1, lower.tail = FALSE)
  logrank_tbl$`p-value`[i] <- ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
}

cat("\n\n## Log-rank test (Early vs Late)\n\n")
cat(kable(logrank_tbl, format = "pipe", align = "lrrl", row.names = FALSE), sep = "\n")

cat("\n\n================================================================\n")
cat(" FIGURE 2 SAVED (600 dpi)\n")
cat("================================================================\n")
cat("Composite (stratified, with A/B/C titles):\n")
cat("  Figure2_km_weight_composite.png / .pdf\n")
cat("Individual stratified panels:\n")
cat("  Figure2A_km_10pct_loss.png\n")
cat("  Figure2B_km_20pct_loss.png\n")
cat("  Figure2C_km_prepreg.png\n")
cat("Overall (supplementary):\n")
cat("  FigureS_km_weight_overall.png  + 3 individual overall panels\n")
cat("Location:", fig_dir, "\n")