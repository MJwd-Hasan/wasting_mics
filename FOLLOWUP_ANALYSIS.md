# Follow-up analysis: results, interpretation, and remaining gaps

## Status

Output CSVs from `analysis_followup.R` are present in this branch. The local run currently fails because Windows Application Control blocks `readr.dll`; the outputs have not been independently reproduced on the current machine or checked against Stata. Treat the results below as **provisional**.

## Research question and sample

The project asks which child, maternal, and household characteristics are associated with severe wasting among children under five.

The current output reports 22,311 eligible children and 552 cases. Unweighted prevalence is 2.47%; design-weighted prevalence is **2.52%**. The core complete-case model includes 22,017 children and 543 cases.

## Findings from the current output tables

### Age
The core logistic model reports OR **0.80 per additional year** (95% CI 0.74–0.86; p < 0.001). A natural-spline test is significant (F = 12.35, p < 0.001).

**Meaning:** odds tend to be lower at older ages, but the relationship is not fully linear. The final primary model should use a flexible age term and present fitted risk across age; the single linear OR is only a summary.

### Sex
The adjusted OR for girls versus boys is **0.72** (95% CI 0.58–0.88; p = 0.0017). The subgroup table gives weighted prevalence of about 2.11% among girls and 2.89% among boys.

**Meaning:** the current model suggests lower odds among girls after adjustment. Verify coding and survey variance estimates before final reporting.

### Recent illness
- Diarrhoea: OR ≈ 1.35 (95% CI 0.94–1.93; p = 0.100).
- Cough: OR ≈ 1.17 (95% CI 0.92–1.48; p = 0.211).
- Breathing difficulty: OR ≈ 0.92 (95% CI 0.65–1.29; p = 0.629).

**Meaning:** these adjusted estimates do not show clear evidence of associations at the conventional 5% level. That does not prove there is no relationship; confounding and timing may matter.

### Multi-category factors

| Factor | Current output | Interpretation |
|---|---|---|
| Maternal age | Joint test p = 0.177 | No clear overall evidence for the factor, although two individual categories have ORs around 1.75 and 1.82. Treat these as exploratory. |
| Toilet category | Joint test p = 0.151 | No clear overall evidence. One small category has OR ≈ 2.34 (95% CI 1.06–5.14), which may be unstable. |
| Wealth | Joint test p = 0.632 | No clear overall association in this adjusted model. |
| Education | Joint test p = 0.633 | No clear overall association in this adjusted model. |
| Division | Joint test p = 0.0176 | Evidence of variation across divisions; investigate further, but do not infer a cause from this result alone. |

For multi-category predictors, consider the overall joint test as well as category-specific estimates. Avoid emphasizing an isolated p-value when the overall factor test is not significant, particularly when many comparisons have been made.

### Sensitivity outcomes
Current files report weighted prevalence of **10.37% for moderate wasting** and **12.88% for any wasting**. Confirm the source definitions and coding before quoting these values.

### Calibration and prediction
The calibration table is in-sample. In the highest-risk decile, predicted prevalence is 5.24% and observed prevalence is 5.96%. This does not show how the model will perform on new data.

The secondary Python notebook reports weighted random-forest ROC-AUC around 0.536 using cluster-grouped folds. The main notebook reports in-sample AUC around 0.635 for a different model/sample. These values are not directly comparable; useful predictive performance has not been established.

## Key output files

| File | What it tells you |
|---|---|
| `sample_and_prevalence.csv` | Eligible sample, cases, weighted/unweighted prevalence, PSUs and strata. |
| `sample_flow.csv` | Number of children and cases retained after complete-case selection. |
| `missingness.csv` | Missingness by variable. |
| `subgroup_prevalence.csv` | Weighted prevalence by selected group. |
| `core_survey_logistic_or.csv` | Adjusted odds ratios and confidence intervals. |
| `core_survey_modified_poisson_pr.csv` | Adjusted prevalence ratios and confidence intervals. |
| `joint_factor_tests.csv` | Overall tests for multi-category predictors. |
| `age_nonlinearity_test.csv`, `age_spline_predictions.csv` | Evidence for non-linearity and fitted age curve. |
| `interaction_tests.csv` | Selected exploratory interactions. |
| `in_sample_calibration_deciles.csv`, `in_sample_brier.csv` | In-sample calibration diagnostics. |
| `sensitivity_*_prevalence.csv` | Alternative outcome prevalence. |

The presence of CSVs does not by itself establish that the estimates are valid. Reproduce them with the current script, inspect warnings and convergence, and document which script/data version generated them.

## Survey design

The R script uses PSU `hh1`, stratum `strata`, and weight `chweight`. The reference Stata setup uses `singleunit(centered)`; R currently sets `survey.lonely.psu = "adjust"`. Compare prevalence, standard errors, confidence intervals, coefficients, and tests with Stata `svy:` rather than assuming the two settings are identical.

The core model is complete-case. Infant feeding variables have roughly 60% missingness in the full child file because they are mainly collected for younger children; analyze them in the appropriate subpopulation.

## Gaps to close

1. Resolve the Windows DLL block through appropriate security/administrator support; do not disable Windows security globally.
2. Re-run the R script and compare every output against the committed CSVs.
3. Validate the outcome and predictor coding with the source codebook.
4. Compare key R results with Stata `svy:`.
5. Use flexible age modelling; review sparse categories, multiple comparisons, missingness, and convergence.
6. Fix undefined variables and investigate the secondary notebook's very large GLM coefficients and missing standard errors.
7. For prediction, use held-out PSU-grouped validation, weighted ROC-AUC, precision–recall metrics, and held-out calibration.
8. Report associations, not causal effects.

## Current conclusion

Child age and sex are the clearest provisional signals; the age association appears non-linear. The division joint test suggests geographic variation may be present. The current output does not provide clear overall evidence for wealth, education, maternal age, or toilet category, while individual category results should be treated cautiously. Validate the outputs against Stata before making final claims.
