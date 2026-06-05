# =============================================================================
# postpartum-glp1 | KM Curves — DELIVERY-ANCHORED (PI revision)
# Script:  km_curves_delivery_anchored.R
# Author:  MDH Lab
# -----------------------------------------------------------------------------
# Time origin = DELIVERY (day 0).  Both groups are plotted over a common
# 0–12 month postpartum window.  During months 0–6 the Late initiators
# (>= 6 mo) are UNTREATED and serve as a natural-history comparison arm;
# a dashed reference line at month 6 marks where that group transitions onto
# GLP-1 therapy.
#
# Panel labeling (journal convention):
#   Top row    — Weight outcomes  : A (>=10% loss)  B (>=20% loss)  C (pre-pregnancy wt)
#   Bottom row — BP outcomes (HDP): D (>=5 mmHg SBP) E (>=10 mmHg SBP) F (>=5 mmHg DBP)
#
# Outputs
#   Figures   : individual panels + composites (PNG 600 dpi + PDF)
#   Tables    : median TTE, landmark CI, 6-mo natural-history, full log-rank
#   Caption   : high-impact journal-style figure caption printed to console
#   Markdown  : all tables written to figure_km_delivery_results.md
#
# Color-blind-safe palette  Early #E69F00 | Late #0072B2
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(survival)
  library(survminer)
  library(ggplot2)
  library(knitr)
  library(gridExtra)
})

# =============================================================================
# PARAMETERS
# =============================================================================
DAYS_PER_MONTH     <- 30.44
FOLLOWUP_CAP       <- round(12 * DAYS_PER_MONTH)   # administrative cap ~365 d
XCAP_MONTHS        <- 12
XBREAK_MONTHS      <- 3
LATE_START_MO      <- 6     # month Late group begins GLP-1
N_AT_RISK_MIN      <- 10    # truncate curve where either group drops below this

N_AT_RISK_MIN      <- 10    # truncate curve where either group drops below this
CHI2_COL           <- paste0("Log-rank ", "\u03c7", "\u00b2")   # "Log-rank χ²"

# BP-specific anchoring rules (per PI)
BP_BASELINE_WINDOW <- 2     # +/- days around delivery for single baseline BP
BP_EVENT_START_DAY <- 14    # blanking period: first event-eligible BP >= 2 wk pp

# =============================================================================
# PATHS (cross-platform)
# =============================================================================
sys_name  <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}
data_dir <- file.path(proj_root, "data_processed")
fig_dir  <- file.path(proj_root, "Results", "Analysis", "Figures")
md_dir   <- file.path(proj_root, "Results", "Analysis", "Tables", "MD Files")
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)
if (!dir.exists(md_dir))  dir.create(md_dir,  recursive = TRUE)

# =============================================================================
# MARKDOWN ACCUMULATOR
# =============================================================================
.md_lines <- c("# Delivery-anchored KM results", "")

emit <- function(header, kable_txt) {
  block <- c(paste0("## ", header), "", kable_txt, "")
  .md_lines <<- c(.md_lines, block)
  cat("\n## ", header, "\n\n", sep = "")
  cat(kable_txt, sep = "\n")
  cat("\n")
}

# =============================================================================
# DATA LOADING
# =============================================================================
analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))
vitals_long <- readRDS(file.path(data_dir, "vitals_long.rds"))
cat("Loaded analysis_df (", nrow(analysis_df), " rows) and vitals_long (",
    nrow(vitals_long), " rows)\n", sep = "")

# HDP subgroup definition (consistent with main analysis)
analysis_df <- analysis_df %>%
  mutate(
    bp_stage2_baseline =
      (!is.na(sbp_baseline_combined) & sbp_baseline_combined >= 140) |
      (!is.na(dbp_baseline_combined) & dbp_baseline_combined >= 90),
    hdp_cohort = (preg_htn_any == TRUE) | bp_stage2_baseline
  )

full_ids <- analysis_df$CURR_CLINIC
hdp_ids  <- analysis_df %>% filter(hdp_cohort) %>% pull(CURR_CLINIC)
cat("Full cohort: ", length(full_ids),
    " | HDP subgroup: ", length(hdp_ids), "\n\n", sep = "")

# =============================================================================
# BASELINE CONSTRUCTION
# =============================================================================

# Weight: earliest postpartum measurement per patient
earliest_pp_baseline <- function(vital_name) {
  vitals_long %>%
    filter(vital == vital_name, days_from_delivery >= 0, !is.na(value)) %>%
    group_by(CURR_CLINIC) %>%
    slice_min(days_from_delivery, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    transmute(CURR_CLINIC, baseline = value, baseline_day = days_from_delivery)
}

# BP: single peripartum value within +/- BP_BASELINE_WINDOW days of delivery
delivery_date_bp_baseline <- function(vital_name) {
  vitals_long %>%
    filter(vital == vital_name, !is.na(value),
           abs(days_from_delivery) <= BP_BASELINE_WINDOW) %>%
    group_by(CURR_CLINIC) %>%
    slice_min(abs(days_from_delivery), n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    transmute(CURR_CLINIC, baseline = value, baseline_day = days_from_delivery)
}

# Pre-pregnancy weight (Panel C reference)
prepreg_baseline_df <- analysis_df %>%
  transmute(
    CURR_CLINIC,
    baseline     = PREGRAVID_BMI * (height_cm / 100)^2,
    baseline_day = NA_real_
  ) %>%
  filter(!is.na(baseline))

wt_base  <- earliest_pp_baseline("weight_kg")
sbp_base <- delivery_date_bp_baseline("sbp")
dbp_base <- delivery_date_bp_baseline("dbp")

# Baseline-timing diagnostic tables
bl_report <- wt_base %>%
  inner_join(analysis_df %>% select(CURR_CLINIC, glp1_timing_2cat),
             by = "CURR_CLINIC") %>%
  group_by(glp1_timing_2cat) %>%
  summarise(
    n = n(),
    `Baseline day, median (IQR)` = sprintf(
      "%.0f (%.0f\u2013%.0f)",
      median(baseline_day),
      quantile(baseline_day, .25),
      quantile(baseline_day, .75)
    ),
    .groups = "drop"
  ) %>%
  rename(Stratum = glp1_timing_2cat)
emit("Weight baseline timing (days from delivery to earliest measurement)",
     kable(bl_report, format = "pipe", align = "lrl"))

bp_report <- sbp_base %>%
  mutate(source = case_when(
    baseline_day == 0 ~ "Delivery day (day 0)",
    baseline_day <  0 ~ "1\u20132 days before delivery",
    TRUE              ~ "1\u20132 days after delivery"
  )) %>%
  group_by(source) %>%
  summarise(n = n(), .groups = "drop") %>%
  rename(`Baseline source` = source)
bp_note <- c(
  kable(bp_report, format = "pipe", align = "lr"), "",
  sprintf(
    "SBP delivery baseline (within \u00b1%d d): %d patients; %d HDP patients without one.",
    BP_BASELINE_WINDOW, nrow(sbp_base),
    length(setdiff(hdp_ids, sbp_base$CURR_CLINIC))
  ),
  sprintf(
    "Event ascertainment begins at day %d (%.1f weeks) postpartum (blanking delivery admission).",
    BP_EVENT_START_DAY, BP_EVENT_START_DAY / 7
  )
)
emit("SBP delivery-date baseline coverage (single value per patient)", bp_note)

# =============================================================================
# DELIVERY-ANCHORED TTE BUILDER
# =============================================================================
build_tte_delivery <- function(vital_name, baseline_df, event_fn, cohort_ids,
                               cap = FOLLOWUP_CAP, event_start_day = 0) {
  vl <- vitals_long %>%
    filter(
      vital == vital_name,
      days_from_delivery >= event_start_day,
      days_from_delivery <= cap,
      !is.na(value),
      CURR_CLINIC %in% cohort_ids
    ) %>%
    inner_join(baseline_df, by = "CURR_CLINIC") %>%
    mutate(is_event = event_fn(value, baseline))

  vl %>%
    group_by(CURR_CLINIC) %>%
    summarise(
      last_day        = max(days_from_delivery),
      first_event_day = if (any(is_event)) min(days_from_delivery[is_event]) else NA_real_,
      .groups = "drop"
    ) %>%
    mutate(
      event      = as.integer(!is.na(first_event_day)),
      tte_days   = pmin(ifelse(event == 1, first_event_day, last_day), cap),
      tte_days   = ifelse(tte_days <= 0, 0.5, tte_days),
      tte_months = tte_days / DAYS_PER_MONTH
    ) %>%
    inner_join(
      analysis_df %>% select(CURR_CLINIC, glp1_timing_2cat),
      by = "CURR_CLINIC"
    ) %>%
    mutate(glp1_timing_2cat = factor(
      glp1_timing_2cat,
      levels = c("Early (< 6 months)", "Late (>= 6 months)")
    ))
}

# =============================================================================
# OUTCOME CONFIGURATION
# Panel labels: Weight = A/B/C | BP = D/E/F
# =============================================================================
cfg <- list(
  A = list(vital = "weight_kg", base = wt_base,
           fn    = function(v, b) v <= b * 0.90,
           label = "A: \u226510% weight loss",
           ids   = full_ids,
           es    = 0),
  B = list(vital = "weight_kg", base = wt_base,
           fn    = function(v, b) v <= b * 0.80,
           label = "B: \u226520% weight loss",
           ids   = full_ids,
           es    = 0),
  C = list(vital = "weight_kg", base = prepreg_baseline_df,
           fn    = function(v, b) v <= b,
           label = "C: Return to pre-pregnancy weight",
           ids   = full_ids,
           es    = 0),
  D = list(vital = "sbp",       base = sbp_base,
           fn    = function(v, b) (b - v) >= 5,
           label = "D: \u22655 mmHg SBP decline",
           ids   = hdp_ids,
           es    = BP_EVENT_START_DAY),
  E = list(vital = "sbp",       base = sbp_base,
           fn    = function(v, b) (b - v) >= 10,
           label = "E: \u226510 mmHg SBP decline",
           ids   = hdp_ids,
           es    = BP_EVENT_START_DAY),
  F = list(vital = "dbp",       base = dbp_base,
           fn    = function(v, b) (b - v) >= 5,
           label = "F: \u22655 mmHg DBP decline",
           ids   = hdp_ids,
           es    = BP_EVENT_START_DAY)
)

cat("Building delivery-anchored TTE datasets...\n")
tte_dlv <- lapply(cfg, function(o)
  build_tte_delivery(o$vital, o$base, o$fn, o$ids, event_start_day = o$es))
names(tte_dlv) <- names(cfg)

# =============================================================================
# KM PLOTTING HELPERS
# =============================================================================
pal_strata  <- c("#E69F00", "#0072B2")
legend_labs <- c("Early (< 6 mo)", "Late (\u2265 6 mo)")

km_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title       = element_text(face = "bold", size = 13),
    panel.grid.minor = element_blank(),
    legend.position  = "top"
  )

fmt_p3 <- function(p) {
  if (is.na(p))    return("p = NA")
  if (p < 0.001)   return("p < 0.001")
  paste0("p = ", formatC(signif(p, 3), format = "fg", digits = 3))
}

last_reliable_time <- function(df, n_min) {
  fit <- survfit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  s   <- summary(fit)
  tab <- data.frame(
    time   = s$time,
    nrisk  = s$n.risk,
    strata = as.character(s$strata),
    stringsAsFactors = FALSE
  )
  per <- tapply(seq_len(nrow(tab)), tab$strata, function(i) {
    x  <- tab[i, , drop = FALSE]
    ok <- x$time[x$nrisk >= n_min]
    if (!length(ok)) 0 else max(ok)
  })
  as.numeric(min(per))
}

make_km_panel <- function(df, panel_letter, title_suffix,
                          ylab_txt, pval_y = 0.10) {
  # Log-rank p over full analysis window
  lr    <- survdiff(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  p_txt <- fmt_p3(pchisq(lr$chisq, df = length(lr$n) - 1, lower.tail = FALSE))

  # Truncate display where either stratum has < N_AT_RISK_MIN at risk
  t_trunc  <- min(last_reliable_time(df, N_AT_RISK_MIN), XCAP_MONTHS)
  df_disp  <- df %>%
    mutate(
      event      = ifelse(tte_months > t_trunc, 0L, event),
      tte_months = pmin(tte_months, t_trunc)
    )

  fit      <- surv_fit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df_disp)
  title_txt <- paste0(panel_letter, ". ", title_suffix)

  gg <- ggsurvplot(
    fit,
    data               = df_disp,
    conf.int           = TRUE,
    conf.int.alpha     = 0.12,
    pval               = p_txt,
    pval.size          = 3.8,
    pval.coord         = c(0.3, pval_y),
    risk.table         = TRUE,
    risk.table.height  = 0.26,
    risk.table.title   = "No. at risk",
    risk.table.fontsize = 3.2,
    tables.theme       = theme_cleantable(),
    palette            = pal_strata,
    legend.title       = "GLP-1 initiation",
    legend.labs        = legend_labs,
    legend             = "top",
    xlab               = "Months since delivery",
    ylab               = ylab_txt,
    title              = title_txt,
    xlim               = c(0, XCAP_MONTHS),
    break.time.by      = XBREAK_MONTHS,
    ggtheme            = km_theme,
    censor.size        = 2
  )

  # Dashed reference line at month 6 (Late group begins GLP-1)
  gg$plot <- gg$plot +
    geom_vline(
      xintercept = LATE_START_MO,
      linetype   = "dashed",
      color      = "#444444",
      linewidth  = 0.5
    ) +
    annotate(
      "text",
      x      = LATE_START_MO + 0.2,
      y      = 0.50,
      label  = "Late group begins GLP-1",
      angle  = 90,
      vjust  = -0.4,
      size   = 2.7,
      color  = "#444444"
    )
  gg
}

# =============================================================================
# BUILD ALL PANELS (Unicode for PNG | ASCII for PDF)
# =============================================================================
ylab_wt <- "Proportion without weight loss"
ylab_bp <- "Proportion without BP improvement"

build_all_panels <- function(ge) {
  list(
    A = make_km_panel(tte_dlv$A, "A", paste0(ge, "10% weight loss"),             ylab_wt),
    B = make_km_panel(tte_dlv$B, "B", paste0(ge, "20% weight loss"),             ylab_wt),
    C = make_km_panel(tte_dlv$C, "C", "Return to pre-pregnancy weight",          ylab_wt),
    D = make_km_panel(tte_dlv$D, "D", paste0(ge, "5 mmHg SBP decline (HDP)"),   ylab_bp),
    E = make_km_panel(tte_dlv$E, "E", paste0(ge, "10 mmHg SBP decline (HDP)"),  ylab_bp),
    F = make_km_panel(tte_dlv$`F`, "F", paste0(ge, "5 mmHg DBP decline (HDP)"), ylab_bp)
  )
}

cat("Building panels (Unicode \u2265 for PNG)...\n")
P <- build_all_panels("\u2265")   # PNG set
cat("Building panels (ASCII >= for PDF)...\n")
Q <- build_all_panels(">=")       # PDF set

# =============================================================================
# DEVICE-AWARE SAVERS
# =============================================================================
png_type <- tryCatch(
  if (isTRUE(capabilities("cairo")))  "cairo"
  else if (isTRUE(capabilities("aqua"))) "quartz"
  else "Xlib",
  error = function(e) "cairo"
)

save_panel_png <- function(p, fname, w = 6.5, h = 6.4, dpi = 600) {
  png(file.path(fig_dir, fname), width = w, height = h, units = "in",
      res = dpi, type = png_type, bg = "white")
  print(p, newpage = FALSE)
  dev.off()
  cat("  Saved:", fname, "\n")
}

save_panel_pdf <- function(p, fname, w = 6.5, h = 6.4) {
  pdf(file.path(fig_dir, fname), width = w, height = h, bg = "white")
  print(p, newpage = FALSE)
  dev.off()
  cat("  Saved:", fname, "\n")
}

save_grob_png <- function(g, fname, w, h, dpi = 600) {
  png(file.path(fig_dir, fname), width = w, height = h, units = "in",
      res = dpi, type = png_type, bg = "white")
  grid::grid.draw(g)
  dev.off()
  cat("  Saved:", fname, "\n")
}

save_grob_pdf <- function(g, fname, w, h) {
  pdf(file.path(fig_dir, fname), width = w, height = h, bg = "white")
  grid::grid.draw(g)
  dev.off()
  cat("  Saved:", fname, "\n")
}

# =============================================================================
# SAVE INDIVIDUAL PANELS
# =============================================================================
cat("\nSaving individual panels...\n")

# Weight panels (A–C)
save_panel_png(P$A, "Figure2_A_wt10pct.png")
save_panel_png(P$B, "Figure2_B_wt20pct.png")
save_panel_png(P$C, "Figure2_C_prepreg.png")

# BP panels (D–F)
save_panel_png(P$D, "Figure3_D_sbp5.png")
save_panel_png(P$E, "Figure3_E_sbp10.png")
save_panel_png(P$`F`, "Figure3_F_dbp5.png")

# =============================================================================
# COMPOSITE FIGURES
# =============================================================================
cat("\nSaving composite figures...\n")

# --- Figure 2: Weight outcomes (A–C) -----------------------------------------
title_fig2 <- paste0(
  "Figure 2. Delivery-anchored time-to-weight-loss outcomes ",
  "(Late group untreated months 0\u20136)"
)
fig2_png <- arrange_ggsurvplots(
  list(P$A, P$B, P$C), ncol = 3, nrow = 1, print = FALSE, title = title_fig2
)
fig2_pdf <- arrange_ggsurvplots(
  list(Q$A, Q$B, Q$C), ncol = 3, nrow = 1, print = FALSE, title = title_fig2
)
save_grob_png(fig2_png, "Figure2_wt_composite.png", w = 19, h = 7.0)
save_grob_pdf(fig2_pdf, "Figure2_wt_composite.pdf", w = 19, h = 7.0)

# --- Figure 3: BP outcomes (D–F), HDP subgroup --------------------------------
title_fig3 <- paste0(
  "Figure 3. Delivery-anchored time-to-BP-improvement, HDP subgroup ",
  "(Late group untreated months 0\u20136)"
)
fig3_png <- arrange_ggsurvplots(
  list(P$D, P$E, P$`F`), ncol = 3, nrow = 1, print = FALSE, title = title_fig3
)
fig3_pdf <- arrange_ggsurvplots(
  list(Q$D, Q$E, Q$`F`), ncol = 3, nrow = 1, print = FALSE, title = title_fig3
)
save_grob_png(fig3_png, "Figure3_bp_composite.png", w = 19, h = 7.0)
save_grob_pdf(fig3_pdf, "Figure3_bp_composite.pdf", w = 19, h = 7.0)

# --- Combined 2-row figure (A–C top | D–F bottom) ----------------------------
library(gridExtra)

title_combined <- paste0(
  "Delivery-anchored Kaplan-Meier curves: ",
  "weight outcomes (A\u2013C, top) and BP outcomes (D\u2013F, bottom, HDP subgroup)"
)

make_combined_grob <- function(panels, title_txt) {
  grobs <- lapply(panels, function(p) ggplotGrob(p$plot))
  title_grob <- grid::textGrob(
    title_txt,
    gp = grid::gpar(fontsize = 13, fontface = "bold")
  )
  gridExtra::arrangeGrob(
    grobs[[1]], grobs[[2]], grobs[[3]],
    grobs[[4]], grobs[[5]], grobs[[6]],
    ncol = 3, nrow = 2,
    top = title_grob
  )
}

fig_cmb_png <- make_combined_grob(list(P$A, P$B, P$C, P$D, P$E, P$`F`), title_combined)
fig_cmb_pdf <- make_combined_grob(list(Q$A, Q$B, Q$C, Q$D, Q$E, Q$`F`), title_combined)

save_grob_png(fig_cmb_png, "Figure_combined_km.png", w = 19, h = 14.5)
save_grob_pdf(fig_cmb_pdf, "Figure_combined_km.pdf", w = 19, h = 14.5)

# =============================================================================
# SUMMARY TABLES
# =============================================================================

# --- 1. Median TTE by stratum -------------------------------------------------
extract_median <- function(df, label) {
  f_all <- survfit(Surv(tte_months, event) ~ 1,                   data = df)
  f_str <- survfit(Surv(tte_months, event) ~ glp1_timing_2cat,    data = df)
  m_all <- summary(f_all)$table["median"]
  m_str <- summary(f_str)$table[, "median"]
  fmt   <- function(x) ifelse(is.na(x), "NR", sprintf("%.1f", x))
  data.frame(
    Outcome          = label,
    N                = nrow(df),
    Events           = sum(df$event),
    `Overall (mo)`   = fmt(m_all),
    `Early (mo)`     = fmt(m_str[1]),
    `Late (mo)`      = fmt(m_str[2]),
    check.names      = FALSE,
    stringsAsFactors = FALSE
  )
}
median_tbl <- do.call(rbind, lapply(names(cfg), function(k)
  extract_median(tte_dlv[[k]], cfg[[k]]$label)))
emit("Median time-to-event by stratum (delivery-anchored, months)",
     kable(median_tbl, format = "pipe", align = "lrrlll"))

# --- 2. Landmark cumulative incidence (3/6/12 mo) ----------------------------
extract_ci_strat <- function(df, label, times = c(3, 6, 12)) {
  max_fu <- max(df$tte_months, na.rm = TRUE)
  times  <- times[times <= max_fu]
  if (!length(times)) return(NULL)
  fit <- survfit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  s   <- summary(fit, times = times)
  data.frame(
    Outcome              = label,
    Group                = sub("glp1_timing_2cat=", "", as.character(s$strata)),
    `Month`              = s$time,
    `Cumulative incidence (%)` = sprintf("%.1f", (1 - s$surv) * 100),
    `95% CI`             = sprintf("%.1f\u2013%.1f",
                             (1 - s$upper) * 100, (1 - s$lower) * 100),
    check.names          = FALSE,
    stringsAsFactors     = FALSE
  )
}
ci_tbl <- do.call(rbind, lapply(names(cfg), function(k)
  extract_ci_strat(tte_dlv[[k]], cfg[[k]]$label)))
emit("Stratified cumulative incidence at landmark timepoints (delivery-anchored)",
     kable(ci_tbl, format = "pipe", align = "llrll", row.names = FALSE))

# --- 3. 6-month natural-history comparison ------------------------------------
ci6_by_group <- function(df) {
  fit <- survfit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  s   <- summary(fit, times = 6)
  grp <- sub("glp1_timing_2cat=", "", as.character(s$strata))
  ci  <- sprintf("%.1f (%.1f\u2013%.1f)",
                 (1 - s$surv) * 100,
                 (1 - s$upper) * 100,
                 (1 - s$lower) * 100)
  out <- setNames(ci, grp)
  function(g) if (g %in% names(out)) out[[g]] else "\u2014"
}

logrank6 <- function(df) {
  d6 <- df %>% mutate(
    event6 = ifelse(tte_months <= 6 & event == 1, 1L, 0L),
    tte6   = pmin(tte_months, 6)
  )
  lr <- survdiff(Surv(tte6, event6) ~ glp1_timing_2cat, data = d6)
  p  <- pchisq(lr$chisq, df = length(lr$n) - 1, lower.tail = FALSE)
  ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
}

nathist_tbl <- do.call(rbind, lapply(names(cfg), function(k) {
  df  <- tte_dlv[[k]]
  ci6 <- ci6_by_group(df)
  out <- data.frame(
    Outcome      = cfg[[k]]$label,
    early_6mo    = ci6("Early (< 6 months)"),
    late_6mo     = ci6("Late (>= 6 months)"),
    logrank6_col = logrank6(df),
    check.names      = FALSE,
    stringsAsFactors = FALSE
  )
  names(out) <- c("Outcome",
                  "Early at 6 mo (treated), % (95% CI)",
                  "Late at 6 mo (untreated), % (95% CI)",
                  LOGRANK6_COL)
  out
}))
emit("6-month natural-history comparison: Early (treated) vs Late (untreated)",
     kable(nathist_tbl, format = "pipe", align = "llll", row.names = FALSE))

# --- 4. Full 0-12 mo log-rank -------------------------------------------------
logrank_full <- function(df) {
  lr      <- survdiff(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  p       <- pchisq(lr$chisq, df = length(lr$n) - 1, lower.tail = FALSE)
  out     <- data.frame(
    chi2    = round(lr$chisq, 2),
    p_value = ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)),
    stringsAsFactors = FALSE
  )
  names(out) <- c(paste0("Log-rank ", "\u03c7", "\u00b2"), "p-value")
  out
}
full_lr_tbl <- do.call(rbind, lapply(names(cfg), function(k) {
  r          <- logrank_full(tte_dlv[[k]])
  r$Outcome  <- cfg[[k]]$label
  r[, c("Outcome", "Log-rank \u03c7\u00b2", "p-value")]
}))
emit("Full 0\u201312 month log-rank test (note: mixes untreated + treated periods for Late group)",
     kable(full_lr_tbl, format = "pipe", align = "lrl", row.names = FALSE))

# =============================================================================
# JOURNAL-STYLE FIGURE CAPTION
# =============================================================================
n_full <- length(full_ids)
n_hdp  <- length(hdp_ids)

caption <- paste0(
  "\n",
  strrep("=", 80), "\n",
  " FIGURE CAPTION\n",
  strrep("=", 80), "\n\n",

  "Figure. Delivery-anchored Kaplan-Meier curves for postpartum weight loss\n",
  "and blood pressure improvement by GLP-1 receptor agonist initiation timing.\n\n",

  "Cumulative incidence of each outcome is shown from the time of delivery\n",
  "(day 0) through 12 months postpartum. Patients were stratified by GLP-1\n",
  "initiation timing: Early (< 6 months postpartum; orange) and Late\n",
  "(\u2265 6 months postpartum; blue). Panels A\u2013C display weight outcomes\n",
  "in the full analytic cohort (n = ", n_full, "): (A) \u226510% total body\n",
  "weight loss, (B) \u226520% total body weight loss, and (C) return to\n",
  "pre-pregnancy weight. Panels D\u2013F display blood pressure outcomes\n",
  "restricted to patients with hypertensive disorders of pregnancy (HDP;\n",
  "n = ", n_hdp, "): (D) \u22655 mmHg systolic blood pressure (SBP) decline,\n",
  "(E) \u226510 mmHg SBP decline, and (F) \u22655 mmHg diastolic blood pressure\n",
  "(DBP) decline. For all outcomes, baseline was anchored to the peripartum\n",
  "period (weight: earliest postpartum measurement; blood pressure: single\n",
  "value within \u00b12 days of delivery). Blood pressure event ascertainment\n",
  "was initiated after a 14-day post-delivery blanking period to exclude\n",
  "transient delivery-admission readings. The vertical dashed line at\n",
  "month 6 denotes the point at which Late-initiating patients began GLP-1\n",
  "therapy; prior to this timepoint, the Late group represents an untreated\n",
  "natural-history comparator. Curves are truncated where the number at risk\n",
  "in either stratum falls below ", N_AT_RISK_MIN, ". Shaded bands indicate\n",
  "95% confidence intervals. Between-group differences were assessed by the\n",
  "log-rank test; p-values are displayed within each panel.\n",
  "Abbreviations: GLP-1RA, glucagon-like peptide-1 receptor agonist;\n",
  "HDP, hypertensive disorders of pregnancy; SBP, systolic blood pressure;\n",
  "DBP, diastolic blood pressure.\n",
  strrep("=", 80), "\n"
)
cat(caption)

# =============================================================================
# WRITE MARKDOWN RESULTS FILE
# =============================================================================
md_out  <- gsub(">=", "\u2265", .md_lines, fixed = TRUE)
md_path <- file.path(md_dir, "figure_km_delivery_results.md")
writeLines(md_out, md_path)

# =============================================================================
# COMPLETION SUMMARY
# =============================================================================
cat(strrep("=", 80), "\n")
cat(" OUTPUT SUMMARY\n")
cat(strrep("=", 80), "\n")
cat("\nFigures saved to:\n  ", fig_dir, "\n\n")
cat("  Individual panels (PNG, 600 dpi):\n")
cat("    Figure2_A_wt10pct.png\n")
cat("    Figure2_B_wt20pct.png\n")
cat("    Figure2_C_prepreg.png\n")
cat("    Figure3_D_sbp5.png\n")
cat("    Figure3_E_sbp10.png\n")
cat("    Figure3_F_dbp5.png\n\n")
cat("  Composite figures (PNG 600 dpi + PDF):\n")
cat("    Figure2_wt_composite.png / .pdf   (panels A\u2013C)\n")
cat("    Figure3_bp_composite.png / .pdf   (panels D\u2013F)\n")
cat("    Figure_combined_km.png / .pdf     (A\u2013C top row, D\u2013F bottom row)\n\n")
cat("Markdown results table:\n  ", md_path, "\n")
cat(strrep("=", 80), "\n")