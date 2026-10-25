# Follow-up analysis: results, interpretation, and remaining gaps

## Status

Output CSVs from `analysis_followup.R` are present in this branch. The script was **independently re-run** (R 4.3.3, Linux) and the original 14 tables reproduced to about 1e-14. They have still not been checked against Stata, so treat the results below as **provisional**. (On the author's Windows machine the local run was blocked because Windows Application Control stopped `readr.dll`; that is a machine issue, not a script problem.)

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

Held-out results are in `models.ipynb` (see `SHAP_results.md`). With PSU-grouped nested cross-validation, the full survey-weighted logistic regression has an out-of-fold weighted ROC-AUC of 0.580 (95% cluster-bootstrap CI 0.553-0.611), compared with the 0.635 in-sample AUC from the main notebook, so the in-sample value was optimistic. Tuned tree models (Random Forest 0.584, XGBoost 0.585, LightGBM 0.560) and age + sex alone (0.587) score about the same, and raw untuned trees score 0.50-0.54. Among children under 2 the tuned Random Forest is nominally best (0.595). Brier scores equal the no-skill baseline and complex models are over-confident (calibration slopes 0.3-0.8), so useful predictive performance has not been established.

## Infants and young children, ages 0-1

Ages 0-1 means completed years 0 and 1 (children under 2): 8,888 children and 297 cases; 8,713 children and 291 cases with complete data. The analysis uses `subset()` on the full survey design so stratum and PSU structure stay intact. `dds` is exactly the sum of the seven `fg_*` indicators, so they are never in the same model.

### Univariate (design-adjusted, Benjamini-Hochberg across 13 tests)

| Variable | Result | FDR p |
|---|---|---|
| `fg_flesh` | 3.93% (no) vs 2.15% (yes); F p = 0.0001 | 0.0012 |
| `fg_grain` | 4.43% vs 2.73%; F p = 0.0002 | 0.0014 |
| `dds` | OR 0.86 per food group (0.80-0.94), p = 0.0005 | 0.0023 |
| `anc_cat` (trend) | OR 0.71 (0.57-0.88), p = 0.0018 | 0.0060 |
| `anc_cat` (categories) | 4.88% / 3.68% / 2.58%; F p = 0.008 | 0.017 |
| `fvs` | OR 0.91 (0.85-0.97), p = 0.006 | 0.015 |
| `bf_status`, `bottle`, other `fg_*` | p >= 0.089 | >= 0.149 |

### Multivariable

| Model | Parameters | Events per parameter | Key results |
|---|---|---|---|
| C, parsimonious (age, sex, diarrhoea, wealth, urban, `dds`, `anc_cat`) | 11 | 26.5 | `dds` OR 0.90 (0.81-1.00), p = 0.045; ANC 4+ vs none 0.65 (0.39-1.07), p = 0.091; girls 0.75 (0.57-0.98); wealth Q4 vs Q1 0.60 (0.39-0.92) |
| A, full adjusters + `dds`, ANC, breastfeeding, bottle | 45 | 6.5 | `dds` OR 0.90 (0.80-1.00), p = 0.048; ANC joint p = 0.17; breastfeeding joint p = 0.28 |
| B, full adjusters + 7 food groups, ANC, breastfeeding, bottle | 51 | 5.7 | `fg_flesh` OR 0.65 (0.45-0.95), p = 0.026; `fg_grain` OR 0.69 (0.48-1.01), p = 0.054 |

Models A and B have too few events per parameter and are shown for transparency; Model C is the primary infant model.

### Interpretation

- Dietary diversity, flesh foods and grains stay associated with lower odds after adjustment, though the confidence intervals are close to 1. Dietary diversity holds within age 0 (OR 0.87, p = 0.036) and age 1 (OR 0.87, p = 0.088), so it is not just an age effect. The relationship is not linear (spline p = 0.020): prevalence falls once a child eats at least 2 food groups.
- The ANC signal weakens after adjustment, consistent with confounding by wealth (17.8% of the poorest infants had no ANC vs 1.6% of the richest). Do not claim an independent ANC effect.
- Breastfeeding status and bottle feeding show no association.
- Diet is one 24-hour recall in a cross-sectional survey; reverse causation (sick or wasted children eating less) cannot be excluded. These are associations only.

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
| `univariate_tests_fdr.csv` | Design-adjusted univariate tests (all children) with FDR adjustment. Not produced before; a silent `svychisq` error is now fixed. |
| `infant_*.csv` | Infant-subpopulation sample flow, prevalence, univariate tests, three models, joint tests, dds-by-age and non-linearity (see README). |

The presence of CSVs does not by itself establish that the estimates are valid. They were reproduced with the current script (R 4.3.3), but still need comparison with Stata.

## Survey design

The R script uses PSU `hh1`, stratum `strata`, and weight `chweight`. The reference Stata setup uses `singleunit(centered)`; R sets `survey.lonely.psu = "adjust"`. In this dataset no stratum has a single PSU (33-451 PSUs each), so the two settings cannot differ. Still compare prevalence, standard errors, confidence intervals, coefficients, and tests with Stata `svy:`.

The core model is complete-case. Infant feeding variables have roughly 60% missingness in the full child file because they are mainly collected for younger children; analyze them in the appropriate subpopulation.

## Gaps to close

1. Compare key R results with Stata `svy:` (the R outputs themselves are now reproduced).
2. Validate predictor coding with the source codebook (the outcome was verified: it equals WHZ < -3).
3. Consider multiple imputation and Firth/penalized models for the infant analysis (about 6-7 events per parameter in the full models).
4. Add an infant-subpopulation sensitivity analysis excluding children who are not breastfed yesterday or using a dds spline.
5. Use flexible age modelling; review sparse categories, multiple comparisons, missingness, and convergence.
6. Fix undefined variables and investigate the secondary notebook's very large GLM coefficients and missing standard errors.
7. Prediction is now validated with PSU-grouped nested cross-validation (see `SHAP_results.md`); still needed are external validation, repeated grouped CV, and recalibration if probabilities will be used.
8. Report associations, not causal effects.

## Current conclusion

Child age and sex are the clearest provisional signals; the age association appears non-linear. The division joint test suggests geographic variation may be present. The current output does not provide clear overall evidence for wealth, education, maternal age, or toilet category, while individual category results should be treated cautiously. Validate the outputs against Stata before making final claims.


## CatBoost model extension (code committed; results not yet computed)

CatBoost has been added to `models.ipynb` in two places:

- **Raw-model comparison:** CatBoostClassifier now joins Decision Tree, Random Forest, XGBoost and LightGBM in the existing stratified PSU-grouped 5-fold evaluation. This means its predictions are evaluated on held-out PSUs, with ROC-AUC, PR-AUC, Brier score, top-decile capture and training AUC recorded alongside fit time.
- **Nested hyperparameter search:** CatBoost is now a candidate in the fair comparison with logistic regression and the other tuned trees. Its randomized search varies iterations, tree depth, learning rate, L2 leaf regularization, random strength, bagging temperature, border count and class weighting. Search stays inside each outer training fold; outer test PSUs are not used to choose settings.
- **SHAP:** the existing out-of-fold TreeExplainer workflow automatically selects the highest mean-AUC raw model per analysis. If CatBoost wins, its held-out predictions will receive the same SHAP summary, feature ranking and dependence plots.

**No CatBoost performance result is claimed yet.** The notebook has been edited and pushed, but it has not been executed against the local dataset in this work. Therefore the existing reported results—roughly 0.58-0.59 weighted out-of-fold AUC for the strongest all-child models and 0.595 for under-2 tuned Random Forest—remain the previous baseline, not a comparison that includes CatBoost. After running all notebook cells, regenerate the CSVs and figures, then update this section with CatBoost's weighted/unweighted ROC-AUC, PR-AUC relative to prevalence, Brier score, calibration, top-decile capture and PSU-bootstrap uncertainty. Only then decide whether it meaningfully improves on the weighted logistic benchmark or tuned Random Forest/XGBoost.

CatBoost's SHAP rankings should be treated as predictive explanations, not causal effects. The current SHAP procedure explains the best **raw** model, not the best nested-tuned model; do not describe those plots as explanations of the tuned winner unless a separate out-of-fold SHAP workflow is added for the selected tuned estimator.
