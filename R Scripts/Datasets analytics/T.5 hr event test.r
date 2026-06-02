library(dplyr)
library(survival)

# 1) Basic structure
required_cols <- c("CURR_CLINIC", "glp1_timing_cat", "glp1_timing_2cat",
                   "wt_event", "wt_tte", "wt_fu", "glp1_index_date",
                   "days_pp_to_glp1")

setdiff(required_cols, names(analysis_df))

# 2) One row per patient
c(
  n_rows = nrow(analysis_df),
  n_patients = dplyr::n_distinct(analysis_df$CURR_CLINIC)
)

# 3) Weight event completeness
analysis_df %>%
  summarise(
    n = n(),
    wt_event_na = sum(is.na(wt_event)),
    wt_tte_na   = sum(is.na(wt_tte)),
    wt_fu_na    = sum(is.na(wt_fu)),
    wt_event_1  = sum(wt_event == TRUE, na.rm = TRUE),
    wt_event_0  = sum(wt_event == FALSE, na.rm = TRUE)
  )

# 4) Build the survival time correctly for Cox
analysis_df <- analysis_df %>%
  mutate(
    wt_time = if_else(wt_event, wt_tte, wt_fu),
    wt_time_ok = !is.na(wt_time) & wt_time >= 0
  )

analysis_df %>%
  summarise(
    missing_wt_time = sum(is.na(wt_time)),
    negative_wt_time = sum(wt_time < 0, na.rm = TRUE),
    ok_wt_time = sum(wt_time_ok, na.rm = TRUE)
  )

# 5) Check follow-up / event relationship
analysis_df %>%
  filter(wt_event == TRUE) %>%
  summarise(
    any_tte_na = any(is.na(wt_tte)),
    any_fu_na  = any(is.na(wt_fu)),
    min_tte = min(wt_tte, na.rm = TRUE),
    max_tte = max(wt_tte, na.rm = TRUE)
  )

# 6) Event rate by timing group
analysis_df %>%
  group_by(glp1_timing_2cat) %>%
  summarise(
    n = n(),
    events = sum(wt_event == TRUE, na.rm = TRUE),
    event_rate = mean(wt_event == TRUE, na.rm = TRUE),
    median_fu = median(wt_fu, na.rm = TRUE)
  )

# 7) A simple Cox model skeleton
fit_wt <- coxph(Surv(wt_time, wt_event) ~ glp1_timing_2cat, data = analysis_df)
summary(fit_wt)

# 8) PH test
cox.zph(fit_wt)

names(analysis_df)
table(analysis_df$glp1_timing_2cat, useNA = "ifany")
summary(analysis_df$wt_time)