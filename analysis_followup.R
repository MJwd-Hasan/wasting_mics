#!/usr/bin/env Rscript

# Follow-up analysis for severe wasting in the MICS child dataset.
# Run from the repository root:
#   Rscript analysis_followup.R MICS-child-ISRC.dta outputs
#
# This pipeline uses the survey package for stratified, clustered, weighted
# estimation. It is a reproducible supplement to eda.ipynb, not a replacement
# for checking the source data dictionary and Stata survey specification.

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(survey)
  library(splines)
})

args <- commandArgs(trailingOnly = TRUE)
data_path <- if (length(args) >= 1) args[[1]] else "MICS-child-ISRC.dta"
out_dir <- if (length(args) >= 2) args[[2]] else "outputs"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

if (!file.exists(data_path)) {
  stop("Dataset not found: ", data_path,
       "\nPlace MICS-child-ISRC.dta in the repository root or pass its path.")
}

dat <- haven::read_dta(data_path) |> as.data.frame()
names(dat) <- tolower(names(dat))

required_design <- c("hh1", "strata", "chweight", "severe_wasting")
missing_design <- setdiff(required_design, names(dat))
if (length(missing_design)) {
  stop("Missing required design/outcome columns: ",
       paste(missing_design, collapse = ", "))
}

# Keep valid design/outcome observations. Never use outcome-derived WHZ
# categories as predictors.
dat <- dat |>
  filter(
    !is.na(hh1), !is.na(strata), !is.na(chweight),
    !is.na(severe_wasting), chweight > 0
  ) |>
  mutate(
    severe_wasting = as.numeric(severe_wasting),
    severe_wasting = ifelse(severe_wasting %in% c(0, 1),
                            severe_wasting, NA_real_)
  ) |>
  filter(!is.na(severe_wasting))

if (!all(dat$severe_wasting %in% c(0, 1))) {
  stop("severe_wasting must be coded 0/1 after cleaning; inspect source coding.")
}

# Stata reference: svyset hh1 [pweight=chweight], strata(strata),
# singleunit(centered). "adjust" is a transparent survey-package lonely-PSU
# handling choice; confirm exact equivalence against the project's Stata output.
options(survey.lonely.psu = "adjust")
des <- survey::svydesign(
  ids = ~hh1, strata = ~strata, weights = ~chweight,
  data = dat, nest = TRUE
)

write.csv(
  data.frame(
    n = nrow(dat),
    unweighted_cases = sum(dat$severe_wasting == 1),
    unweighted_prevalence_pct = mean(dat$severe_wasting) * 100,
    weighted_prevalence_pct =
      as.numeric(survey::svymean(~severe_wasting, des, na.rm = TRUE)[1]) * 100,
    psus = length(unique(dat$hh1)),
    strata = length(unique(dat$strata)),
    lonely_psu_option = getOption("survey.lonely.psu")
  ),
  file.path(out_dir, "sample_and_prevalence.csv"), row.names = FALSE
)

# Survey-weighted overall prevalence and design-based subgroup estimates.
group_vars <- intersect(
  c("female", "urban", "division", "wealth", "edu_level",
    "diarrhoea_2w", "cough_2w", "breathing_2w", "toilet_cat"),
  names(dat)
)
prev_rows <- list()
for (v in group_vars) {
  dsub <- des[!is.na(dat[[v]]), ]
  f <- as.formula(paste0("~factor(", v, ")"))
  # svyby estimates prevalence within each observed subgroup.
  est <- tryCatch(
    survey::svyby(~severe_wasting, f, dsub, survey::svymean,
                  na.rm = TRUE, vartype = c("se", "ci"), keep.names = FALSE),
    error = function(e) NULL
  )
  if (!is.null(est)) {
    tmp <- as.data.frame(est)
    tmp$group_variable <- v
    prev_rows[[v]] <- tmp
  }
}
if (length(prev_rows)) {
  write.csv(bind_rows(prev_rows), file.path(out_dir, "subgroup_prevalence.csv"),
            row.names = FALSE)
}

# Candidate predictors from the existing notebook. Only variables present in
# the supplied data are used; the selected variables are recorded in outputs.
candidate <- c(
  "ub2", "female", "diarrhoea_2w", "cough_2w", "breathing_2w",
  "edu_level", "mage_cat", "parity_cat", "water_cat", "toilet_cat",
  "fuel_cat", "urban", "wealth", "division"
)
predictors <- intersect(candidate, names(dat))
factor_vars <- intersect(
  c("edu_level", "mage_cat", "parity_cat", "water_cat", "toilet_cat",
    "fuel_cat", "wealth", "division"),
  predictors
)
for (v in factor_vars) dat[[v]] <- factor(dat[[v]])
# Collapse the sparse zero-parity category only if the source coding confirms
# it means zero; keep original parity_cat unchanged for auditability.
if ("parity_cat" %in% names(dat)) {
  dat$parity_model <- factor(ifelse(as.character(dat$parity_cat) == "0", "1",
                                    as.character(dat$parity_cat)))
  predictors[predictors == "parity_cat"] <- "parity_model"
  factor_vars <- unique(c(setdiff(factor_vars, "parity_cat"), "parity_model"))
}
writeLines(paste(predictors, collapse = "\n"),
           file.path(out_dir, "core_model_predictors.txt"))

# Complete-case model, with sample-flow and missingness reports.
model_vars <- unique(c("severe_wasting", "hh1", "strata", "chweight", predictors))
model_dat <- dat[complete.cases(dat[, model_vars, drop = FALSE]), , drop = FALSE]
write.csv(
  data.frame(
    analysis = c("eligible_design_outcome_sample", "complete_case_core_model"),
    n = c(nrow(dat), nrow(model_dat)),
    events = c(sum(dat$severe_wasting == 1), sum(model_dat$severe_wasting == 1)),
    non_events = c(sum(dat$severe_wasting == 0), sum(model_dat$severe_wasting == 0))
  ),
  file.path(out_dir, "sample_flow.csv"), row.names = FALSE
)
miss <- data.frame(
  variable = names(dat),
  missing_n = vapply(dat, function(x) sum(is.na(x)), integer(1)),
  missing_pct = vapply(dat, function(x) mean(is.na(x)) * 100, numeric(1))
)
write.csv(miss, file.path(out_dir, "missingness.csv"), row.names = FALSE)

if (nrow(model_dat) == 0 || sum(model_dat$severe_wasting == 1) < 20) {
  stop("Insufficient complete-case observations/events for the core model.")
}
des_model <- survey::svydesign(
  ids = ~hh1, strata = ~strata, weights = ~chweight,
  data = model_dat, nest = TRUE
)

rhs <- vapply(predictors, function(v) {
  if (v %in% factor_vars) paste0("factor(", v, ")") else v
}, character(1))
core_formula <- as.formula(paste("severe_wasting ~", paste(rhs, collapse = " + ")))
core_fit <- survey::svyglm(core_formula, design = des_model,
                           family = quasibinomial())

coef_table <- as.data.frame(summary(core_fit)$coefficients)
coef_table$term <- rownames(coef_table)
names(coef_table)[1:4] <- c("estimate_log_odds", "std_error", "statistic", "p_value")
coef_table$OR <- exp(coef_table$estimate_log_odds)
coef_table$OR_CI_low <- exp(coef_table$estimate_log_odds - 1.96 * coef_table$std_error)
coef_table$OR_CI_high <- exp(coef_table$estimate_log_odds + 1.96 * coef_table$std_error)
write.csv(coef_table, file.path(out_dir, "core_survey_logistic_or.csv"),
          row.names = FALSE)

# Design-adjusted joint Wald tests for categorical factors.
joint <- list()
for (v in factor_vars) {
  term <- if (v == "parity_model") "parity_model" else paste0("factor(", v, ")")
  result <- tryCatch(survey::regTermTest(core_fit, as.formula(paste("~", term))),
                     error = function(e) NULL)
  if (!is.null(result)) {
    joint[[v]] <- data.frame(
      variable = v,
      wald_statistic = as.numeric(result$Ftest[1]),
      numerator_df = as.numeric(result$df[1]),
      denominator_df = as.numeric(result$ddf[1]),
      p_value = as.numeric(result$p)
    )
  }
}
if (length(joint)) write.csv(bind_rows(joint), file.path(out_dir, "joint_factor_tests.csv"),
                             row.names = FALSE)

# Adjusted prevalence ratios: survey-weighted modified Poisson model.
pr_fit <- survey::svyglm(core_formula, design = des_model,
                         family = quasipoisson(link = "log"))
pr_coef <- as.data.frame(summary(pr_fit)$coefficients)
pr_coef$term <- rownames(pr_coef)
names(pr_coef)[1:4] <- c("estimate_log_pr", "std_error", "statistic", "p_value")
pr_coef$adjusted_PR <- exp(pr_coef$estimate_log_pr)
pr_coef$CI_low <- exp(pr_coef$estimate_log_pr - 1.96 * pr_coef$std_error)
pr_coef$CI_high <- exp(pr_coef$estimate_log_pr + 1.96 * pr_coef$std_error)
write.csv(pr_coef, file.path(out_dir, "core_survey_modified_poisson_pr.csv"),
          row.names = FALSE)

# Age functional form: compare a linear-age model with a natural-spline model
# via a design-adjusted Wald test of the additional spline terms.
if ("ub2" %in% predictors) {
  other_rhs <- setdiff(rhs, "ub2")
  linear_formula <- as.formula(paste("severe_wasting ~ ub2",
                                     if (length(other_rhs)) paste("+", paste(other_rhs, collapse = " + ")) else ""))
  spline_formula <- as.formula(paste("severe_wasting ~ splines::ns(ub2, df = 3)",
                                     if (length(other_rhs)) paste("+", paste(other_rhs, collapse = " + ")) else ""))
  age_linear <- survey::svyglm(linear_formula, design = des_model, family = quasibinomial())
  age_spline <- survey::svyglm(spline_formula, design = des_model, family = quasibinomial())
  age_test <- tryCatch(
    survey::regTermTest(age_spline, ~splines::ns(ub2, df = 3)),
    error = function(e) NULL
  )
  if (!is.null(age_test)) {
    write.csv(data.frame(
      test = "joint natural-spline age term",
      F_statistic = as.numeric(age_test$Ftest[1]),
      numerator_df = as.numeric(age_test$df[1]),
      denominator_df = as.numeric(age_test$ddf[1]),
      p_value = as.numeric(age_test$p)
    ), file.path(out_dir, "age_nonlinearity_test.csv"), row.names = FALSE)
  }
  age_grid <- data.frame(ub2 = seq(min(model_dat$ub2, na.rm = TRUE),
                                   max(model_dat$ub2, na.rm = TRUE), length.out = 100))
  for (v in setdiff(predictors, "ub2")) {
    if (v %in% factor_vars) age_grid[[v]] <- factor(levels(model_dat[[v]])[1],
                                                    levels = levels(model_dat[[v]]))
    else age_grid[[v]] <- median(model_dat[[v]], na.rm = TRUE)
  }
  age_grid$predicted_probability <- predict(age_spline, newdata = age_grid, type = "response")
  write.csv(age_grid[, c("ub2", "predicted_probability")],
            file.path(out_dir, "age_spline_predictions.csv"), row.names = FALSE)
}

# Hypothesis-driven interactions; each is tested separately to limit overfit.
interaction_results <- list()
if (all(c("female", "ub2") %in% predictors)) {
  fit <- tryCatch(update(core_fit, . ~ . + female:ub2), error = function(e) NULL)
  if (!is.null(fit)) {
    test <- tryCatch(survey::regTermTest(fit, ~female:ub2), error = function(e) NULL)
    if (!is.null(test)) interaction_results[["female_by_age"]] <- data.frame(
      interaction = "female x age", F_statistic = as.numeric(test$Ftest[1]),
      p_value = as.numeric(test$p))
  }
}
if (all(c("wealth", "urban") %in% predictors)) {
  fit <- tryCatch(update(core_fit, . ~ . + factor(wealth):urban), error = function(e) NULL)
  if (!is.null(fit)) {
    test <- tryCatch(survey::regTermTest(fit, ~factor(wealth):urban), error = function(e) NULL)
    if (!is.null(test)) interaction_results[["wealth_by_urban"]] <- data.frame(
      interaction = "wealth x urban", F_statistic = as.numeric(test$Ftest[1]),
      p_value = as.numeric(test$p))
  }
}
if (length(interaction_results)) {
  itab <- bind_rows(interaction_results)
  itab$p_fdr <- p.adjust(itab$p_value, method = "BH")
  write.csv(itab, file.path(out_dir, "interaction_tests.csv"), row.names = FALSE)
}

# Exploratory univariate design-adjusted tests with Benjamini-Hochberg FDR.
uni_results <- list()
for (v in group_vars) {
  if (v %in% names(dat)) {
    test <- tryCatch(
      survey::svychisq(as.formula(paste("~factor(", v, ") + severe_wasting")),
                       design = des, statistic = "F"),
      error = function(e) NULL
    )
    if (!is.null(test)) uni_results[[v]] <- data.frame(
      variable = v, statistic = as.numeric(test$statistic),
      numerator_df = if (!is.null(test$parameter)) as.numeric(test$parameter[1]) else NA_real_,
      p_value = as.numeric(test$p.value)
    )
  }
}
if (length(uni_results)) {
  utab <- bind_rows(uni_results)
  utab$p_fdr <- p.adjust(utab$p_value, method = "BH")
  write.csv(utab, file.path(out_dir, "univariate_tests_fdr.csv"), row.names = FALSE)
}

# Survey-weighted calibration diagnostics on the complete-case sample.
# These are descriptive; calibration and discrimination should be validated
# out-of-sample before any predictive claim is made.
model_dat$predicted <- as.numeric(predict(core_fit, newdata = model_dat, type = "response"))
model_dat$predicted <- pmin(pmax(model_dat$predicted, 1e-6), 1 - 1e-6)
model_dat$calibration_bin <- dplyr::ntile(model_dat$predicted, 10)
calibration <- model_dat |>
  group_by(calibration_bin) |>
  summarise(
    n = n(),
    weighted_predicted_pct = weighted.mean(predicted, chweight) * 100,
    weighted_observed_pct = weighted.mean(severe_wasting, chweight) * 100,
    .groups = "drop"
  )
write.csv(calibration, file.path(out_dir, "in_sample_calibration_deciles.csv"),
          row.names = FALSE)
brier <- weighted.mean((model_dat$severe_wasting - model_dat$predicted)^2,
                       model_dat$chweight)
write.csv(data.frame(weighted_in_sample_brier = brier),
          file.path(out_dir, "in_sample_brier.csv"), row.names = FALSE)

# Sensitivity analyses for alternative wasting endpoints, only when present.
# These are separate outcomes, never predictors in the severe-wasting model.
for (outcome in intersect(c("mod_wasting", "any_wasting"), names(dat))) {
  tmp <- dat[!is.na(dat[[outcome]]), , drop = FALSE]
  if (all(tmp[[outcome]] %in% c(0, 1)) && nrow(tmp) > 0) {
    dtmp <- survey::svydesign(ids = ~hh1, strata = ~strata, weights = ~chweight,
                              data = tmp, nest = TRUE)
    prev <- survey::svymean(as.formula(paste0("~", outcome)), dtmp, na.rm = TRUE)
    write.csv(data.frame(
      outcome = outcome, weighted_prevalence_pct = as.numeric(coef(prev)[1]) * 100,
      standard_error = as.numeric(SE(prev)[1]) * 100
    ), file.path(out_dir, paste0("sensitivity_", outcome, "_prevalence.csv")),
    row.names = FALSE)
  }
}

message("Follow-up analysis completed. Review CSVs in: ", normalizePath(out_dir))
message("Important: compare estimates with Stata svyset/svy output before publication.")
