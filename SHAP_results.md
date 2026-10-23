# Tree-Based Prediction and SHAP Results

Results from [`models.ipynb`](models.ipynb): four tree-based classifiers with **default (untuned) settings**, 5-fold cross-validation, ROC AUC and ROC curves, then SHAP explanations. The outcome is `severe_wasting` (WHZ < -3; 2.47% of 22,311 children).

## Bottom line

- **Prediction is weak.** The best raw model reaches a mean cross-validated ROC AUC of **0.542** (all children) and **0.552** (children aged 0-1), against 0.500 for chance. Permutation tests show this is above chance (p = 0.020 and 0.039) but only marginally, and not usable as a screening tool.
- **The raw models overfit.** Training AUC is 0.97-1.00 while held-out AUC is 0.50-0.55. A two-variable logistic regression using child age and sex (AUC 0.588) beats every raw tree model in the all-children analysis.
- **SHAP agrees with the survey analysis on the main drivers:** child age, sex, wealth, and (in children under 2) diet and antenatal care. It also ranks maternal age and some household variables high, which the inference did not support and which probably reflects overfitting.
- These are associations learned by weak models on cross-sectional data; they are not causal effects.

## What was done

| Item | Choice |
|---|---|
| Models | `DecisionTreeClassifier`, `RandomForestClassifier`, `XGBClassifier`, `LGBMClassifier`, all with default hyperparameters |
| Settings changed | Only `random_state=42`, `n_jobs=2` and silent logging (for a low-end laptop) |
| Cross-validation | Stratified group 5-fold, grouped by PSU (`hh1`), so no PSU is in both training and test folds; every child is predicted once, out of fold |
| Analysis A | All children aged 0-4: 22,311 children, 552 cases, 17 predictors (no feeding variables) |
| Analysis B | Children aged 0-1 (under 2): 8,888 children, 297 cases, 28 predictors (adds dietary diversity, the 7 food groups, breastfeeding, bottle feeding, ANC) |
| Excluded | Outcome-derived columns (`whz2`, `mod_wasting`, `any_wasting`, `wast_cat`); identifiers and design variables; duplicates of other predictors (`young`, `any_illness`, `mage_cat`, `parity_cat`, `fvs`, `bd9`) |
| Missing values | Left as they are; the tree models handle them natively, so no rows are dropped |
| Weights | Models are trained unweighted (prediction in this sample) |
| SHAP | `TreeExplainer`, out of fold: the best model is refitted on each training fold and explained on 1,000 held-out children per fold (5,000 children) |

Total run time for the whole notebook was about 4 minutes on a single CPU core with 4 GB of RAM.

## Cross-validated prediction results

Values are mean ± SD across the 5 folds. No-skill references: ROC AUC 0.500, PR AUC = prevalence (0.025 in A, 0.033 in B), Brier 0.024 (A) and 0.032 (B), top-10% capture 0.100.

### Analysis A: all children aged 0-4

| Model | ROC AUC | PR AUC | Brier | Top-10% capture | Train ROC AUC | Fit time (s) |
|---|---|---|---|---|---|---|
| LightGBM | 0.542 ± 0.031 | 0.033 ± 0.005 | 0.025 ± 0.000 | 0.138 ± 0.012 | 0.966 ± 0.005 | 0.3 |
| Random Forest | 0.534 ± 0.021 | 0.028 ± 0.001 | 0.026 ± 0.000 | 0.120 ± 0.010 | 1.000 ± 0.000 | 1.5 |
| XGBoost | 0.526 ± 0.023 | 0.032 ± 0.006 | 0.025 ± 0.000 | 0.131 ± 0.027 | 0.984 ± 0.003 | 0.2 |
| Decision Tree | 0.503 ± 0.007 | 0.025 ± 0.001 | 0.062 ± 0.004 | 0.114 ± 0.032 | 1.000 ± 0.000 | 0.1 |

### Analysis B: children aged 0-1

| Model | ROC AUC | PR AUC | Brier | Top-10% capture | Train ROC AUC | Fit time (s) |
|---|---|---|---|---|---|---|
| XGBoost | 0.552 ± 0.044 | 0.045 ± 0.012 | 0.035 ± 0.001 | 0.145 ± 0.039 | 1.000 ± 0.000 | 0.1 |
| Random Forest | 0.547 ± 0.042 | 0.048 ± 0.018 | 0.034 ± 0.001 | 0.131 ± 0.057 | 1.000 ± 0.000 | 0.7 |
| LightGBM | 0.544 ± 0.025 | 0.047 ± 0.008 | 0.033 ± 0.000 | 0.128 ± 0.025 | 0.998 ± 0.001 | 0.2 |
| Decision Tree | 0.503 ± 0.012 | 0.034 ± 0.001 | 0.075 ± 0.002 | 0.118 ± 0.048 | 0.999 ± 0.002 | 0.0 |

How to read the table:

- **Train ROC AUC** near 1.00 with test AUC near 0.50 shows overfitting. Fully grown default trees memorise the training children.
- **Top-10% capture** is the share of a fold's cases found among the 10% of children with the highest predicted risk. 10% is chance; the best models reach 13.8% (A) and 14.5% (B).
- The default **Decision Tree** is no better than chance and has a much worse Brier score because its predicted probabilities are almost all 0 or 1.

### ROC and precision-recall curves

![ROC and PR, all children](figures/ml_roc_pr_all_children.png)
![ROC and PR, children aged 0-1](figures/ml_roc_pr_infants.png)

The ROC curves of all models hug the diagonal. Per-fold curves (fold-to-fold variability, which is large, especially in B with only about 60 cases per fold):

![ROC per fold, all children](figures/ml_roc_folds_all_children.png)
![ROC per fold, children aged 0-1](figures/ml_roc_folds_infants.png)

### Reference checks

Cross-validated logistic regression with the same folds (reference only, not one of the four requested models):

| analysis | reference model | ROC AUC |
|---|---|---|
| A: all children | Logistic regression: ub2 | 0.584 ± 0.025 |
| A: all children | Logistic regression: ub2 + female | 0.588 ± 0.025 |
| B: ages 0-1 | Logistic regression: ub2 | 0.542 ± 0.032 |
| B: ages 0-1 | Logistic regression: ub2 + female | 0.555 ± 0.040 |

Label-permutation test (50 shuffles of the outcome; best model in each analysis):

| analysis | best model | observed mean AUC | chance mean AUC | chance SD | chance max | permutation p-value |
|---|---|---|---|---|---|---|
| A: all children | LightGBM | 0.542 | 0.499 | 0.016 | 0.533 | 0.02 |
| B: ages 0-1 | XGBoost | 0.552 | 0.497 | 0.026 | 0.563 | 0.039 |

In Analysis A the best model beats all 50 shuffled runs (largest chance AUC 0.533, p = 0.020); in Analysis B one shuffled run scored higher (largest chance AUC 0.563, p = 0.039). Both are above chance, but the margin is small.

## SHAP analysis

SHAP values are on the log-odds scale. The **share** column is each variable's share of the total mean |SHAP|; **direction** is the Spearman correlation between a variable's value and its SHAP value (positive = higher values raise predicted risk; negative = higher values lower it). For unordered codes (`division`, `water_cat`, `toilet_cat`, `fuel_cat`) the direction is not meaningful, because the code numbers have no order; read direction together with the plots.

### Analysis A: all children (LightGBM)

| rank | Variable | Meaning | mean abs SHAP | share of total | direction |
|---|---|---|---|---|---|
| 1 | ub2 | Age of child in completed years | 0.287 | 17.4% | -0.88 |
| 2 | wb4 | Age of mother/caretaker | 0.217 | 13.1% | +0.11 |
| 3 | wealth | Wealth index quintile | 0.141 | 8.6% | -0.61 |
| 4 | division | Division | 0.126 | 7.6% | -0.36 |
| 5 | cm11 | Total number of live births | 0.12 | 7.3% | -0.33 |
| 6 | female | Child is female | 0.114 | 6.9% | -0.79 |
| 7 | water_cat | Drinking water source | 0.112 | 6.8% | -0.67 |
| 8 | fuel_cat | Cookstove fuel category | 0.105 | 6.4% | +0.15 |
| 9 | edu_level | Mother/caretaker education | 0.089 | 5.4% | -0.06 |
| 10 | toilet_cat | Toilet type | 0.089 | 5.4% | -0.25 |

![SHAP beeswarm, all children](figures/ml_shap_beeswarm_all_children.png)
![SHAP bar, all children](figures/ml_shap_bar_all_children.png)
![SHAP dependence, all children](figures/ml_shap_dependence_all_children.png)

- **Child age** is the top predictor (17% of the total), with younger children pushed toward higher risk (direction -0.88). This matches the survey analysis (OR 0.80 per year).
- **Sex:** being female lowers predicted risk (direction -0.79), matching the survey analysis (OR 0.72).
- **Wealth and urban area:** higher wealth and urban residence lower predicted risk (directions -0.61 and -0.58). The survey models found only a weak wealth trend, so these variables may share information.
- **Recent illness:** cough and diarrhoea raise risk (directions +0.31, +0.34), in line with the univariate results.
- **Mother's age (`wb4`)** ranks second, but its direction is almost flat (+0.11) and the earlier inference found no clear maternal-age effect. It is a numeric variable with 35 distinct values, which tree models over-use when they overfit; treat it with caution.

### Analysis B: children aged 0-1 (XGBoost)

| rank | Variable | Meaning | mean abs SHAP | share of total | direction |
|---|---|---|---|---|---|
| 1 | wb4 | Age of mother/caretaker | 0.45 | 10.2% | +0.17 |
| 2 | dds | Dietary diversity score | 0.351 | 8.0% | -0.44 |
| 3 | division | Division | 0.338 | 7.6% | -0.31 |
| 4 | wealth | Wealth index quintile | 0.307 | 6.9% | -0.61 |
| 5 | fg_flesh | Ate flesh foods yesterday | 0.253 | 5.7% | -0.77 |
| 6 | anc_cat | ANC visits category | 0.243 | 5.5% | -0.63 |
| 7 | water_cat | Drinking water source | 0.234 | 5.3% | -0.70 |
| 8 | edu_level | Mother/caretaker education | 0.223 | 5.1% | -0.06 |
| 9 | fuel_cat | Cookstove fuel category | 0.213 | 4.8% | -0.17 |
| 10 | cm11 | Total number of live births | 0.201 | 4.6% | -0.42 |

![SHAP beeswarm, ages 0-1](figures/ml_shap_beeswarm_infants.png)
![SHAP bar, ages 0-1](figures/ml_shap_bar_infants.png)
![SHAP dependence, ages 0-1](figures/ml_shap_dependence_infants.png)

SHAP importance by variable group (Analysis B):

| Group | Share of total mean \|SHAP\| |
|---|---|
| Household and maternal (wealth, division, water, fuel, toilet, education, mother's age, births, urban, etc.) | 51.2% |
| Diet (`dds` and the seven food groups) | 26.7% |
| Recent illness | 6.7% |
| Child age and sex | 6.5% |
| Antenatal care | 5.5% |
| Breastfeeding and bottle | 3.3% |

- **Dietary diversity (`dds`)** and **flesh foods (`fg_flesh`)** are among the leading predictors, with higher values lowering predicted risk (directions -0.44 and -0.77). **ANC** also lowers risk with more visits (-0.63). This agrees with the survey-based infant analysis, where `dds`, `fg_flesh` and ANC were the main infant signals.
- `dds` is the sum of the seven food-group indicators, so SHAP credit is shared between them; the 26.7% diet share is the more reliable summary than any single food variable.
- Breastfeeding status and bottle feeding contribute little (3.3% together), matching the survey analysis.
- In this subset child age has only two values (0 or 1), so its importance is small by construction.

## How to interpret the SHAP results

1. **The models are close to chance.** Out-of-fold AUC is 0.54-0.55, so the SHAP values explain what these overfit models learned, not stable risk factors. Individual SHAP values reach ±1.5 to ±2 log-odds even though the models barely separate cases from non-cases, which is a sign of fitted noise.
2. **Agreement with the survey analysis** (age, sex, wealth, diet, ANC, illness direction) is the most trustworthy part of this output.
3. **Disagreement** (mother's age, fuel and water category, number of births) is more likely overfitting or proxying for geography and wealth than real signal.
4. **No causal claim** is supported: the data are cross-sectional, diet is a single 24-hour recall, and sick or wasted children may eat less.

## Limitations

- Untuned models were requested; heavy overfitting is the expected result, and regularised or tuned models (shallower trees, fewer leaves, early stopping, class weighting) could do somewhat better.
- Only about 60 cases per test fold in Analysis B, so fold-to-fold variation is large.
- SHAP was computed on a 5,000-child out-of-fold sample, not all children.
- Models are unweighted, so results describe this sample, not the national population.
- Integer-coded categories (division, water, fuel, toilet) are treated as ordered numbers by the trees.

## Files

| File | Content |
|---|---|
| [`models.ipynb`](models.ipynb) | The executed notebook: setup, cross-validation, ROC curves, reference checks, SHAP |
| `outputs/ml_cv_summary_*.csv`, `outputs/ml_cv_fold_metrics_*.csv` | Cross-validation summary and per-fold metrics for Analysis A (`all_children`) and B (`infants`) |
| `outputs/ml_reference_logistic.csv`, `outputs/ml_permutation_check.csv` | Reference logistic regression and permutation test |
| `outputs/ml_shap_importance_*.csv` | Mean absolute SHAP, share and direction for every variable |
| `figures/ml_*.png` | ROC/PR curves, per-fold ROC curves, SHAP beeswarm, bar and dependence plots |

## Run it on a low-end laptop

```bash
pip install pandas numpy scikit-learn xgboost lightgbm shap matplotlib scipy
jupyter nbconvert --to notebook --execute models.ipynb
```

Settings that control the load are at the top of the notebook: `N_JOBS = 2` (use 1 on a very slow machine), `N_SPLITS = 5` and `SHAP_N_PER_FOLD = 1000` (use 500 to halve the SHAP work). The whole notebook took about 4 minutes on one CPU core with 4 GB of RAM.
