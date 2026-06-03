# =============================================================================
# postpartum-glp1: Figure 4 — Forest Plot, Cox PH Hazard Ratios (drug-anchored)
# -----------------------------------------------------------------------------
# THE centerpiece figure. All 6 outcomes (A1-A3 weight, B1-B3 BP) in one forest
# plot. Each row shows BOTH the unadjusted HR (hollow circle) and the adjusted
# HR (solid square) on a single CI axis. Reference = Early initiators (< 6 mo);
# HR is for Late vs Early. Significant HRs (p < 0.05) are bold + starred (*).
#
# Uses tte_datasets.rds from build_table3_revised.R. Re-fits the same Cox
# models behind Tables 3 & 4 to extract HR / CI / p.
#
# Package: forestploter (clean modern tabular forest layout).
# Output: ~180mm composite PNG/PDF at 600 dpi (single-column ~90mm also saved).
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(survival)
  library(forestploter)
  library(grid)
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
cat("Loaded tte_datasets.rds (anchor =", tte$anchor, ")\n\n")

# Covariate sets (same as Table 3 / Table 4)
cov_weight <- "current_age + bmi_baseline_combined + parity_cat + delivery_mode_simple + ckm_t2dm + preg_gdm + glp1_agent_simple"
cov_bp     <- "current_age + bmi_baseline_combined + preg_preec_any_spectrum + ckm_t2dm + preg_gdm + glp1_agent_simple + bp_med_any"

LATE_COEF <- "glp1_timing_2catLate (>= 6 months)"

# =============================================================================
# EXTRACT HR / CI / p FOR EACH OUTCOME (unadjusted + adjusted)
# =============================================================================
fit_one <- function(df, cov_rhs) {
  df <- df %>% mutate(glp1_timing_2cat = factor(glp1_timing_2cat,
                       levels = c("Early (< 6 months)", "Late (>= 6 months)")))

  # Unadjusted
  un <- coxph(Surv(tte, event) ~ glp1_timing_2cat, data = df)
  un_ci <- exp(confint(un))
  un_hr <- exp(coef(un))[1]
  un_p  <- summary(un)$coefficients[1, "Pr(>|z|)"]

  # Adjusted
  f  <- as.formula(paste("Surv(tte, event) ~ glp1_timing_2cat +", cov_rhs))
  ad <- tryCatch(coxph(f, data = df), error = function(e) NULL)
  if (is.null(ad)) {
    ad_hr <- NA; ad_lcl <- NA; ad_ucl <- NA; ad_p <- NA
  } else {
    ad_ci <- exp(confint(ad))
    ad_hr <- exp(coef(ad))[LATE_COEF]
    ad_lcl <- ad_ci[LATE_COEF, 1]; ad_ucl <- ad_ci[LATE_COEF, 2]
    ad_p  <- summary(ad)$coefficients[LATE_COEF, "Pr(>|z|)"]
  }

  data.frame(
    n = nrow(df), events = sum(df$event),
    un_hr = un_hr, un_lcl = un_ci[1,1], un_ucl = un_ci[1,2], un_p = un_p,
    ad_hr = ad_hr, ad_lcl = ad_lcl, ad_ucl = ad_ucl, ad_p = ad_p
  )
}

outcomes <- list(
  list(label = ">=10% weight loss",      df = tte$A1, cov = cov_weight),
  list(label = ">=20% weight loss",      df = tte$A2, cov = cov_weight),
  list(label = "Pre-pregnancy weight",   df = tte$A3, cov = cov_weight),
  list(label = ">=5 mmHg SBP decline",   df = tte$B1, cov = cov_bp),
  list(label = ">=10 mmHg SBP decline",  df = tte$B2, cov = cov_bp),
  list(label = ">=5 mmHg DBP decline",   df = tte$B3, cov = cov_bp)
)

res <- do.call(rbind, lapply(outcomes, function(o) {
  r <- fit_one(o$df, o$cov)
  r$Outcome <- o$label
  r
}))
res <- res[, c("Outcome", setdiff(names(res), "Outcome"))]

cat("--- Extracted hazard ratios (Late vs Early) ---\n")
print(res[, c("Outcome","events","n","un_hr","un_p","ad_hr","ad_p")], row.names = FALSE)
cat("\n")

# =============================================================================
# FORMAT TEXT COLUMNS — ADJUSTED ONLY (unadj nearly identical, dropped).
# HR text bold + "*" when p < 0.05; separate exact p-value column (2 dp).
# =============================================================================
fmt_hr_txt <- function(hr, lcl, ucl, p) {
  if (is.na(hr)) return("-")
  star <- ifelse(!is.na(p) & p < 0.05, "*", "")
  sprintf("%.2f (%.2f-%.2f)%s", hr, lcl, ucl, star)
}

# Exact p to 2 decimals; show <0.01 rather than a misleading 0.00
fmt_p_exact <- function(p) {
  if (is.na(p)) return("-")
  if (p < 0.005) return("<0.01")
  sprintf("%.2f", p)
}

res <- res %>%
  mutate(
    `Events / N`            = sprintf("%d / %d", events, n),
    `Adjusted HR (95%% CI)` = mapply(fmt_hr_txt, ad_hr, ad_lcl, ad_ucl, ad_p),
    `p-value`               = vapply(ad_p, fmt_p_exact, character(1))
  )

# Significance flag (adjusted) for bold styling
sig_adj <- which(!is.na(res$ad_p) & res$ad_p < 0.05)

# =============================================================================
# BUILD FOREST PLOT TABLE — single (adjusted) CI
# =============================================================================
plot_df <- data.frame(
  Outcome      = res$Outcome,
  `Events / N` = res$`Events / N`,
  ` `          = paste(rep(" ", 22), collapse = " "),  # CI drawing column
  `Adjusted HR (95% CI)` = res$`Adjusted HR (95%% CI)`,
  `p-value`    = res$`p-value`,
  check.names = FALSE, stringsAsFactors = FALSE
)

# Single estimate vectors (adjusted)
est_v   <- res$ad_hr
lower_v <- res$ad_lcl
upper_v <- res$ad_ucl

# Theme: solid square (adjusted); color-blind safe blue
tm <- forest_theme(
  base_size   = 10,
  ci_pch      = 15,                        # solid square
  ci_col      = "#0072B2",
  ci_fill     = "#0072B2",
  ci_alpha    = 1,
  ci_lty      = 1,
  ci_lwd      = 1.8,
  ci_Theight  = 0.2,
  refline_gp  = gpar(lwd = 1, lty = "dashed", col = "#444444"),
  core = list(bg_params = list(fill = c("#FFFFFF", "#F6F6F6")))  # subtle row stripe
)

ci_col_index <- which(names(plot_df) == " ")

p <- forest(
  plot_df,
  est       = est_v,
  lower     = lower_v,
  upper     = upper_v,
  ci_column = ci_col_index,
  ref_line  = 1,
  xlim      = c(0.2, 3),
  ticks_at  = c(0.25, 0.5, 1, 2, 3),
  xlab      = "Hazard ratio (Late vs Early initiators)",
  theme     = tm
)

# =============================================================================
# BOLD SIGNIFICANT CELLS (adjusted p < 0.05)
# Columns: 1 Outcome, 2 Events/N, 3 CI, 4 Adjusted HR, 5 p-value
# =============================================================================
if (length(sig_adj) > 0) {
  p <- edit_plot(p, row = sig_adj, col = 4, gp = gpar(fontface = "bold"))
  p <- edit_plot(p, row = sig_adj, col = 5, gp = gpar(fontface = "bold"))
}

# Header rule for a clean clinical look
p <- add_border(p, part = "header", row = 1, where = "bottom",
                gp = gpar(lwd = 1.2))

# =============================================================================
# SAVE — 600 dpi. forestploter objects are gtables, NOT ggplots, so they must
# be saved via a graphics device + plot(p) (per package docs), not ggsave().
# get_wh() returns the correct natural width/height for the device.
# =============================================================================
wh <- get_wh(p, unit = "in")
cat(sprintf("Forest plot natural size: %.1f x %.1f inches\n", wh[1], wh[2]))

png(file.path(fig_dir, "Figure4_forest_cox.png"),
    width = wh[1], height = wh[2], units = "in", res = 600, bg = "white")
plot(p)
dev.off()

pdf(file.path(fig_dir, "Figure4_forest_cox.pdf"),
    width = wh[1], height = wh[2], bg = "white")
plot(p)
dev.off()

cat("\n================================================================\n")
cat(" FIGURE 4 SAVED (600 dpi)\n")
cat("================================================================\n")
cat("  Figure4_forest_cox.png / .pdf\n")
cat("Solid blue square = adjusted HR (95% CI). Reference: Early initiators (< 6 mo).\n")
cat("Bold + * marks adjusted p < 0.05. Exact adjusted p shown to 2 dp.\n")
cat("(Unadjusted HRs were near-identical to adjusted, so dropped from the plot.)\n")
cat("Location:", fig_dir, "\n")