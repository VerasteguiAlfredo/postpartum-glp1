# =============================================================================
# postpartum-glp1: Figure 5 — Swimmer Plot (patient timelines)
# -----------------------------------------------------------------------------
# Patient-level timelines, stratified Early vs Late, sorted by time-to-event.
# Marks: delivery, GLP-1 start, event (if achieved), censoring.
#
# Parameterized: change OUTCOME below to swap which event is shown.
# Produces BOTH time axes:
#   - Delivery-anchored (day 0 = delivery; shows the pre-drug gap)
#   - Drug-anchored      (day 0 = GLP-1 start; matches survival models)
#
# Sample: ALL patients who had the event + a random sample of censored
# patients (balanced-ish across strata), targeting ~80 bars total.
#
# Uses tte_datasets.rds from build_table3_revised.R. Reconstructs postpartum
# timing as: postpartum_event_day = days_pp_to_glp1 + tte.
#
# 600 dpi.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(knitr)
})

# ----------------------------- PARAMETERS ------------------------------------
OUTCOME      <- "A1"     # one of: A1, A2, A3 (weight) | B1, B2, B3 (BP)
N_CENSORED   <- 40       # random censored patients to include (total, split by strata)
SEED         <- 42
# -----------------------------------------------------------------------------

outcome_labels <- c(
  A1 = ">=10% weight loss",
  A2 = ">=20% weight loss",
  A3 = "pre-pregnancy weight",
  B1 = ">=5 mmHg SBP decline",
  B2 = ">=10 mmHg SBP decline",
  B3 = ">=5 mmHg DBP decline"
)
event_label <- outcome_labels[[OUTCOME]]

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
df  <- tte[[OUTCOME]]
cat("Outcome:", OUTCOME, "(", event_label, ") — n =", nrow(df),
    ", events =", sum(df$event), "\n")

# =============================================================================
# 1. SAMPLE: all events + random censored
# =============================================================================
set.seed(SEED)

df <- df %>%
  mutate(glp1_timing_2cat = factor(glp1_timing_2cat,
          levels = c("Early (< 6 months)", "Late (>= 6 months)")))

events_df   <- df %>% filter(event == 1)
censored_df <- df %>% filter(event == 0)

# Sample censored proportionally to strata sizes, up to N_CENSORED
cens_sample <- censored_df %>%
  group_by(glp1_timing_2cat) %>%
  slice_sample(n = ceiling(N_CENSORED / 2)) %>%
  ungroup()

swim <- bind_rows(events_df, cens_sample) %>% distinct(CURR_CLINIC, .keep_all = TRUE)
cat("Swimmer sample:", nrow(swim), "patients (",
    sum(swim$event), "events +", sum(swim$event == 0), "censored )\n\n")

# =============================================================================
# 2. RECONSTRUCT TIMING ON BOTH AXES
# -----------------------------------------------------------------------------
# Drug-anchored: GLP-1 start = 0; bar 0 -> tte; delivery at -days_pp_to_glp1.
# Delivery-anchored: delivery = 0; GLP-1 at days_pp_to_glp1; bar end at
#   days_pp_to_glp1 + tte.
# =============================================================================
swim <- swim %>%
  mutate(
    # delivery-anchored (postpartum days)
    dlv_glp1   = days_pp_to_glp1,
    dlv_end    = days_pp_to_glp1 + tte,
    # drug-anchored
    drg_dlv    = -days_pp_to_glp1,   # delivery sits before drug start
    drg_glp1   = 0,
    drg_end    = tte,
    status     = if_else(event == 1, "Event", "Censored")
  )

# =============================================================================
# 3. ORDER BARS: within each stratum, sort by time-to-event (drug-anchored tte)
# =============================================================================
order_bars <- function(d, end_col) {
  d %>%
    arrange(glp1_timing_2cat, .data[[end_col]]) %>%
    group_by(glp1_timing_2cat) %>%
    mutate(y = row_number()) %>%
    ungroup() %>%
    # global y across strata with a gap between groups
    arrange(glp1_timing_2cat, y) %>%
    mutate(yglobal = row_number())
}

# =============================================================================
# 4. SWIMMER PLOT BUILDER
# =============================================================================
pal_status <- c("Event" = "#C0392B", "Censored" = "#7F8C8D")
seg_predrug <- "#D6D6D6"   # delivery -> GLP-1 (pre-drug)
seg_ondrug  <- "#0072B2"   # GLP-1 -> end (on-drug exposure)

make_swimmer <- function(d, x_dlv, x_glp1, x_end, axis_label, title_txt,
                         refline_at = NULL, refline_label = NULL,
                         show_delivery_point = FALSE) {
  d <- order_bars(d, x_end)

  # facet labels with counts
  strat_counts <- d %>% count(glp1_timing_2cat) %>%
    mutate(lab = sprintf("%s (n=%d)", glp1_timing_2cat, n))
  d <- d %>% left_join(strat_counts %>% select(glp1_timing_2cat, lab),
                       by = "glp1_timing_2cat")

  p <- ggplot(d, aes(y = yglobal)) +
    # on-drug segment (GLP-1 -> end)
    geom_segment(aes(x = .data[[x_glp1]], xend = .data[[x_end]],
                     yend = yglobal), color = seg_ondrug, linewidth = 1.4) +
    # pre-drug segment (delivery -> GLP-1)
    geom_segment(aes(x = .data[[x_dlv]],  xend = .data[[x_glp1]],
                     yend = yglobal), color = seg_predrug, linewidth = 1.4) +
    # GLP-1 start marker
    geom_point(aes(x = .data[[x_glp1]]), shape = 124, size = 2.6,
               color = "#222222")

  # optional delivery marker (useful in drug-anchored, where delivery is < 0)
  if (show_delivery_point) {
    p <- p + geom_point(aes(x = .data[[x_dlv]]), shape = 4, size = 1.8,
                        color = "#444444", stroke = 0.7)
  }

  p <- p +
    # event / censor end markers
    geom_point(aes(x = .data[[x_end]], color = status, shape = status),
               size = 2.2) +
    scale_color_manual(values = pal_status, name = NULL) +
    scale_shape_manual(values = c("Event" = 18, "Censored" = 124), name = NULL) +
    facet_grid(lab ~ ., scales = "free_y", space = "free_y", switch = "y") +
    labs(title = title_txt,
         subtitle = paste0("Event marked: ", event_label,
                           "  |  blue = on-drug, grey = pre-drug",
                           if (show_delivery_point) "; x = delivery" else ""),
         x = axis_label, y = NULL) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title       = element_text(face = "bold", size = 13),
      plot.subtitle    = element_text(size = 9, color = "#4D4D4D"),
      axis.text.y      = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      strip.text.y.left = element_text(angle = 0, face = "bold", size = 10),
      strip.placement  = "outside",
      legend.position  = "top"
    )

  if (!is.null(refline_at)) {
    p <- p + geom_vline(xintercept = refline_at, linetype = "dashed",
                        color = "#999999", linewidth = 0.4)
    if (!is.null(refline_label)) {
      p <- p + annotate("text", x = refline_at, y = Inf, label = refline_label,
                       vjust = 1.5, hjust = -0.05, size = 3, color = "#777777")
    }
  }
  p
}

# =============================================================================
# 5. BUILD BOTH AXES
# =============================================================================
cat("Building delivery-anchored swimmer...\n")
# Delivery-anchored: delivery IS day 0, so the bar starts at 0. Add an explicit
# zero column for the pre-drug segment origin. Reference line at 0 = delivery.
swim <- swim %>% mutate(dlv_start0 = 0)
p_dlv <- make_swimmer(
  swim,
  x_dlv = "dlv_start0", x_glp1 = "dlv_glp1", x_end = "dlv_end",
  axis_label = "Days since delivery",
  title_txt  = "Figure 5A. Patient timelines (delivery-anchored)",
  refline_at = 0, refline_label = "delivery",
  show_delivery_point = FALSE   # delivery == bar start, no separate marker needed
)

cat("Building drug-anchored swimmer...\n")
# Drug-anchored: GLP-1 start = 0 (reference line). Delivery sits at a negative
# x (drg_dlv); show it as an explicit 'x' marker.
p_drg <- make_swimmer(
  swim, x_dlv = "drg_dlv", x_glp1 = "drg_glp1", x_end = "drg_end",
  axis_label = "Days since GLP-1 initiation",
  title_txt  = "Figure 5B. Patient timelines (drug-anchored)",
  refline_at = 0, refline_label = "GLP-1 start",
  show_delivery_point = TRUE
)

# =============================================================================
# 6. SAVE (600 dpi)
# =============================================================================
nbar <- nrow(swim)
h_in <- max(6, nbar * 0.13)

ggsave(file.path(fig_dir, paste0("Figure5A_swimmer_delivery_", OUTCOME, ".png")),
       p_dlv, width = 9, height = h_in, dpi = 600, bg = "white", limitsize = FALSE)
ggsave(file.path(fig_dir, paste0("Figure5B_swimmer_drug_", OUTCOME, ".png")),
       p_drg, width = 9, height = h_in, dpi = 600, bg = "white", limitsize = FALSE)
ggsave(file.path(fig_dir, paste0("Figure5A_swimmer_delivery_", OUTCOME, ".pdf")),
       p_dlv, width = 9, height = h_in, bg = "white", limitsize = FALSE)
ggsave(file.path(fig_dir, paste0("Figure5B_swimmer_drug_", OUTCOME, ".pdf")),
       p_drg, width = 9, height = h_in, bg = "white", limitsize = FALSE)

cat("\n================================================================\n")
cat(" FIGURE 5 SAVED (600 dpi) — outcome:", OUTCOME, "(", event_label, ")\n")
cat("================================================================\n")
cat("  Figure5A_swimmer_delivery_", OUTCOME, ".png / .pdf\n", sep = "")
cat("  Figure5B_swimmer_drug_", OUTCOME, ".png / .pdf\n", sep = "")
cat("To swap outcomes, change OUTCOME at top (A1/A2/A3/B1/B2/B3) and re-run.\n")
cat("Location:", fig_dir, "\n")

# =============================================================================
# 7. CONSOLE SUMMARY — knitr::kable markdown output
# =============================================================================
DAYS_PER_MONTH <- 30.44

# --- Table 1: Sample composition (plotted vs full cohort) ---
full_n <- nrow(df)
comp_tbl <- swim %>%
  group_by(glp1_timing_2cat) %>%
  summarise(
    `Plotted (n)` = n(),
    Events        = sum(event),
    Censored      = sum(event == 0),
    `Event rate (%)` = sprintf("%.1f", mean(event) * 100),
    .groups = "drop"
  ) %>%
  rename(Stratum = glp1_timing_2cat) %>%
  bind_rows(
    tibble(
      Stratum = "Total (plotted / full cohort)",
      `Plotted (n)` = nrow(swim),
      Events        = sum(swim$event),
      Censored      = sum(swim$event == 0),
      `Event rate (%)` = sprintf("%.1f (full: %.1f)",
                                  mean(swim$event) * 100,
                                  mean(df$event) * 100)
    )
  )

cat("\n\n## Sample composition —", OUTCOME, "(", event_label, ")\n\n")
cat(kable(comp_tbl, format = "pipe", align = "lrrrr"), sep = "\n")
cat(sprintf("\nFull cohort: %d patients (%d events). Plotted: %d patients.\n",
            full_n, sum(df$event), nrow(swim)))

# --- Table 2: Timeline summary by stratum (months) ---
timeline_tbl <- swim %>%
  group_by(glp1_timing_2cat) %>%
  summarise(
    n = n(),
    `Delivery to GLP-1 (months)` = sprintf("%.1f (%.1f-%.1f)",
      median(days_pp_to_glp1 / DAYS_PER_MONTH),
      quantile(days_pp_to_glp1 / DAYS_PER_MONTH, 0.25),
      quantile(days_pp_to_glp1 / DAYS_PER_MONTH, 0.75)),
    `Time-to-event (months)` = sprintf("%.1f (%.1f-%.1f)",
      median(tte / DAYS_PER_MONTH),
      quantile(tte / DAYS_PER_MONTH, 0.25),
      quantile(tte / DAYS_PER_MONTH, 0.75)),
    `Total PP follow-up (months)` = sprintf("%.1f (%.1f-%.1f)",
      median(dlv_end / DAYS_PER_MONTH),
      quantile(dlv_end / DAYS_PER_MONTH, 0.25),
      quantile(dlv_end / DAYS_PER_MONTH, 0.75)),
    .groups = "drop"
  ) %>%
  rename(Stratum = glp1_timing_2cat)

cat("\n\n## Timeline summary by stratum — median (IQR), months\n\n")
cat(kable(timeline_tbl, format = "pipe", align = "lrlll"), sep = "\n")

# --- Table 3: Event vs censored timeline comparison ---
status_tbl <- swim %>%
  group_by(status) %>%
  summarise(
    n = n(),
    `Delivery to GLP-1 (months)` = sprintf("%.1f (%.1f-%.1f)",
      median(days_pp_to_glp1 / DAYS_PER_MONTH),
      quantile(days_pp_to_glp1 / DAYS_PER_MONTH, 0.25),
      quantile(days_pp_to_glp1 / DAYS_PER_MONTH, 0.75)),
    `Time on drug to endpoint (months)` = sprintf("%.1f (%.1f-%.1f)",
      median(tte / DAYS_PER_MONTH),
      quantile(tte / DAYS_PER_MONTH, 0.25),
      quantile(tte / DAYS_PER_MONTH, 0.75)),
    .groups = "drop"
  ) %>%
  rename(Status = status)

cat("\n\n## Event vs censored — timeline comparison (months)\n\n")
cat(kable(status_tbl, format = "pipe", align = "lrll"), sep = "\n")
cat("\n")