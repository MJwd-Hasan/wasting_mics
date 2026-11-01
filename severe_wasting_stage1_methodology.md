# Severe Wasting Prediction — Stage 1: Methodology, Variables and Results

> Companion documentation for `severe_wasting_stage1.ipynb`. This document describes the notebook's executed Stage 1 analysis only. It does not describe later feature-engineering or ensemble stages.

## 1. Study objective

Stage 1 investigates whether routinely available child, maternal and household characteristics can discriminate between children with and without severe wasting. The analysis is conducted separately for two age groups because feeding and some maternal-care variables are only available or meaningful for the youngest children.

The work is predictive and exploratory. Model importance scores and observed associations must not be interpreted as causal effects.

## 2. Dataset and study population

The notebook reads the revised Stata dataset, `MICS-child-ISRC-revised.dta`, and checks that it contains 22,311 records and 552 severe-wasting cases.

| Cohort key | Age definition | Children | Severe-wasting cases | Unweighted prevalence |
|---|---|---:|---:|---:|
| `Y0_full` | `young = 0`: ages 2–4 years | 13,423 | 255 | 1.90% |
| `Y1_full` | `young = 1`: ages 0–1 years (under 2) | 8,888 | 297 | 3.34% |
| `Y1_full+infant` | Same under-2 children, with infant-specific predictors | 8,888 | 297 | 3.34% |
| **Overall** | **All children aged 0–4 years** | **22,311** | **552** | **2.47%** |

The two under-2 datasets contain the same children. They differ only in their predictor sets, which makes it possible to examine whether infant-specific feeding and care information adds predictive value.

The notebook reports substantial class imbalance: only about 2.5% of observations are positive overall. Consequently, a classifier can achieve high accuracy by predicting almost every child as not severely wasted. Accuracy is therefore not used as the main measure of model quality.

## 3. Outcome variable

| Variable | Meaning | Role |
|---|---|---|
| `severe_wasting` | Binary indicator of severe wasting, defined as weight-for-height z-score (WHZ) below -3 | Target / outcome |
| `whz2` | Weight-for-height z-score | Excluded: directly determines the outcome |
| `mod_wasting` | Moderate-wasting indicator | Excluded: derived from the same anthropometric measure |
| `any_wasting` | Any-wasting indicator | Excluded: derived from the same anthropometric measure |
| `wast_cat` | Wasting-category variable | Excluded: derived from the same anthropometric measure |

The target is `severe_wasting = 1` when WHZ < -3 and `0` otherwise. The notebook explicitly excludes WHZ and other wasting-derived variables from the predictor matrix to prevent target leakage. This is essential: a model should predict severe wasting from explanatory information, not from a variable that already encodes the outcome.

## 4. Predictor variables and their interpretation

The notebook begins with a common set of child, maternal and household predictors (`FULL`) and a separate set of infant-specific predictors (`INFANT`). Collinearity pruning then determines the final variables used in each dataset.

### 4.1 Common predictor block

| Notebook variable | Plain-language description | Conceptual domain |
|---|---|---|
| `age_m` | Child's age in months | Child characteristics |
| `female` | Indicator for a female child | Child characteristics |
| `division` | Administrative division of residence | Geographic context |
| `urban` | Urban/rural residence indicator | Household context |
| `wb4` | Mother's/caretaker's age (source variable WB4) | Maternal characteristics |
| `parity_cat` | Categorised parity / number of births | Maternal characteristics |
| `diarrhoea_2w` | Recent diarrhoea, within the preceding two weeks | Child health |
| `cough_2w` | Recent cough, within the preceding two weeks | Child health |
| `breathing_2w` | Recent breathing difficulty / breathing-related symptom | Child health |
| `has_mother` | Whether the child has a mother present/identified in the household record | Caregiver context |
| `fuel_cat` | Household cooking-fuel category | Household environment |
| `water_cat` | Household drinking-water source category | Household environment |
| `toilet_cat` | Household sanitation / toilet-facility category | Household environment |
| `edu_level` | Maternal/caretaker education level | Socioeconomic context |
| `birth_order` | Child's birth order | Maternal / birth history |
| `mother_age_at_birth` | Mother's age when the child was born | Maternal / birth history |
| `water_treated` | Indicator/category for household drinking-water treatment | Household environment |
| `water_boil_filter` | Indicator/category for boiling or filtering drinking water | Household environment |
| `handwash_place` | Place or facility used for handwashing | Household hygiene |
| `handwash_water` | Availability/presence of water at the handwashing location | Household hygiene |
| `floor_quality` | Household floor-material / floor-quality category | Household environment |

**Coding note:** These descriptions explain the analytical meaning indicated by the notebook's variable names. Exact category codes, reference categories and source-question wording should be checked against the MICS recode/codebook before publication. In particular, do not assume that a numeric category code represents a higher or lower level without verifying its labels.

### 4.2 Infant-specific predictor block

These variables are added only for children aged 0–1 years.

| Notebook variable | Plain-language description | Conceptual domain |
|---|---|---|
| `bd9` | Number of times the child ate solid or semi-solid food yesterday (the notebook treats 7 as seven or more) | Feeding frequency |
| `dds` | Dietary diversity score | Complementary feeding |
| `fvs` | Food variety score | Complementary feeding |
| `anc_cat` | Categorised antenatal-care (ANC) visits | Maternal healthcare |
| `bf_status` | Breastfeeding-status category | Infant feeding |
| `bottle` | Bottle-feeding indicator/category | Infant feeding |
| `birth_size` | Reported size of the child at birth | Birth characteristics |
| `suppl_yday` | Whether the child received the relevant supplement yesterday | Infant feeding / supplementation |
| `early_bf` | Early initiation of breastfeeding indicator | Infant feeding |

The infant block contains information that is not generally available or applicable in the same way for older children. It is therefore not imputed into the ages 2–4 cohort.

### 4.3 Variables retained after collinearity pruning

The final feature sets are not identical to the initial lists. The following are the actual predictors used in the executed model comparisons.

**A. `Y0_full`: ages 2–4 (17 predictors)**

`age_m`, `female`, `division`, `urban`, `wb4`, `parity_cat`, `diarrhoea_2w`, `cough_2w`, `breathing_2w`, `has_mother`, `fuel_cat`, `water_cat`, `toilet_cat`, `edu_level`, `water_treated`, `handwash_water`, `floor_quality`.

**B. `Y1_full`: ages 0–1, common predictors (16 predictors)**

`age_m`, `female`, `division`, `urban`, `wb4`, `diarrhoea_2w`, `cough_2w`, `breathing_2w`, `has_mother`, `fuel_cat`, `water_cat`, `toilet_cat`, `edu_level`, `water_treated`, `handwash_place`, `floor_quality`.

**C. `Y1_full+infant`: ages 0–1, common plus infant-specific predictors (24 predictors)**

The 16 predictors in `Y1_full`, plus:

`bd9`, `dds`, `anc_cat`, `bf_status`, `bottle`, `birth_size`, `suppl_yday`, `early_bf`.

The `fvs` variable is not retained in the final infant feature set because it is highly associated with `dds`. This avoids putting two near-redundant measures of dietary variety into the same model.

## 5. Data preparation and multicollinearity analysis

### 5.1 Missing data

The notebook inspects missingness separately by age group before modelling. Many infant-specific variables are structurally unavailable for older children: for example, `dds` and `fvs` are entirely missing in the ages 2–4 cohort. This is why the age cohorts are modelled separately rather than treating all missing infant information as ordinary missing data.

XGBoost and CatBoost are used with their native missing-value handling. The notebook does not apply a general imputation procedure to these tree models.

### 5.2 Association measures

Before fitting predictive models, the notebook examines relationships among predictors without using the outcome:

- Absolute Spearman correlation is used for numeric, binary and ordinal pairs.
- Bias-corrected Cramér's V is used when at least one variable is nominal. Continuous variables are divided into quantile groups for this comparison.
- Variance inflation factors (VIFs) are also calculated after one-hot encoding nominal variables.

The pruning rule removes one variable from a pair with association of at least 0.70. The variable with greater missingness is preferred for removal; if missingness is similar, overall redundancy is considered. `age_m` and `female` are protected. For the infant feature set, the retained common predictors are protected while the infant-specific block is pruned.

### 5.3 Examples of strong associations found

| Cohort / block | Variable pair | Association | Variable removed |
|---|---|---:|---|
| Ages 2–4 | `water_treated` and `water_boil_filter` | 0.864 | `water_boil_filter` |
| Ages 2–4 | `parity_cat` and `birth_order` | 0.831 | `birth_order` |
| Ages 2–4 | `wb4` and `mother_age_at_birth` | 0.784 | `mother_age_at_birth` |
| Ages 2–4 | `handwash_place` and `handwash_water` | 0.769 | `handwash_place` |
| Ages 0–1 | `parity_cat` and `birth_order` | 0.930 | `birth_order` |
| Ages 0–1 | `water_treated` and `water_boil_filter` | 0.884 | `water_boil_filter` |
| Ages 0–1 | `wb4` and `mother_age_at_birth` | 0.789 | `mother_age_at_birth` |
| Infant block | `dds` and `fvs` | 0.972 | `fvs` |

For the under-2 full-plus-infant set, the highest reported VIF fell from 11.90 before pruning to 4.22 after pruning. This suggests that the pruning procedure reduced the most severe redundancy, although it does not prove that all dependence among predictors has disappeared.

## 6. Models compared

Three model approaches are evaluated.

### 6.1 Logistic regression benchmark: age + sex

A simple logistic regression using only `age_m` and `female` is used as a reference model. It answers an important question: do the more complex machine-learning models provide useful predictive improvement over a small, interpretable baseline?

The benchmark is fitted separately within each outer training fold. Its classification threshold is selected from predictions on that training fold, rather than from the outer test fold. This benchmark is a reference, not a fully tuned competing model.

### 6.2 XGBoost

XGBoost is a gradient-boosted decision-tree algorithm. It builds trees sequentially, with each new tree attempting to improve the predictions made by the existing ensemble.

The notebook uses histogram-based tree construction and allows the model to handle missing values natively. Nominal predictors are supplied as integer-coded values. Class imbalance is addressed through the tunable `scale_pos_weight` parameter.

### 6.3 CatBoost

CatBoost is another gradient-boosted tree method. It is supplied with the nominal predictors as categorical features and handles missing values natively.

It is included to compare a model designed to work effectively with categorical predictors against XGBoost. Both tree models are tuned separately within each outer training fold.

## 7. Hyperparameter tuning and validation design

### 7.1 Nested cross-validation

The analysis uses nested, PSU-grouped cross-validation:

1. **Outer evaluation:** five-fold `StratifiedGroupKFold`, stratified by the outcome and grouped by PSU identifier `hh1`.
2. **Inner tuning:** three-fold grouped cross-validation within each outer training partition.
3. **Hyperparameter search:** Optuna uses a Tree-structured Parzen Estimator (TPE) sampler and a median pruner. The objective is mean inner-fold ROC-AUC.
4. **Threshold selection:** the best trial's inner out-of-fold predictions are used to choose the threshold that maximises F1.
5. **Outer evaluation:** the fitted model and selected threshold are applied to the held-out outer fold. These held-out predictions are combined to calculate the reported out-of-fold metrics.

The outer test fold is not used to choose hyperparameters or the XGBoost/CatBoost classification threshold. This reduces optimistic evaluation caused by tuning on the same observations used to report performance.

The folds are created once and saved. Both under-2 feature sets use exactly the same children and folds, so their comparison is paired.

### 7.2 Optuna search

The full run uses 30 Optuna trials per outer fold and model, with up to 600 trees/iterations. The notebook's `QUICK` mode reduces this to two trials and 150 trees/iterations for a smoke test.

The search includes parameters controlling:

- Number of trees / iterations and learning rate.
- Tree depth and minimum child weight (XGBoost).
- L2 regularisation and randomisation / sampling.
- Feature and row subsampling (XGBoost).
- Class-imbalance weight (`scale_pos_weight`).

The selected parameter values are saved in `outputs/stage1_best_params.csv`.

### 7.3 Grouping by PSU

Grouping on `hh1` ensures that records from the same primary sampling unit do not appear in both training and test folds. This is important because children from the same PSU may share environmental and socioeconomic characteristics. Treating them as fully independent across folds could make evaluation overly optimistic.

### 7.4 Important distinction about survey weights

The notebook stores `chweight` and uses it to calculate the survey-weighted ROC-AUC. However, the displayed model-fitting code does **not** pass `chweight` as a sample weight when fitting the logistic regression, XGBoost or CatBoost models. The ordinary pooled AUC, PR-AUC, precision, recall and F1 are also unweighted.

Therefore, these are not fully survey-weighted model fits. The weighted AUC is a weighted evaluation metric, not proof that the model estimation and all reported metrics account for the full complex survey design. This distinction should be made explicit in any paper or presentation.

## 8. Evaluation metrics: what they mean

| Metric | Meaning | How to interpret it in this study |
|---|---|---|
| ROC-AUC | Probability that a randomly selected case receives a higher score than a randomly selected non-case | 0.50 is chance-level ranking; higher is better |
| Fold mean AUC ± SD | Mean and variability of AUC across the five outer folds | Shows how consistent performance is across held-out groups |
| Survey-weighted AUC | ROC-AUC calculated using child sampling weights | Reflects the supplied sampling weights in this evaluation metric |
| PR-AUC | Area under the precision–recall curve | Particularly informative when positive cases are rare |
| Precision | Share of predicted positive children who are truly positive | Low precision means many false alarms |
| Recall | Share of actual severe-wasting cases identified | Higher recall means fewer missed cases |
| F1 | Harmonic mean of precision and recall | Summarises their trade-off at the selected threshold |
| Top-decile capture | Share of all cases that fall among the 10% of children with the highest predicted risk | Measures how concentrated cases are in the highest-risk score group |
| Confusion matrix | Counts of true negatives, false positives, false negatives and true positives | Makes the classification trade-off visible |

Because severe wasting is uncommon, precision and F1 can be low even when a model has some ranking ability. ROC-AUC should not be interpreted in isolation; PR-AUC, recall, precision, calibration and the intended use of predictions also matter.

## 9. Executed model results

The following values are taken from the notebook's executed `stage1_results` table. AUC values are pooled out-of-fold results. Values are rounded to three decimal places.

### 9.1 Discrimination and case capture

| Cohort | Model | Pooled AUC | Fold mean AUC | Fold SD | Weighted AUC | PR-AUC | Top-decile capture |
|---|---|---:|---:|---:|---:|---:|---:|
| Ages 2–4 | Age + sex logistic | 0.512 | 0.539 | 0.062 | 0.523 | 0.020 | 10.6% |
| Ages 2–4 | XGBoost | 0.507 | 0.500 | 0.050 | 0.498 | 0.019 | 7.8% |
| Ages 2–4 | CatBoost | 0.512 | 0.530 | 0.054 | 0.508 | 0.020 | 11.4% |
| Ages 0–1, common features | Age + sex logistic | 0.570 | 0.575 | 0.028 | 0.566 | 0.052 | 20.5% |
| Ages 0–1, common features | XGBoost | 0.532 | 0.570 | 0.014 | 0.531 | 0.042 | 14.1% |
| Ages 0–1, common features | CatBoost | 0.536 | 0.583 | 0.024 | 0.527 | 0.037 | 9.8% |
| Ages 0–1, common + infant | Age + sex logistic | 0.570 | 0.575 | 0.028 | 0.566 | 0.052 | 20.5% |
| Ages 0–1, common + infant | XGBoost | 0.525 | 0.591 | 0.031 | 0.535 | 0.046 | 13.5% |
| Ages 0–1, common + infant | CatBoost | 0.558 | 0.583 | 0.026 | 0.557 | 0.041 | 14.5% |

### 9.2 Classification metrics at the selected thresholds

| Cohort | Model | Precision | Recall | F1 | True positives | False negatives | False positives |
|---|---|---:|---:|---:|---:|---:|---:|
| Ages 2–4 | Age + sex logistic | 0.025 | 0.267 | 0.045 | 68 | 187 | 2,694 |
| Ages 2–4 | XGBoost | 0.019 | 0.325 | 0.036 | 83 | 172 | 4,246 |
| Ages 2–4 | CatBoost | 0.025 | 0.184 | 0.043 | 47 | 208 | 1,862 |
| Ages 0–1, common features | Age + sex logistic | 0.078 | 0.145 | 0.101 | 43 | 254 | 508 |
| Ages 0–1, common features | XGBoost | 0.070 | 0.189 | 0.102 | 56 | 241 | 746 |
| Ages 0–1, common features | CatBoost | 0.059 | 0.242 | 0.095 | 72 | 225 | 1,153 |
| Ages 0–1, common + infant | Age + sex logistic | 0.078 | 0.145 | 0.101 | 43 | 254 | 508 |
| Ages 0–1, common + infant | XGBoost | 0.070 | 0.168 | 0.099 | 50 | 247 | 666 |
| Ages 0–1, common + infant | CatBoost | 0.058 | 0.256 | 0.095 | 76 | 221 | 1,235 |

The confusion-matrix counts are pooled across the outer test folds. Precision, recall and F1 depend on the selected classification threshold; they should not be treated as fixed properties of a model independent of the threshold.

## 10. Interpretation of the results

### 10.1 Children aged 2–4 years

Predictive performance is close to chance for all three approaches:

- The age + sex logistic benchmark and CatBoost both have pooled AUC of 0.512.
- XGBoost has pooled AUC of 0.507 and weighted AUC below 0.50.
- CatBoost captures 11.4% of cases in the highest-risk decile, only slightly above the 10% reference expected if cases were evenly distributed.
- The models produce low precision and F1, with many false-positive classifications.

**Interpretation:** The Stage 1 predictors provide little useful discrimination for severe wasting among children aged 2–4. Neither boosted-tree model demonstrates a meaningful improvement over the simple benchmark.

### 10.2 Children aged 0–1 years: common predictors

The age + sex benchmark performs better than either boosted-tree model on pooled AUC:

- Benchmark pooled AUC: 0.570.
- XGBoost pooled AUC: 0.532.
- CatBoost pooled AUC: 0.536.

CatBoost has a higher fold-mean AUC (0.583) than the benchmark's fold mean (0.575), but its pooled AUC and weighted AUC are lower. A fold average and a pooled out-of-fold AUC are different summaries; the fold average gives each fold equal weight, while the pooled metric is calculated from all pooled predictions.

**Interpretation:** Adding the common child, maternal and household predictors to the age + sex benchmark does not improve overall pooled discrimination in this run.

### 10.3 Children aged 0–1 years: common plus infant-specific predictors

Adding infant-specific predictors changes the relative performance:

- XGBoost pooled AUC decreases from 0.532 to 0.525.
- CatBoost pooled AUC increases from 0.536 to 0.558.
- CatBoost weighted AUC increases from 0.527 to 0.557.
- CatBoost recall increases from 0.242 to 0.256, while precision remains low (0.058).
- The age + sex benchmark remains at pooled AUC 0.570.

The paired pooled-AUC comparisons printed by the notebook are:

| Model | Comparison | AUC difference |
|---|---|---:|
| XGBoost | Ages 2–4 full model minus benchmark | -0.005 |
| XGBoost | Under-2 common model minus benchmark | -0.038 |
| XGBoost | Under-2 common + infant minus benchmark | -0.045 |
| XGBoost | Under-2 common + infant minus common model | -0.007 |
| CatBoost | Ages 2–4 full model minus benchmark | -0.001 |
| CatBoost | Under-2 common model minus benchmark | -0.034 |
| CatBoost | Under-2 common + infant minus benchmark | -0.012 |
| CatBoost | Under-2 common + infant minus common model | +0.022 |

**Interpretation:** Infant-specific variables appear to help CatBoost relative to its own common-feature version, with a pooled AUC increase of 0.022. However, the resulting AUC of 0.558 remains below the age + sex benchmark's 0.570. This is a promising relative improvement within CatBoost, not evidence that the infant feature block produces the best overall predictive model. XGBoost does not benefit from the additional block in pooled AUC.

### 10.4 Why low precision is expected

The positive class is rare. For example, in the under-2 cohort, only 297 of 8,888 children are cases. A model that flags many children as high risk can increase recall but will also generate many false positives. This is visible in CatBoost's under-2 common-plus-infant result: it identifies 76 cases but also produces 1,235 false positives.

The classification threshold determines this trade-off. The reported F1-maximising thresholds are selected within training data, not chosen to represent a clinical or public-health intervention threshold.

## 11. Feature importance

The notebook averages model feature-importance values across the five outer-fold fits. These are model-specific importance scores, normalised within each fitted model and then averaged. They are not regression coefficients, odds ratios, causal effects or directly comparable effect sizes.

### 11.1 Most important variables reported

| Cohort | Model | Leading variables (mean importance) |
|---|---|---|
| Ages 2–4 | XGBoost | `cough_2w` 0.11; `age_m` 0.10; `wb4` 0.10; `female` 0.09; `edu_level` 0.09; `division` 0.09 |
| Ages 2–4 | CatBoost | `age_m` 0.14; `edu_level` 0.10; `cough_2w` 0.09; `female` 0.08; `diarrhoea_2w` 0.07 |
| Ages 0–1, common | XGBoost | `age_m` 0.12; `division` 0.07; `water_cat` 0.07; `floor_quality` 0.07; `wb4` 0.07 |
| Ages 0–1, common | CatBoost | `age_m` 0.36; `wb4` 0.11; `edu_level` 0.09; `water_cat` 0.07; `floor_quality` 0.06 |
| Ages 0–1, common + infant | XGBoost | `age_m` 0.10; `dds` 0.08; `birth_size` 0.08; `anc_cat` 0.07; `bd9` 0.06 |
| Ages 0–1, common + infant | CatBoost | `age_m` 0.19; `dds` 0.08; `bd9` 0.07; `birth_size` 0.07; `wb4` 0.07 |

Age is repeatedly prominent, particularly in the under-2 common-feature CatBoost model. Dietary diversity (`dds`), meal frequency (`bd9`), birth size and ANC category appear among the leading infant-block predictors.

These patterns suggest where the fitted algorithms are finding predictive information. They do not show that changing a particular exposure would change a child's risk. Correlated predictors can also share or redistribute importance.

## 12. Overall conclusion

The Stage 1 analysis provides three main findings:

1. **Prediction is weak for children aged 2–4.** All tested models have pooled AUC close to 0.50.
2. **The under-2 cohort contains more predictive signal than the older cohort in this analysis.** The age + sex benchmark achieves pooled AUC 0.570, although this is still modest discrimination.
3. **Infant-specific variables improve CatBoost relative to its own common-feature model, but not beyond the age + sex benchmark.** The CatBoost pooled AUC rises by 0.022 to 0.558 after adding the infant block, while the benchmark remains at 0.570.

The most defensible Stage 1 conclusion is therefore not that XGBoost or CatBoost outperforms logistic regression. Rather, the simple age + sex benchmark remains competitive or better on pooled AUC, and infant-specific predictors provide a modest improvement for CatBoost that warrants further investigation.

No model in this stage is sufficiently discriminative to be presented as a validated individual-level screening tool.

## 13. Limitations and points to address

1. **Weak discrimination:** AUC values are mostly between 0.50 and 0.57. Predictive performance is limited.
2. **Rare outcome:** There are only 552 cases overall, with 255 in the ages 2–4 group and 297 in the under-2 group. This limits the precision and stability of model comparisons.
3. **Survey-weight handling:** `chweight` is used for weighted AUC but is not passed into model fitting in the executed code. The analysis should not be described as fully survey-weighted machine learning.
4. **Survey design:** PSU grouping is respected during cross-validation, but the reported metrics do not provide full design-based uncertainty estimates for every model metric.
5. **Benchmark threshold:** The age + sex logistic benchmark selects its threshold from predictions on the same outer-training data used to fit it. This differs from the inner out-of-fold threshold selection used for XGBoost and CatBoost and may make its threshold-dependent classification metrics optimistic. A stricter comparison would select the benchmark threshold using inner grouped out-of-fold predictions as well.
6. **Feature importance:** Tree-based importance is model-dependent and does not establish independent associations or causation. Correlation among predictors complicates interpretation.
7. **Category coding:** The exact labels and reference categories should be verified against the MICS codebook before reporting variable-level interpretations.
8. **External validation:** The models have not been evaluated on an independent survey or a separate external sample.
9. **Calibration:** AUC measures ranking, not whether predicted probabilities correspond to observed risks. Calibration analysis is needed before using probabilities for decisions.
10. **Stage scope:** This notebook is Stage 1. Feature engineering and ensemble modelling are explicitly outside its scope.

## 14. Reproducibility and generated outputs

The notebook writes its results under the `outputs/` directory:

| Output | Purpose |
|---|---|
| `outputs/feature_sets.json` | Retained predictor names for each cohort |
| `outputs/fold_assignment.csv` | Reusable outer-fold assignments |
| `outputs/oof_Y0_full_XGBoost.csv` | Out-of-fold XGBoost predictions for ages 2–4 |
| `outputs/oof_Y0_full_CatBoost.csv` | Out-of-fold CatBoost predictions for ages 2–4 |
| `outputs/oof_Y1_full_XGBoost.csv` | Out-of-fold XGBoost predictions for under-2 common features |
| `outputs/oof_Y1_full_CatBoost.csv` | Out-of-fold CatBoost predictions for under-2 common features |
| `outputs/oof_Y1_full+infant_XGBoost.csv` | Out-of-fold XGBoost predictions for under-2 common + infant features |
| `outputs/oof_Y1_full+infant_CatBoost.csv` | Out-of-fold CatBoost predictions for under-2 common + infant features |
| `outputs/stage1_results.csv` | Summary performance metrics |
| `outputs/stage1_best_params.csv` | Best Optuna hyperparameters by cohort, model and outer fold |

The notebook also displays association / collinearity diagnostics, ROC curves, confusion matrices and feature-importance summaries.

---

*Prepared from the code and saved execution outputs in `severe_wasting_stage1.ipynb`. Numerical results in this document describe that committed notebook run; rerunning the notebook with different data, package versions, randomisation or settings may produce different results.*
