# Severe Wasting among Children Under Five: MICS Analysis

This project explores child, maternal, and household factors associated with **severe wasting** (weight-for-height z-score < -3) among children under five in a MICS child dataset. It combines Python exploratory notebooks with a survey-design-aware R follow-up (`survey` package).

> **Status: preliminary, but reproduced.** The R script was re-run independently (R 4.3.3, Linux) and its original 14 output tables matched the committed CSVs to about 1e-14. Estimates have **not** yet been compared with Stata `svy:`, so treat them as provisional, not publication-ready.

## Start here

- [Methodology in simple words](methodology.md): what was done and why.
- [Follow-up results, interpretation, and gaps](FOLLOWUP_ANALYSIS.md): readable summary of current outputs.
- [R follow-up script](analysis_followup.R): survey models, infant-subpopulation models, tests, diagnostics.
- [Main exploratory notebook](eda.ipynb): data prep, **extended EDA (sections 1-12)**, univariate and multivariable tests.
- [Tree-based prediction notebook](models.ipynb): untuned Decision Tree, Random Forest, XGBoost and LightGBM with cross-validation, ROC curves and SHAP, plus a fair nested-CV comparison with tuned models and logistic regression.\n- [Interpretable neural-network notebook](nn.ipynb) and [results](nn.md): two PyTorch Neural Additive Models for ages 0-4 and 0-1 using the same predictor sets as `models.ipynb`.
- [SHAP and prediction results](SHAP_results.md): tables, figures and interpretation from `models.ipynb`.
- [Earlier modelling notebook](analysis.ipynb): preliminary GLM, random forest, SHAP (superseded by `models.ipynb`).
- [`outputs/`](outputs): CSV tables written by `analysis_followup.R`.

## Research question and data

**Question:** Which child, maternal, and household characteristics are associated with severe wasting among children under five?

- **Sample:** 22,311 children, 3,144 PSUs, 16 strata, 67 districts. 552 severe-wasting cases: unweighted prevalence 2.47%, design-weighted **2.52%** (95% CI 2.29-2.77).
- **Outcome check:** `severe_wasting` equals WHZ < -3 exactly (all 552 cases have WHZ between -4.96 and -3.01). `whz2`, `mod_wasting`, `any_wasting` and `wast_cat` are derived from the same measurement and are never used as predictors.
- **Survey design:** cluster/PSU `hh1`, stratum `strata`, child weight `chweight`. The Stata reference is `svyset hh1 [pweight=chweight], strata(strata) singleunit(centered)`. No stratum has a single PSU (33-451 PSUs each), so R's `survey.lonely.psu = "adjust"` and Stata's `centered` option do not change anything here.
- **"Infants 0-1"** means completed age 0 or 1 year, i.e. children **under 2** (8,888 children, 297 cases). Feeding and antenatal-care variables exist only for this group.

## Key findings (provisional)

### All children 0-4 (core survey-weighted logistic model, N = 22,017, 543 cases)

- **Age:** OR **0.80 per year** (95% CI 0.74-0.86). The relationship is not linear (spline test p < 0.001): adjusted risk for a reference child falls from about 4.8% at age 0 to 3.5% at age 1, 2.7% at age 2 and 2.3% at age 3. Use a flexible age term in the final model.
- **Sex:** girls vs boys OR **0.72** (0.58-0.88); weighted prevalence 2.11% vs 2.89%. Among the univariate tests, sex is the only one that stays significant after Benjamini-Hochberg correction (FDR p = 0.018).
- **Recent illness:** diarrhoea adjusted OR 1.35 (0.94-1.93), cough 1.17 (0.92-1.48), breathing difficulty 0.92 (0.65-1.29). Diarrhoea is significant on its own (OR 1.56, p = 0.014) but weakens after adjustment, partly because it is commoner at ages 0-1. Within each age band, prevalence is still about 1.4 times higher with diarrhoea.
- **Maternal age, toilet type:** individual categories show ORs of about 1.8 and 2.3, but overall joint tests are not significant (p = 0.177 and 0.151). Treat as exploratory; the toilet category has only 12 cases.
- **Division:** joint test p = 0.0176, so geographic variation may exist. Wealth (p = 0.632) and education (p = 0.633) are not significant jointly once other factors are in the model.
- **Alternative outcomes:** weighted prevalence of moderate wasting 10.37% and any wasting 12.88%.

### Infants and young children, ages 0-1 (survey subpopulation, N = 8,713 complete cases, 291 cases)

The infant variables were the strongest univariate signals, so they are analysed separately (`subset()` on the full design keeps variance estimates valid).

| Variable | Univariate result (design-adjusted) | After adjustment |
|---|---|---|
| Dietary diversity `dds` (per food group) | OR 0.86 (0.80-0.94), p = 0.0005 | OR 0.90 (0.81-1.00), p = 0.045 in the parsimonious model; association holds within age 0 (OR 0.87, p = 0.036) and age 1 (OR 0.87, p = 0.088); not linear (spline p = 0.020), prevalence drops once dds reaches 2 |
| Ate flesh foods `fg_flesh` | 3.93% vs 2.15% (no vs yes), F p = 0.0001 | OR 0.65 (0.45-0.95), p = 0.026 |
| Ate grains/tubers `fg_grain` | 4.43% vs 2.73%, F p = 0.0002 | OR 0.69 (0.48-1.01), p = 0.054 |
| Food variety `fvs` | OR 0.91 (0.85-0.97), p = 0.006 | not in adjusted models (collinear with `dds`) |
| ANC visits `anc_cat` | 4.88% / 3.68% / 2.58% (none / 1-3 / 4+), p = 0.008; trend OR 0.71 (0.57-0.88) | 4+ vs none OR 0.65 (0.39-1.07), p = 0.091; joint test p about 0.16 |
| Breastfeeding `bf_status`, bottle `bottle` | no association | no association |

How to read this:

- The univariate signals are real, but they shrink after adjustment. Feeding is strongly age-dependent (grains rise from about 40% at age 0 to 90% at age 1; flesh foods from 13% to 54%), and antenatal care and diet both track wealth (17.8% of the poorest infants had no ANC vs 1.6% of the richest).
- `dds` is exactly the sum of the seven `fg_*` indicators, so they are modelled **separately** (Model A uses `dds`, Model B uses the `fg_*` groups), never together.
- The full infant models (A: 45 parameters, B: 51) have only 5.7-6.5 events per parameter and are overfitted; the parsimonious Model C (11 parameters, 26.5 events per parameter) is the primary infant model.
- Diet is a single 24-hour recall in a cross-sectional survey: sick or wasted children may eat less (reverse causation), so these are associations, not effects.

### Prediction

The weighted in-sample Brier score of the core survey model (0.02436) is nearly the same as a no-skill model that predicts the average prevalence (0.02453). The tree-based experiments below confirm that prediction is weak. The 0.635 in-sample AUC in `eda.ipynb` was optimistic: the full survey-weighted logistic regression scores 0.580 out of fold.

## Tree-based prediction and SHAP (`models.ipynb`)

Full tables, figures and caveats are in [SHAP_results.md](SHAP_results.md).

### Raw (untuned) tree models

Four untuned tree models (Decision Tree, Random Forest, XGBoost, LightGBM) were cross-validated with PSU-grouped, stratified 5-fold splits.

| Analysis | Best model | Mean ROC AUC (5 folds) | Other models |
|---|---|---|---|
| A: all children, 0-4 (22,311; 552 cases) | LightGBM | **0.542** | Random Forest 0.534, XGBoost 0.526, Decision Tree 0.503 |
| B: ages 0-1 with feeding and ANC variables (8,888; 297 cases) | XGBoost | **0.552** | Random Forest 0.545, LightGBM 0.544, Decision Tree 0.500 |

- **Weak prediction:** AUC is only slightly above chance (permutation p = 0.020 and 0.039). The top 10% highest-risk children contain 14-15% of cases (10% by chance). Training AUC is 0.97-1.00, so the raw ensembles overfit.
- **SHAP (out of fold, best raw model):** child age is the top predictor in Analysis A (17% of importance), followed by mother's age, wealth, division, number of births and sex. In Analysis B the diet variables (`dds` and food groups) carry about 27% of the SHAP importance, with `dds`, `fg_flesh` and ANC all lowering predicted risk when higher.
- **Agreement with the survey analysis:** age, sex, wealth, diet and ANC agree. Maternal age ranks high in SHAP but is not supported by the inference and likely reflects overfitting.

### Fair comparison: tuned models vs logistic regression (nested CV)

Every model uses the same children, outer folds and preprocessing; tree hyperparameters are tuned only inside each outer training fold; weighted metrics are primary and intervals come from a PSU cluster bootstrap. Selected rows (weighted pooled out-of-fold ROC AUC, 95% CI):

| Model | A: all children | B: ages 0-1 |
|---|---|---|
| Logistic: age + sex | 0.587 (0.558-0.613) | 0.548 (0.511-0.584) |
| Logistic: full, survey-weighted (reference) | 0.580 (0.553-0.611) | 0.570 (0.533-0.605) |
| Logistic: regularised, weighted | 0.581 (0.553-0.610) | 0.580 (0.545-0.615) |
| Random Forest (tuned) | 0.584 (0.555-0.614) | **0.595** (0.557-0.634) |
| XGBoost (tuned) | 0.585 (0.557-0.614) | 0.589 (0.555-0.628) |
| LightGBM (tuned) | 0.560 (0.532-0.588) | 0.573 (0.541-0.613) |
| Decision Tree (tuned) | 0.555 (0.526-0.584) | 0.546 (0.506-0.584) |
| Prevalence baseline | 0.485 | 0.488 |

- **No clear winner for all children.** The logistic models, tuned Random Forest and tuned XGBoost are statistically indistinguishable (differences vs the weighted logistic are within about ±0.03, and all intervals include 0), and age + sex alone is as good (0.587). The extra predictors and tree ensembles add no measurable discrimination.
- **Tuning helps the trees:** unweighted AUC rises from 0.534 to 0.582 (Random Forest), 0.526 to 0.580 (XGBoost) and 0.503 to 0.554 (Decision Tree). The chosen settings are shallow and regularised (for example XGBoost depth 2 in every fold), consistent with a weak signal.
- **Under 2, the extra variables help a little:** tuned Random Forest is nominally best (+0.025 over weighted logistic, 95% CI 0.000 to 0.052) and the regularised logistic regression beats the plain one (+0.010, CI 0.003 to 0.018). Age + sex alone is lower here (0.548).
- **Still modest, and over-confident:** AUC is at most about 0.60; PR AUC is about 0.035 (prevalence 0.025) in A and 0.046 (0.033) in B; the top 10% of predicted risk holds up to about 19% of cases in A (best models) and 15-16% in B (tree models); Brier is no better than the baseline. Calibration slopes are 0.3-0.8 for all complex models (age + sex: 0.93), so their probabilities need recalibration.
- **Caution:** the Python weighted fit gives no design-based standard errors, the tuning budget is small, and SHAP was computed on the raw models, not the tuned ones. No causal claims.

## Multicollinearity and PCA (`multicollinearity_pca.ipynb`)

The locally executed notebook now includes pairwise overlap, VIF diagnostics, PCA variance summaries, cross-validated prediction using PCA scores, and SHAP explanations in component space.

### Multicollinearity diagnostics

- The analysis loaded 22,311 children and identified 552 severe-wasting cases in the all-child sample; the under-2 sample contained 8,888 children and 297 cases.
- The notebook could match only **7 core predictors** for all children and **17 predictors** for under-2 from the names currently available in the dataset. Many planned candidates were not found. These results therefore describe the predictors actually detected by the notebook, not the full intended predictor inventory.
- The VIF design matrix was poorly conditioned and rank-deficient. Several district indicators have extremely large VIFs, and district (`hh7a`) is almost deterministically associated with division. Treat the numeric VIF values as unstable; the robust takeaway is redundant geographic encoding. Consider using either district or division (or a carefully defined geographic hierarchy), and inspect dummy coding before using VIF to drop individual predictors.
- PCA retained at least 80% of encoded predictor variance with **18 components from 94 encoded columns** for all children and **24 components from 114 encoded columns** for children under 2. The first component explained 22.2% and 18.1%, respectively; the first five explained 46.8% and 45.1%.

### Prediction using PCA scores

The notebook used the selected FS1 configurations saved in `outputs/tuning_results.csv`, with PCA fitted inside each training fold. Metrics below are means across five PSU-grouped folds, not pooled out-of-fold metrics, so they should not be compared as if identical to the nested-CV results above.

| Cohort | Model | Mean weighted ROC-AUC (SD) | Mean weighted PR-AUC | Mean Brier score |
|---|---|---:|---:|---:|
| All children 0-4 | LightGBM | **0.548 (0.019)** | 0.036 | 0.02455 |
| All children 0-4 | XGBoost | 0.546 (0.022) | 0.032 | 0.02454 |
| All children 0-4 | Random Forest | 0.525 (0.029) | 0.030 | 0.02455 |
| All children 0-4 | Elastic Net | 0.519 (0.026) | 0.031 | 0.02454 |
| Children 0-1 | Elastic Net | **0.561 (0.047)** | 0.048 | 0.03210 |
| Children 0-1 | XGBoost | 0.560 (0.046) | 0.043 | 0.03206 |
| Children 0-1 | LightGBM | 0.560 (0.046) | 0.045 | 0.03207 |
| Children 0-1 | Random Forest | 0.540 (0.037) | 0.039 | 0.03208 |

CatBoost was not present in the selected configurations returned to this PCA evaluation, so no PCA-CatBoost score is reported. These PCA results show **weak discrimination**, with mean AUCs around 0.52-0.55 for all children and 0.54-0.56 for children under 2. No model reaches strong individual-level prediction, and differences among the top under-2 models are very small relative to fold-to-fold variation.

### SHAP on principal components

SHAP was run for the fitted PCA models. In the all-child tree models, components around PC7 and PC5/PC8 ranked highly; their largest loadings include child-age-related encoded categories (`ub2`/ `wb4`) and geographic/household categories such as division, toilet and fuel. For the under-2 models, PC1 (strong loadings from food variety and food-group indicators), PC3 (ANC-category loadings), and PC9 (geographic/household loadings) were prominent for different models.

**Interpretation caution:** SHAP values describe the model's use of principal components, not the direct effect of a named original predictor. Loading tables show which encoded variables contribute strongly to a component, but this is not equivalent to original-variable SHAP or a causal effect. Component rankings also differ by model and cohort.

## Interpretable neural networks (`nn.ipynb`)

Two PyTorch Neural Additive Models (NAMs) were added using exactly the same predictors as `models.ipynb`: one for all children aged 0-4 and one for ages 0-1/under 2. The additive architecture makes each original variable's logit contribution directly inspectable while still allowing nonlinear continuous effects. Evaluation again uses PSU-grouped stratified 5-fold cross-validation.

The result is a useful negative finding: weighted out-of-fold ROC AUC is **0.492** for all children and **0.522** for ages 0-1. This is worse than the logistic/tuned-tree comparison already in the project (about 0.58-0.60). Feature-contribution rankings are therefore treated as unstable model descriptions, not new epidemiologic evidence. See [nn.md](nn.md) for interpretation and limitations.

## Extended EDA added to `eda.ipynb`

Section "Extended Exploratory Data Analysis" (right after data preparation) covers: structural missingness; outcome definition check against WHZ; survey-design diagnostics; age-by-sex and age-by-wealth patterns; division and district funnel plot; predictor profiles; illness-by-age confounding; predictor overlap (Cramer's V, VIF); infant feeding and ANC; data-validity checks. Main takeaways:

- The design effect (about 1.34) comes from the weights, not clustering: PSU dispersion ratio 1.04 and ICC about 0.0003.
- Missingness is mostly structural: infant-only variables are about 60% missing overall but only 0-1% missing at ages 0-1 (meal frequency `bd9` is the exception at 27%).
- Several categories are too small for stable estimates (`toilet_cat` 3: 12 cases; `fuel_cat` 4: 5; unmarried mothers: 9; `parity_cat` 0: 29 children, 0 cases, likely non-mother caretakers).

## CatBoost update (code added; results pending)

CatBoost has been added to both the raw PSU-grouped cross-validation models and the nested hyperparameter search in `models.ipynb`. The tuned search covers iterations, depth, learning rate, L2 leaf regularization, random strength, bagging temperature, border count and class weighting. The raw-model SHAP workflow will explain CatBoost if it is selected as the best model by mean grouped-CV ROC-AUC for either analysis. The repository edit has not run the notebook against the local MICS dataset, so there are **no measured CatBoost scores or SHAP rankings yet**. The existing result tables below describe earlier models and must not be presented as including CatBoost until the notebook is rerun and its output tables regenerated.

## Main gaps

0. For prediction, even tuned tree models do not beat logistic regression (about 0.58-0.60 AUC). Repeat SHAP on the tuned Random Forest or XGBoost, recalibrate predicted probabilities if they will be used, use repeated grouped CV with more cases per fold for the under-2 analysis, and keep comparing with a simple age + sex logistic regression.

1. Compare weighted prevalence, confidence intervals, coefficients, and tests with Stata `svy:`.
2. Verify predictor coding against the source codebook (the outcome coding is now verified).
3. Use a flexible (spline) age term in the primary model.
4. Review sparse categories, multiple testing, and complete-case selection. Consider Firth or penalized models for sparse categories and multiple imputation for the infant models.
5. Repair the remaining notebook reproducibility issues: several cells in `eda.ipynb` (Poisson, interaction, joint-Wald, ROC, mixed-model cells) use variables never defined in the notebook (`df_model`, `df_multi`, `glm_main`, `main_formula`); the multilevel cell calls a function that does not exist in `statsmodels`. The R script supersedes the Poisson and interaction analyses but not the multilevel model.
6. Prediction claims now rest on PSU-grouped nested validation with weighted ROC-AUC, precision-recall, calibration and cluster-bootstrap intervals (see above); external validation is still missing.
7. Describe findings as observational associations, not causes.

## Run the R follow-up

Install packages:

```r
install.packages(c("haven", "dplyr", "survey"), repos = "https://cloud.r-project.org")
```

From the repository root:

```bash
Rscript analysis_followup.R MICS-child-ISRC.dta outputs
```

In Windows PowerShell, if R is not on PATH:

```powershell
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" analysis_followup.R MICS-child-ISRC.dta outputs
```

## Python modelling dependency

The updated `models.ipynb` includes CatBoost. Install it in the notebook's Python environment before running the modelling cells:

```bash
python -m pip install catboost
```

The notebook also requires the existing project dependencies (including scikit-learn, SHAP, XGBoost and LightGBM).

## Output files (tree-based models)

| File | Content |
|---|---|
| `outputs/ml_cv_summary_*.csv`, `outputs/ml_cv_fold_metrics_*.csv` | Cross-validation results (A = `all_children`, B = `infants`) |
| `outputs/ml_reference_logistic.csv`, `outputs/ml_permutation_check.csv` | Reference logistic regression and permutation test |
| `outputs/ml_shap_importance_*.csv` | Mean absolute SHAP, share and direction per variable; CatBoost will appear if it is the selected best raw model after rerunning |
| `outputs/fair_model_comparison_summary_*.csv` | Nested-CV metrics (weighted and unweighted) with calibration, for `all_children` and `under2` |
| `outputs/fair_model_comparison_cluster_bootstrap_*.csv` | Weighted AUC with PSU cluster-bootstrap CIs and paired differences vs weighted logistic |
| `outputs/fair_model_comparison_tuning_*.csv` | Hyperparameters selected in each outer fold, including CatBoost after rerunning the notebook |
| `outputs/fair_model_comparison_fold_metrics_*.csv`, `outputs/fair_model_comparison_oof_predictions_*.csv` | Fold-level metrics and out-of-fold predictions |
| `figures/ml_*.png` | ROC/PR curves and SHAP plots |

## Output files (infant additions)

| File | Content |
|---|---|
| `infant_sample_flow.csv` | Children and cases: all, ages 0-1, complete case |
| `infant_subgroup_prevalence.csv` | Weighted prevalence by feeding / ANC category |
| `infant_univariate_tests.csv` | Rao-Scott F tests and Wald trend ORs with FDR-adjusted p-values |
| `infant_model_A_dds_or.csv`, `infant_model_B_foodgroups_or.csv`, `infant_model_C_parsimonious_or.csv` | Adjusted odds ratios from the three infant models |
| `infant_model_summary.csv` | n, events, parameters and events per parameter for each model |
| `infant_joint_tests.csv` | Joint tests for `anc_cat` and `bf_status` |
| `infant_dds_by_age.csv`, `infant_dds_nonlinearity_test.csv` | Dietary diversity by age and spline test |
| `univariate_tests_fdr.csv` | Design-adjusted univariate tests for all children with FDR adjustment (previously never written because of a silent error; fixed) |

## Bottom line

The clearest signals are child age (non-linear, highest in the first two years) and sex, plus some geographic variation by division. In children under 2, more diverse and flesh/grain-containing diets are associated with lower odds of severe wasting, while the antenatal-care signal is largely explained by wealth and other factors. Validate against Stata and verify the codebook before presenting final findings.
