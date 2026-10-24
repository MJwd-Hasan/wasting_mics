# Methodology so far — plain-language guide

## 1. Research question

This project explores which child, maternal, and household characteristics are associated with **severe wasting among children under five** in a MICS child dataset. It is observational research: it can identify patterns and associations, but it cannot by itself prove cause and effect.

## 2. Dataset and outcome

The project uses `MICS-child-ISRC.dta`, a Stata-format child dataset. Current output tables report 22,311 eligible records and 552 severe-wasting cases. The outcome is `severe_wasting`, intended to indicate severe wasting based on weight-for-height z-score. Confirm its exact coding and cut-off in the source codebook before final reporting.

## 3. Data preparation

The Python notebook reads the Stata file, excludes records missing key survey design variables or the outcome, and excludes non-positive child weights. Variables derived from the same weight-for-height measurement (such as `whz2`, `mod_wasting`, `any_wasting`, and `wast_cat`) are excluded as predictors to avoid outcome leakage.

Some feeding and dietary variables are mainly collected for infants. They should be analyzed in the correct age subpopulation, not treated as ordinary all-child variables.

The current R output reports 22,311 eligible children / 552 cases and a complete-case core model of 22,017 children / 543 cases.

## 4. Why survey design matters

MICS is not a simple random sample. The analysis uses:
- **Weight (`chweight`):** accounts for differences in selection probabilities.
- **Cluster / primary sampling unit (`hh1`):** children from the same cluster may be more alike.
- **Stratum (`strata`):** groups used in the sample design and variance estimation.

The project includes the Stata reference:

```stata
svyset hh1 [pweight = chweight], strata(strata) singleunit(centered)
```

The R script uses the `survey` package to represent the cluster, stratum, and weight. It currently sets `survey.lonely.psu = "adjust"`, which is not automatically identical to Stata's `singleunit(centered)`. Compare estimates between R and Stata.

## 5. Analyses completed so far

### Descriptive and univariate analysis
The Python notebook summarizes the sample and explores severe-wasting prevalence across groups. It reports preliminary patterns involving age, sex, recent illness, wealth, and some infant feeding or antenatal-care variables. These one-predictor analyses do not adjust for all other characteristics.

### Multivariable regression
The existing notebook fits logistic regression models with several predictors. The R output tables on this branch include a survey-design logistic model and a modified-Poisson model.

Current provisional output:
- Design-weighted severe-wasting prevalence: **2.52%**.
- Age OR in the linear core model: **0.80 per additional year** (95% CI 0.74–0.86).
- Girls versus boys: adjusted OR **0.72** (95% CI 0.58–0.88).
- Joint test for division: p = 0.0176.
- Joint tests for wealth, education, maternal age, and toilet category are not significant at 5%.
- Natural-spline age test: p < 0.001, suggesting age is not adequately described by a straight-line effect alone.

These estimates are provisional: the committed outputs were independently reproduced with the R script (R 4.3.3, Linux), but have not yet been compared with Stata. (On the author's Windows machine the local run was blocked by Windows Application Control on `readr.dll`.)

### Infants and young children (ages 0-1)
Feeding and antenatal-care variables exist only for children aged 0-1 (under 2), so they are analysed in a separate subpopulation: the survey design is built on all children and then subset, which keeps the sampling structure (and therefore the standard errors) correct. Dietary diversity (`dds`) is the sum of the seven food-group indicators, so it is never modelled together with them. Univariately, dietary diversity, flesh foods, grains and antenatal care are associated with lower prevalence; after adjustment dietary diversity and flesh foods remain associated while antenatal care weakens (it tracks household wealth). The full infant models have few events per parameter, so a smaller (parsimonious) model is the primary one.

### Sensitivity outcomes
Current files report weighted prevalence of about 10.37% for moderate wasting and 12.88% for any wasting. Verify the outcome definitions and coding against the codebook.

### Prediction with tree-based models and SHAP
Because the inferential and non-linear models did not clearly identify the important variables, a prediction-focused analysis was added in `models.ipynb`. Four tree-based classifiers (Decision Tree, Random Forest, XGBoost, LightGBM) were fitted with their default settings (no hyperparameter tuning). They were evaluated with stratified, PSU-grouped 5-fold cross-validation: every cluster stays entirely in one fold, so the test children come from neighbourhoods the model never saw. Scores reported are ROC AUC, PR AUC, Brier score and the share of cases found in the highest-risk 10% of children, plus ROC and precision-recall curves. Two analyses were run: all children (ages 0-4, 17 predictors) and children aged 0-1 (28 predictors, adding diet, breastfeeding and antenatal care). Missing values were left for the tree models to handle, and outcome-derived columns and identifiers were excluded.

SHAP (a method that splits each prediction into per-variable contributions) was then applied to the best model in each analysis. To avoid explaining the model on data it had memorised, SHAP values were computed out of fold: the model is refitted on each training fold and explained on held-out children.

Main results: the best cross-validated ROC AUC is about 0.54 for all children (LightGBM) and 0.55 for children aged 0-1 (XGBoost), against 0.50 for chance. The models fit the training data almost perfectly but generalise poorly, so they overfit. Label-permutation tests show the best models are above chance but only marginally, and a simple logistic regression with child age and sex (AUC 0.588) beats all four raw trees for all children. SHAP ranks child age first, then mother's age, wealth, division, births and sex; among children under 2, diet (dietary diversity and food groups, about 27% of importance), flesh foods and antenatal care push predicted risk down when higher. Age, sex, wealth, diet and ANC agree with the survey analysis; maternal age does not and is probably overfitting. See `SHAP_results.md` for details.

### Fair model comparison with tuning (nested cross-validation)
The raw-model scores are not directly comparable with the in-sample AUC of 0.635 in `eda.ipynb`, and untuned trees overfit. A like-for-like comparison was therefore added: the same children, the same outer PSU-grouped 5-fold splits and the same preprocessing (imputation and one-hot encoding inside each training fold) for every model. Logistic regression with age and sex only, full unweighted and survey-weighted logistic regression, a more regularised weighted logistic regression, and Decision Tree, Random Forest, XGBoost and LightGBM were compared. The trees were tuned with a small random search using inner 3-fold PSU-grouped cross-validation inside each outer training fold, so the test fold is never used for tuning. Weighted models use the survey weight as a predictive sample weight (this gives no design-based standard errors). Reported are weighted and unweighted pooled out-of-fold ROC AUC, PR AUC, Brier score, share of cases in the top-risk 10%, and calibration intercept and slope; confidence intervals and paired differences come from a bootstrap that resamples whole PSUs (300 resamples).

Main results: for all children the weighted out-of-fold AUC is about 0.58-0.59 for the logistic models, tuned Random Forest and tuned XGBoost, with intervals about ±0.03 wide; none is significantly better than the survey-weighted logistic regression, and age + sex alone scores 0.587. Tuning raises the trees from 0.50-0.54 to 0.55-0.58 but they still do not beat logistic regression. Among children under 2 the tuned Random Forest is nominally best (0.595, +0.025 over weighted logistic, 95% CI 0.000 to 0.052) and age + sex is lower (0.548), so diet, antenatal care and household variables add a small amount of discrimination. Calibration is poor for the complex models (slopes 0.3-0.8; only age + sex is near 1), and Brier scores equal the no-skill baseline. The out-of-fold AUC of the full weighted logistic regression is 0.580, so the earlier in-sample 0.635 was optimistic by about 0.05. The SHAP analysis above used the raw untuned models; repeating it on the tuned models is a sensible next step.

### Interpretable neural-network check
Two PyTorch Neural Additive Models (NAMs) were fitted in `nn.ipynb`, one for ages 0-4 using the same 17 predictors as Analysis A in `models.ipynb`, and one for ages 0-1 using the same 28 predictors as Analysis B. A NAM models the log-odds as an additive sum of one learned function per original variable, so nonlinear effects are possible while variable-level contributions remain directly inspectable. Numeric variables are median-imputed and standardized within each training fold; categorical variables use a dedicated missing/unseen category. The same stratified PSU-grouped 5-fold validation principle is used.

The weighted out-of-fold ROC AUC is 0.492 for all children and 0.522 for ages 0-1, with weighted PR AUC 0.025 and 0.037 respectively. These models do not improve on the existing logistic or tuned tree models. Their contribution rankings are therefore descriptive of unstable weak models and are not interpreted as effect estimates or evidence of causation. This reinforces the conclusion that the current cross-sectional variables contain limited information for individual severe-wasting prediction. Full interpretation is in `nn.md`.

## 6. What the results suggest

Age and sex are the clearest preliminary correlates. The age relationship appears non-linear, so a flexible age term should be considered in the primary model. The division joint test suggests geographic variation. Evidence for wealth, education, recent illness, maternal age overall, and toilet category overall is less conclusive. Isolated category-level results need caution when the overall factor test is not significant or categories are small.

No causal interpretation is supported.

## 7. Limitations and unresolved work

1. **Reproducibility:** the R outputs reproduce (checked on an independent machine). The Python notebooks still contain cells that use undefined variables.
2. **Survey validation:** compare prevalence, standard errors, confidence intervals, coefficients, and tests with Stata `svy:`. Lonely-PSU settings may differ.
3. **Coding:** verify outcome definition, predictor labels, category references, and alternative outcomes against the source codebook.
4. **Age non-linearity:** the spline test suggests the linear age term alone may be too restrictive.
5. **Sparse events:** only 552 cases are reported in the eligible sample; small categories can yield unstable estimates.
6. **Missing data:** the core model excludes incomplete cases. Infant feeding variables have roughly 60% missingness in the full file because they are mainly collected for younger children.
7. **Notebook reproducibility:** some cells use variables not defined in the visible run order; the secondary GLM has very large coefficients and missing standard errors for some sparse terms.
8. **Prediction:** PSU-grouped nested validation, precision-recall metrics, calibration and cluster-bootstrap intervals are now reported (modest discrimination, poor calibration for complex models); external validation and repeated grouped CV are still missing.
9. **Multiple testing and causality:** pre-specify key hypotheses, emphasize intervals, and describe results as associations.

## 8. Next steps

1. Compare key estimates with Stata `svy:`.
2. Verify predictor coding against the codebook.
4. Use flexible age modelling and review sparse categories, missingness, and convergence.
4a. If prediction matters, repeat SHAP on the tuned Random Forest or XGBoost, recalibrate predicted probabilities, use repeated grouped CV with more cases per fold for the under-2 analysis, and keep the simple age + sex logistic regression as the benchmark.
5. Re-run the notebooks from a clean kernel and fix reproducibility/model-diagnostic issues.
6. Update interpretation only after validation.

## Bottom line

The exploratory phase has identified age and sex as important patterns to investigate and has produced an R follow-up script plus output tables. The work is not yet at final-results stage: reproducibility and comparison with Stata are essential next steps.
