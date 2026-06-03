# =============================================================================
# postpartum-glp1: KM Curves v2 — DELIVERY-ANCHORED (PI revision)
# -----------------------------------------------------------------------------
# Time origin = DELIVERY (day 0). Both groups plotted over a common 0-18 month
# postpartum window. During months 0-6, Late initiators (>= 6 mo) are UNTREATED
# and serve as a natural-history comparison; a dashed reference line at 6 months
# marks where the Late group transitions onto GLP-1.
#
# WHY A REBUILD: the drug-anchored tte_datasets.rds starts the Late group's clock
# at their month-6+ drug initiation and therefore contains no events from their
# untreated months 0-6. To capture the natural-history window, time-to-event is
# rebuilt here from vitals_long using a DELIVERY-ANCHORED baseline = each
# patient's EARLIEST postpartum measurement (closest to delivery).
#
# Outputs (cumulative incidence, rising):
#   Figure 2 (delivery): A1/A2/A3 weight  — full cohort
#   Figure 3 (delivery): B1/B2/B3 BP      — HDP subgroup
# Plus knitr tables: median TTE, stratified landmark CI (3/6/12/18 mo),
#   and a 6-MONTH NATURAL-HISTORY comparison (Early treated vs Late untreated).
#
# 600 dpi. Color-blind-safe palette: Early #E69F00, Late #0072B2.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(survival)
  library(survminer)
  library(ggplot2)
  library(knitr)
})

# ----------------------------- PARAMETERS ------------------------------------
DAYS_PER_MONTH <- 30.44
FOLLOWUP_CAP   <- round(18 * DAYS_PER_MONTH)   # 18 months in days (~548)
XCAP_MONTHS    <- 18
XBREAK_MONTHS  <- 3
LATE_START_MO  <- 6        # month where Late group begins GLP-1
# BP baseline = a SINGLE value on the delivery date (within BP_BASELINE_WINDOW
# days of day 0). Event ascertainment then starts only AFTER a blanking period
# (BP_EVENT_START_DAY), so the many readings during the delivery admission cannot
# trigger an immediate "drop" at time 0. Per PI: the next meaningful BP is the
# 2-6 week postpartum visit.
BP_BASELINE_WINDOW <- 2     # +/- days around delivery for the single baseline BP
BP_EVENT_START_DAY <- 14    # blanking period: first event-eligible BP at >= 2 wk pp
# -----------------------------------------------------------------------------

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

analysis_df <- readRDS(file.path(data_dir, "analysis_df.rds"))
vitals_long <- readRDS(file.path(data_dir, "vitals_long.rds"))
cat("Loaded analysis_df (", nrow(analysis_df), ") and vitals_long (",
    nrow(vitals_long), " rows )\n", sep = "")

# --- HDP subgroup (same definition as main analysis) ------------------------
analysis_df <- analysis_df %>%
  mutate(bp_stage2_baseline =
           (!is.na(sbp_baseline_combined) & sbp_baseline_combined >= 140) |
           (!is.na(dbp_baseline_combined) & dbp_baseline_combined >= 90),
         hdp_cohort = (preg_htn_any == TRUE) | bp_stage2_baseline)

full_ids <- analysis_df$CURR_CLINIC
hdp_ids  <- analysis_df %>% filter(hdp_cohort) %>% pull(CURR_CLINIC)
cat("Full cohort:", length(full_ids), " | HDP subgroup:", length(hdp_ids), "\n\n")

# =============================================================================
# BASELINES (delivery-anchored)
# =============================================================================
# Earliest postpartum measurement per patient for a given vital (used for WEIGHT)
earliest_pp_baseline <- function(vital_name) {
  vitals_long %>%
    filter(vital == vital_name, days_from_delivery >= 0, !is.na(value)) %>%
    group_by(CURR_CLINIC) %>%
    slice_min(days_from_delivery, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    transmute(CURR_CLINIC, baseline = value, baseline_day = days_from_delivery)
}

# Delivery-date BP baseline (used for BLOOD PRESSURE): a SINGLE value on (or
# closest to) the delivery date, within BP_BASELINE_WINDOW days. Deliberately
# narrow so it captures the peripartum value, not an already-normalized later
# reading. Multiple same-admission readings are handled by the blanking period
# in build_tte_delivery (events only counted from BP_EVENT_START_DAY onward).
delivery_date_bp_baseline <- function(vital_name) {
  vitals_long %>%
    filter(vital == vital_name, !is.na(value),
           abs(days_from_delivery) <= BP_BASELINE_WINDOW) %>%
    group_by(CURR_CLINIC) %>%
    slice_min(abs(days_from_delivery), n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    transmute(CURR_CLINIC, baseline = value, baseline_day = days_from_delivery)
}

# Pre-pregnancy weight (fixed reference for A3)
prepreg_baseline_df <- analysis_df %>%
  transmute(CURR_CLINIC,
            baseline = PREGRAVID_BMI * (height_cm / 100)^2,
            baseline_day = NA_real_) %>%
  filter(!is.na(baseline))

wt_base  <- earliest_pp_baseline("weight_kg")        # WEIGHT: earliest postpartum
sbp_base <- delivery_date_bp_baseline("sbp")          # BP: single delivery-date value
dbp_base <- delivery_date_bp_baseline("dbp")

# Report baseline-day distribution (how close to delivery the anchors are)
bl_report <- wt_base %>%
  inner_join(analysis_df %>% select(CURR_CLINIC, glp1_timing_2cat), by = "CURR_CLINIC") %>%
  group_by(glp1_timing_2cat) %>%
  summarise(n = n(),
            `Baseline day, median (IQR)` = sprintf("%.0f (%.0f-%.0f)",
              median(baseline_day), quantile(baseline_day, .25), quantile(baseline_day, .75)),
            .groups = "drop") %>%
  rename(Stratum = glp1_timing_2cat)
cat("## Weight baseline timing (days from delivery to earliest measurement)\n\n")
cat(kable(bl_report, format = "pipe", align = "lrl"), sep = "\n")
cat("\n\n")

# BP delivery-baseline coverage: confirm the single baseline sits on/near delivery
bp_report <- sbp_base %>%
  mutate(source = case_when(
           baseline_day == 0 ~ "delivery day (day 0)",
           baseline_day <  0 ~ "1-2 d before delivery",
           TRUE              ~ "1-2 d after delivery")) %>%
  group_by(source) %>%
  summarise(n = n(), .groups = "drop") %>%
  rename(`Baseline source` = source)
cat("## SBP delivery-date baseline coverage (single value per patient)\n\n")
cat(kable(bp_report, format = "pipe", align = "lr"), sep = "\n")
cat(sprintf("\nSBP delivery baseline (within +/-%d d): %d patients; %d HDP patients without one.\n",
            BP_BASELINE_WINDOW, nrow(sbp_base),
            length(setdiff(hdp_ids, sbp_base$CURR_CLINIC))))
cat(sprintf("Event ascertainment begins at day %d (%.1f weeks) postpartum (blanking the delivery admission).\n",
            BP_EVENT_START_DAY, BP_EVENT_START_DAY / 7))
cat("\n\n")

# =============================================================================
# DELIVERY-ANCHORED TTE BUILDER
# =============================================================================
build_tte_delivery <- function(vital_name, baseline_df, event_fn, cohort_ids,
                               cap = FOLLOWUP_CAP, event_start_day = 0) {
  vl <- vitals_long %>%
    filter(vital == vital_name, days_from_delivery >= event_start_day,
           days_from_delivery <= cap, !is.na(value),
           CURR_CLINIC %in% cohort_ids) %>%
    inner_join(baseline_df, by = "CURR_CLINIC") %>%
    mutate(is_event = event_fn(value, baseline))

  vl %>%
    group_by(CURR_CLINIC) %>%
    summarise(last_day = max(days_from_delivery),
              first_event_day = if (any(is_event)) min(days_from_delivery[is_event]) else NA_real_,
              .groups = "drop") %>%
    mutate(event = as.integer(!is.na(first_event_day)),
           tte_days = pmin(ifelse(event == 1, first_event_day, last_day), cap),
           tte_days = ifelse(tte_days <= 0, 0.5, tte_days),
           tte_months = tte_days / DAYS_PER_MONTH) %>%
    inner_join(analysis_df %>% select(CURR_CLINIC, glp1_timing_2cat),
               by = "CURR_CLINIC") %>%
    mutate(glp1_timing_2cat = factor(glp1_timing_2cat,
             levels = c("Early (< 6 months)", "Late (>= 6 months)")))
}

# --- Outcome configuration ---
cfg <- list(
  A1 = list(vital="weight_kg", base=wt_base,            fn=function(v,b) v <= b*0.90, label="A1: >=10% weight loss",    ids=full_ids, title="A. >=10% weight loss",     es=0),
  A2 = list(vital="weight_kg", base=wt_base,            fn=function(v,b) v <= b*0.80, label="A2: >=20% weight loss",    ids=full_ids, title="B. >=20% weight loss",     es=0),
  A3 = list(vital="weight_kg", base=prepreg_baseline_df,fn=function(v,b) v <= b,      label="A3: Pre-pregnancy weight", ids=full_ids, title="C. Pre-pregnancy weight",  es=0),
  B1 = list(vital="sbp",       base=sbp_base,           fn=function(v,b) (b-v) >= 5,  label="B1: >=5 mmHg SBP decline", ids=hdp_ids,  title="A. >=5 mmHg SBP decline", es=BP_EVENT_START_DAY),
  B2 = list(vital="sbp",       base=sbp_base,           fn=function(v,b) (b-v) >= 10, label="B2: >=10 mmHg SBP decline",ids=hdp_ids,  title="B. >=10 mmHg SBP decline",es=BP_EVENT_START_DAY),
  B3 = list(vital="dbp",       base=dbp_base,           fn=function(v,b) (b-v) >= 5,  label="B3: >=5 mmHg DBP decline", ids=hdp_ids,  title="C. >=5 mmHg DBP decline", es=BP_EVENT_START_DAY)
)

cat("Building delivery-anchored TTE datasets...\n")
tte_dlv <- lapply(cfg, function(o)
  build_tte_delivery(o$vital, o$base, o$fn, o$ids, event_start_day = o$es))
names(tte_dlv) <- names(cfg)

# =============================================================================
# KM PLOT (cumulative incidence, delivery-anchored, 6-month reference line)
# =============================================================================
pal_strata  <- c("#E69F00", "#0072B2")
legend_labs <- c("Early (< 6 mo)", "Late (>= 6 mo)")
km_theme <- theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 13),
        panel.grid.minor = element_blank())

make_km_strat <- function(df, title_txt, ylab_txt = "Cumulative incidence",
                          fun_type = "event", pval_y = 0.92) {
  fit <- surv_fit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  gg <- ggsurvplot(
    fit, data = df,
    fun = fun_type, conf.int = TRUE, conf.int.alpha = 0.12,
    pval = TRUE, pval.size = 4, pval.coord = c(0.3, pval_y),
    risk.table = TRUE, risk.table.height = 0.26,
    risk.table.title = "Number at risk", risk.table.fontsize = 3.2,
    tables.theme = theme_cleantable(),
    palette = pal_strata,
    legend.title = "GLP-1 timing", legend.labs = legend_labs, legend = "top",
    xlab = "Months since delivery", ylab = ylab_txt, title = title_txt,
    xlim = c(0, XCAP_MONTHS), break.time.by = XBREAK_MONTHS,
    ggtheme = km_theme, censor.size = 2
  )
  # 6-month reference line: Late group transitions onto GLP-1
  gg$plot <- gg$plot +
    geom_vline(xintercept = LATE_START_MO, linetype = "dashed",
               color = "#444444", linewidth = 0.5) +
    annotate("text", x = LATE_START_MO + 0.2, y = 0.5,
             label = "Late group begins GLP-1", angle = 90,
             vjust = -0.4, size = 2.7, color = "#444444")
  gg
}

save_km <- function(p, fname, w = 6.5, h = 6.4, dpi = 600) {
  png(file.path(fig_dir, fname), width = w, height = h, units = "in", res = dpi)
  print(p, newpage = FALSE)
  dev.off()
}

cat("Building KM panels (weight)...\n")
p_A1 <- make_km_strat(tte_dlv$A1, cfg$A1$title)
p_A2 <- make_km_strat(tte_dlv$A2, cfg$A2$title)
p_A3 <- make_km_strat(tte_dlv$A3, cfg$A3$title)

cat("Building KM panels (BP, falling survival shape)...\n")
p_B1 <- make_km_strat(tte_dlv$B1, cfg$B1$title,
                      ylab_txt = "Proportion without BP improvement",
                      fun_type = NULL, pval_y = 0.1)
p_B2 <- make_km_strat(tte_dlv$B2, cfg$B2$title,
                      ylab_txt = "Proportion without BP improvement",
                      fun_type = NULL, pval_y = 0.1)
p_B3 <- make_km_strat(tte_dlv$B3, cfg$B3$title,
                      ylab_txt = "Proportion without BP improvement",
                      fun_type = NULL, pval_y = 0.1)

save_km(p_A1, "Figure2_delivery_A1_10pct.png")
save_km(p_A2, "Figure2_delivery_A2_20pct.png")
save_km(p_A3, "Figure2_delivery_A3_prepreg.png")
save_km(p_B1, "Figure3_delivery_B1_sbp5.png")
save_km(p_B2, "Figure3_delivery_B2_sbp10.png")
save_km(p_B3, "Figure3_delivery_B3_dbp5.png")

# Composites
fig2 <- arrange_ggsurvplots(list(p_A1, p_A2, p_A3), ncol = 3, nrow = 1, print = FALSE,
  title = "Figure 2. Delivery-anchored time-to-event, weight outcomes (Late group untreated until month 6)")
ggsave(file.path(fig_dir, "Figure2_delivery_km_weight_composite.png"), fig2,
       width = 19, height = 7.0, dpi = 600, bg = "white")
ggsave(file.path(fig_dir, "Figure2_delivery_km_weight_composite.pdf"), fig2,
       width = 19, height = 7.0, bg = "white")

fig3 <- arrange_ggsurvplots(list(p_B1, p_B2, p_B3), ncol = 3, nrow = 1, print = FALSE,
  title = "Figure 3. Delivery-anchored time-to-event, BP outcomes, HDP subgroup (Late group untreated until month 6)")
ggsave(file.path(fig_dir, "Figure3_delivery_km_bp_composite.png"), fig3,
       width = 19, height = 7.0, dpi = 600, bg = "white")
ggsave(file.path(fig_dir, "Figure3_delivery_km_bp_composite.pdf"), fig3,
       width = 19, height = 7.0, bg = "white")

# =============================================================================
# SUMMARY TABLES (knitr::kable)
# =============================================================================
# 1. Median TTE by stratum
extract_median <- function(df, label) {
  f_all <- survfit(Surv(tte_months, event) ~ 1, data = df)
  f_str <- survfit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  m_all <- summary(f_all)$table["median"]
  m_str <- summary(f_str)$table[, "median"]
  fmt <- function(x) ifelse(is.na(x), "NR", sprintf("%.1f", x))
  data.frame(Outcome = label, N = nrow(df), Events = sum(df$event),
             `Overall (mo)` = fmt(m_all), `Early (mo)` = fmt(m_str[1]),
             `Late (mo)` = fmt(m_str[2]),
             check.names = FALSE, stringsAsFactors = FALSE)
}
median_tbl <- do.call(rbind, lapply(names(cfg), function(k)
  extract_median(tte_dlv[[k]], cfg[[k]]$label)))
cat("\n## Median time-to-event by stratum (delivery-anchored, months)\n\n")
cat(kable(median_tbl, format = "pipe", align = "lrrlll"), sep = "\n")

# 2. Stratified landmark cumulative incidence (3/6/12/18 mo)
extract_ci_strat <- function(df, label, times = c(3, 6, 12, 18)) {
  max_fu <- max(df$tte_months, na.rm = TRUE)
  times  <- times[times <= max_fu]
  if (length(times) == 0) return(NULL)
  fit <- survfit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  s   <- summary(fit, times = times)
  data.frame(
    Outcome = label,
    Group   = sub("glp1_timing_2cat=", "", as.character(s$strata)),
    Month   = s$time,
    `Cum. incidence (%)` = sprintf("%.1f", (1 - s$surv) * 100),
    `95% CI` = sprintf("%.1f-%.1f", (1 - s$upper) * 100, (1 - s$lower) * 100),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}
ci_tbl <- do.call(rbind, lapply(names(cfg), function(k)
  extract_ci_strat(tte_dlv[[k]], cfg[[k]]$label)))
cat("\n\n## Stratified cumulative incidence at landmarks (delivery-anchored)\n\n")
cat(kable(ci_tbl, format = "pipe", align = "llrll", row.names = FALSE), sep = "\n")

# 3. 6-MONTH NATURAL-HISTORY COMPARISON (Early treated vs Late untreated)
#    Cumulative incidence at 6 mo by group + log-rank restricted to 0-6 months.
ci6_by_group <- function(df) {
  fit <- survfit(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  s   <- summary(fit, times = 6)
  grp <- sub("glp1_timing_2cat=", "", as.character(s$strata))
  ci  <- sprintf("%.1f (%.1f-%.1f)", (1 - s$surv) * 100,
                 (1 - s$upper) * 100, (1 - s$lower) * 100)
  out <- setNames(ci, grp)
  # robust accessor: returns "-" if a stratum has no 6-mo estimate
  function(g) if (g %in% names(out)) out[[g]] else "-"
}
logrank6 <- function(df) {
  d6 <- df %>% mutate(event6 = ifelse(tte_months <= 6 & event == 1, 1L, 0L),
                      tte6   = pmin(tte_months, 6))
  lr <- survdiff(Surv(tte6, event6) ~ glp1_timing_2cat, data = d6)
  p  <- pchisq(lr$chisq, df = length(lr$n) - 1, lower.tail = FALSE)
  ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
}
nathist_tbl <- do.call(rbind, lapply(names(cfg), function(k) {
  df  <- tte_dlv[[k]]
  ci6 <- ci6_by_group(df)
  data.frame(
    Outcome = cfg[[k]]$label,
    `Early @6mo (treated), % (95% CI)` = ci6("Early (< 6 months)"),
    `Late @6mo (untreated), % (95% CI)` = ci6("Late (>= 6 months)"),
    `Log-rank p (0-6 mo)` = logrank6(df),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}))
cat("\n\n## 6-month natural-history comparison (Early treated vs Late UNTREATED)\n\n")
cat(kable(nathist_tbl, format = "pipe", align = "llll", row.names = FALSE), sep = "\n")

# 4. Full 0-18 mo log-rank
logrank_full <- function(df) {
  lr <- survdiff(Surv(tte_months, event) ~ glp1_timing_2cat, data = df)
  p  <- pchisq(lr$chisq, df = length(lr$n) - 1, lower.tail = FALSE)
  data.frame(`Log-rank chi-sq` = round(lr$chisq, 2),
             `p-value` = ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)),
             check.names = FALSE)
}
full_lr_tbl <- do.call(rbind, lapply(names(cfg), function(k) {
  r <- logrank_full(tte_dlv[[k]]); r$Outcome <- cfg[[k]]$label
  r[, c("Outcome", "Log-rank chi-sq", "p-value")]
}))
cat("\n\n## Full 0-18 month log-rank (mixes untreated + treated periods for Late)\n\n")
cat(kable(full_lr_tbl, format = "pipe", align = "lrl", row.names = FALSE), sep = "\n")

cat("\n\n================================================================\n")
cat(" DELIVERY-ANCHORED KM SAVED (600 dpi)\n")
cat("================================================================\n")
cat("  Figure2_delivery_km_weight_composite.png / .pdf\n")
cat("  Figure3_delivery_km_bp_composite.png / .pdf\n")
cat("  + 6 individual panels (Figure2_delivery_*, Figure3_delivery_*)\n")
cat("Dashed line at month 6 = Late group begins GLP-1 (untreated control before).\n")
cat("Location:", fig_dir, "\n")