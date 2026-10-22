# Follow-up analysis: results, interpretation, and remaining gaps

## Status at a glance

**The follow-up R script is written but has not yet completed successfully on the local machine.** The latest reported error says Windows Application Control blocked `readr.dll`. Consequently, no output from `analysis_followup.R` has yet been inspected or validated. The findings in this document are from the existing notebooks and must be treated as preliminary.

## Why a follow-up is needed

The existing notebooks explore severe wasting using descriptive summaries, univariate tests, and regression. However, some earlier models use sampling weights with cluster-robust standard errors but do not fully represent the survey strata in the variance calculation. The notebooks also contain reproducibility and sparse-category issues. The R script was added to represent the PSU, stratum, and sampling weight explicitly using the `survey` package.

## Research question

Which child, maternal, and household characteristics are associated with severe wasting among children under five in the available MICS child dataset?

The dataset is reported as having 22,311 eligible records and 552 severe-wasting cases in the initial sample. These counts should be reproduced by the R script and checked against the source data and outcome coding.

## What the existing notebook suggests

The statements below summarize previously saved notebook results; they are not newly generated results from the R follow-up.

### 1. Child age

The notebook reports that prevalence is higher among younger children and decreases with age. It reports a univariate odds ratio of approximately 0.81 per additional year and an adjusted odds ratio of approximately 0.80 (95% CI 0.74–0.86) in the all-child model.

**Interpretation:** age appears to be an important correlate in this sample. This does not prove that age itself causes the difference. The shape of the age relationship should be checked rather than assuming it is perfectly linear.

### 2. Child sex

The notebook reports prevalence of about 2.89% among boys and 2.11% among girls in the univariate summary. Its preliminary adjusted model reports an adjusted odds ratio of about 0.72 for girls relative to the model's reference category (95% CI 0.58–0.88).

**Interpretation:** the existing analysis suggests lower odds among girls than boys after adjustment. Confirm category coding and the survey-design-based confidence interval before reporting this as a final estimate.

### 3. Household wealth

The notebook reports a modest decline in univariate odds across wealth quintiles, but the adjusted evidence is not consistent across models.

**Interpretation:** wealth may be related to severe wasting, but the current results do not support a simple, definitive claim that wealth independently explains the outcome. Check the overall joint test, confidence intervals, missingness, and reference categories.

### 4. Recent illness

The notebook reports univariate associations for recent diarrhoea, cough, and any illness. Those associations may be affected by age, household circumstances, measurement timing, or other confounding.

**Interpretation:** treat these as possible correlates, not proof that illness caused severe wasting or that severe wasting caused illness.

### 5. Maternal and household factors

Some preliminary adjusted category estimates for maternal age, division, and toilet category are reported as statistically significant. At least one toilet category is very small, and the total number of severe-wasting cases is limited.

**Interpretation:** these results are hypothesis-generating. Small cells, multiple testing, and unstable coefficients can produce apparently strong but imprecise associations. Prefer joint tests and confidence intervals, and verify estimates with the design-aware model.

### 6. Prediction experiments

The main notebook reports an in-sample survey-weighted ROC-AUC of about 0.635. The secondary notebook reports a weighted cross-validation ROC-AUC around 0.536 for a random forest using PSU-grouped folds. These estimates come from different models and sample definitions.

**Interpretation:** the current evidence does not establish strong predictive performance. In-sample performance can be optimistic, and ROC-AUC alone does not show whether a model is useful for a rare outcome. Any prediction project should use held-out clusters, report precision–recall performance and calibration, and compare against a simple baseline.

## What the R script is intended to produce

If it runs successfully, `analysis_followup.R` is intended to create files under `outputs/`:

| Output | What it answers |
|---|---|
| `sample_and_prevalence.csv` | How many observations/cases are included, and what is the overall weighted prevalence? |
| `sample_flow.csv` | How many children and cases remain in the core complete-case model? |
| `missingness.csv` | Which variables have missing values, and how much is missing? |
| `subgroup_prevalence.csv` | How does weighted prevalence vary across selected groups? |
| `core_survey_logistic_or.csv` | What are the adjusted odds ratios and confidence intervals in the survey-design model? |
| `core_survey_modified_poisson_pr.csv` | What are the adjusted prevalence ratios from the modified-Poisson model? |
| `joint_factor_tests.csv` | Is there overall evidence for a multi-category predictor? |
| Exploratory test / age / interaction files | Are there exploratory signals worth checking in a pre-specified analysis? |
| In-sample calibration output | How closely do fitted probabilities match outcomes in the same model sample? |

These are intended outputs, not confirmation that the files exist or that every model has run correctly. Inspect all warnings, convergence, estimates, and confidence intervals. In-sample calibration is not external or out-of-sample validation.

## Survey design and important choices

- PSU/cluster: `hh1`
- Stratum: `strata`
- Weight: `chweight`
- The Stata reference uses `singleunit(centered)`; the R script currently sets `survey.lonely.psu = "adjust"`. Compare estimates with Stata rather than assuming these settings are identical.
- The R script uses complete cases for the core model. Missingness and sample flow must be reviewed before interpretation.
- The script recodes the sparse zero-parity category for model estimation. Confirm its meaning in the codebook and document this choice.
- Outcome-derived variables such as `whz2`, `mod_wasting`, `any_wasting`, and `wast_cat` must not be predictors of `severe_wasting`.

## Gaps that remain

1. **Windows execution:** resolve the Application Control block on `readr.dll` with the appropriate Windows security settings or administrator support. Do not bypass security controls globally.
2. **Code validation:** run the script end to end and fix any R errors. The script has not been tested against the local dataset yet.
3. **Survey validation:** compare overall and subgroup prevalence, coefficients, standard errors, confidence intervals, and tests with Stata `svy:`.
4. **Outcome validation:** confirm severe-wasting coding and the alternative wasting outcomes from the source codebook.
5. **Sparse data:** review zero cells, separation, small categories, and model stability; consider defensible category collapsing or penalized methods where appropriate.
6. **Notebook reproducibility:** restart the Python kernel and run `eda.ipynb` from top to bottom. Resolve undefined variables and inspect the secondary GLM's missing standard errors before using its coefficients.
7. **Prediction:** do not claim a deployable predictor until PSU-grouped validation and appropriate rare-outcome metrics are complete.
8. **Reporting:** define a primary model and hypotheses in advance, prioritize effect sizes and intervals, and label exploratory/FDR-adjusted tests clearly.

## Current interpretation

The most consistent preliminary signals are child age and sex. Other factors—wealth, recent illness, maternal characteristics, and household conditions—need stronger validation because results vary by model and some categories are sparse. No causal claim is supported at this stage.

**Next milestone:** get the R script to run, inspect its outputs, compare key estimates with Stata, and only then update this section with validated design-aware results.
