# models_m.ipynb — Methods and workflow in simple language

## 1. What this notebook is trying to do

This notebook tests whether information about a child, their mother or caregiver, and their household can help rank children by their likelihood of **severe wasting**.

The outcome is `severe_wasting`:

- `1` means the child is severely wasted.
- `0` means the child is not severely wasted.
- The notebook checks that this outcome agrees exactly with weight-for-height z-score (WHZ) below -3.

This is a **prediction** exercise. It asks how well a model can distinguish children with and without severe wasting in data it has not seen. It does not prove that a predictor causes severe wasting.

The notebook deliberately compares complicated machine-learning models with simpler logistic-regression baselines. A complicated model is useful only if it performs reliably better on new data.

## 2. Data used and preparation

The main input is `MICS-child-ISRC.dta`, a Stata dataset. The notebook:

1. Loads the data and its variable labels.
2. Checks that required columns are present.
3. Checks that important variables use expected codes. For example, binary variables should contain only 0 and 1, and division should use the expected category codes.
4. Checks missing values and identifies categories with very few children or severe-wasting cases.
5. Removes records missing the outcome or essential survey-design information (`hh1`, `strata`, or `chweight)), and removes records with a non-positive child weight.
6. Confirms that the outcome is binary and agrees with the WHZ cut-off.

In the saved run, this left **22,311 children and 552 severe-wasting cases**. The unweighted proportion of cases was 2.47%; after applying child survey weights, the estimated proportion was 2.52%.

### Why some columns are not allowed to predict the outcome

A model must not be given information that already contains the answer. That would make its performance look better than it really is. This is called **data leakage**.

The notebook therefore excludes:

- `whz2`, `mod_wasting`, `any_wasting`, and `wast_cat`, because they are calculated from the same anthropometric measurement as the severe-wasting outcome.
- Identification columns such as `child_id`, `hh_id`, `mother_id`, `hh2`, and `ln). These identify records; they are not meaningful risk predictors.
- `hh1` (the sampling cluster), `hh7a` (district), `strata` (sampling stratum), and `chweight` (survey weight). These are used for validation, grouping, or weighting, not as ordinary predictors.

The WHZ value is used separately in an auxiliary experiment. In that experiment, a model predicts WHZ using training data only; the observed WHZ of a test child is never supplied to a severe-wasting classifier.

## 3. Three age groups are analysed separately

The notebook does not assume that the same information is available or equally useful at every age. It creates three cohorts:

| Cohort | Age definition | Children | Severe-wasting cases |
|---|---|---:|---:|
| All children | Ages 0–4 years | 22,311 | 552 |
| Under 2 | Completed ages 0–1 years | 8,888 | 297 |
| Ages 2–4 | Completed ages 2–4 years | 13,423 | 255 |

Dietary diversity, food-group, breastfeeding, bottle-feeding, and antenatal-care variables are available for the younger-child group, but are largely missing for older children because they were not collected for them in the same way. The notebook therefore gives those variables only to the under-2 models. It does not fill in unavailable older-child information with invented values.

The 2–4 cohort has relatively few cases in each validation fold, so its model comparisons are especially uncertain.

## 4. Comparing three feature sets

A **feature** is an input variable given to a model. The notebook defines three groups of possible predictors.

### FS0 — Original variables

This is the starting set: variables already present in the dataset.

For all children and ages 2–4, FS0 has 17 predictors:

- Child age in completed years and sex.
- Urban or rural residence and division.
- Household wealth, maternal/caregiver education and age, number of live births, and marital status.
- Drinking water, toilet and cooking-fuel categories.
- Electricity and health insurance.
- Recent diarrhoea, cough and breathing difficulty.

For children under 2, FS0 also includes 11 infant-specific variables:

- Dietary diversity score (`dds`).
- Seven food-group indicators (grains, legumes, dairy, flesh foods, eggs, vitamin-A-rich fruit/vegetables, and other fruit/vegetables).
- Breastfeeding status and bottle feeding.
- Antenatal-care category.

That makes **28 predictors** in the under-2 FS0 set. The seven food-group indicators describe what the child ate on the previous day. The dietary diversity score summarises the number of food groups consumed.

### FS1 — Original plus engineered variables

FS1 keeps FS0 and adds variables calculated from existing columns. Examples include:

- A count of recent illness indicators.
- An approximate maternal age at the child's birth (mother's age minus child's age in completed years).
- Counts of under-five children in the household and linked to the mother.
- A simple WASH score based on the water and toilet categories.
- A simple asset score based on electricity, insurance and urban residence.
- Interactions such as wealth × urban residence, education × wealth, age × sex, age × wealth, and age × illness.
- Indicators showing when selected maternal/caregiver variables are missing.

For under-2 children, FS1 additionally creates dietary-diversity groupings and thresholds, a count of non-grain food groups, diet-by-age, a breastfeeding-by-bottle category, ANC-by-wealth, and meal-frequency (`bd9`) with a missingness indicator.

FS1 contains **32 predictors** for all children and ages 2–4, and **52 predictors** for under-2 children.

These engineered variables are summaries or combinations of existing information; they are not new survey measurements. The WASH category mappings and other heuristic constructions should be checked against the MICS codebook before final publication.

### FS2 — Extended, post-hoc variables

FS2 was designed to add age in months and an under-six-month indicator; for under-2 children it also adds reported small size at birth, early breastfeeding, and facility delivery.

These variables were considered after earlier exploration of this dataset. For that reason, FS2 is labelled **post hoc**: results from it would need extra caution because the variables were not fixed before looking at the data.

**FS2 was not run in the saved notebook execution.** The revised Stata file was found, but its shared rows/columns did not pass the notebook's equality checks, so the extra variables were not merged. The reported model comparisons are therefore FS0 and FS1 only.

| Cohort | FS0 | FS1 | FS2 |
|---|---:|---:|---:|
| All children | 17 | 32 | 34 (not run) |
| Under 2 | 28 | 52 | 57 (not run) |
| Ages 2–4 | 17 | 32 | 34 (not run) |

## 5. How variables are prepared for modelling

Different kinds of variables need different preparation:

- **Nominal categories** have labels but no natural order, such as division, water source, toilet type, fuel type, and breastfeeding status. The notebook uses one-hot encoding, which creates a separate 0/1 column for each category.
- **Ordered variables**, such as wealth quintile and education level, are treated as ordered numeric values.
- **Binary variables** are already represented as 0/1.
- **Numeric variables**, such as maternal age or a count, remain numeric.

Missing numeric, ordered and binary values are filled using the median calculated from the training data. Numeric variables are standardised where the model needs it. One-hot encoding and imputation are placed inside a pipeline so that the held-out fold cannot influence the preparation of the training data.

This is important: if we calculate medians or scaling values using the full dataset before splitting, information from the test data can leak into training.

## 6. Why the notebook uses grouped, nested cross-validation

The notebook uses **cross-validation** to estimate how a model may perform on children it has not seen.

### Why group by PSU?

MICS samples children through a clustered design. Children in the same primary sampling unit (PSU, represented by `hh1`) may share local conditions.

If children from one PSU appear in both training and test data, a model may partly recognise the same local environment. That can make the test score too optimistic.

The notebook uses **stratified, PSU-grouped five-fold cross-validation**:

1. The PSUs are divided into five groups (folds).
2. All children from a PSU stay together in one fold.
3. The model is trained on four folds.
4. It predicts the children in the remaining fold, which it has not seen.
5. This is repeated until every child has a prediction from a model that did not train on that child's PSU.

The stratification step tries to keep the outcome distribution reasonably balanced across folds while respecting the PSU groups.

### Why is it nested?

The notebook also tunes model settings. If settings are chosen using the same fold used for final evaluation, the score can become optimistic.

To avoid this, it uses two loops:

- **Outer loop:** five PSU-grouped folds. These are used to produce the final held-out predictions.
- **Inner loop:** within each outer training sample, three PSU-grouped folds are used to choose model settings.

The outer test fold is not used to tune the model. Preprocessing, tuning, threshold selection and probability calibration are learned using the training portion only.

The experiment is repeated with three random seeds (42, 43 and 44). This checks whether the result changes when the fold assignments change.

## 7. Models compared

The notebook compares simple reference models with more flexible methods.

### Baselines

- **Prevalence-only model:** predicts the same overall event rate for everyone. This is a basic reference, not a useful individual ranking model.
- **Age + sex logistic regression:** a deliberately simple benchmark using only child age and sex.
- **Full logistic regression:** uses the available feature set, with ordinary or survey-weighted fitting.
- **Regularised (ridge) logistic regression:** shrinks coefficients to reduce the effect of too many or unstable predictors.

### Tuned machine-learning models

- **Elastic-net logistic regression:** logistic regression with regularisation that can reduce or remove weak predictor effects.
- **Decision tree:** makes a sequence of simple if/then splits.
- **Random forest:** combines many decision trees to reduce dependence on one tree.
- **XGBoost and LightGBM:** boosted-tree methods that build trees sequentially to improve on earlier errors.
- **CatBoost:** another boosted-tree method. It is optional and is skipped if the package is unavailable.
- **Simple ensemble:** averages predicted probabilities from selected tuned models.

The tuning process tests a small set of candidate settings. It includes conservative settings and random candidates favouring relatively shallow trees, larger minimum leaf sizes and regularisation. The notebook also tests three fitting schemes: ordinary fitting, survey-weighted fitting, and case-balanced fitting. The inner folds decide which scheme works best for each model family.

A Platt-calibrated version is also considered for tuned models. Calibration adjusts predicted probabilities using training-only inner-fold predictions; it does not use the outer test outcomes.

### Auxiliary WHZ experiment

A separate ridge model predicts continuous WHZ from training-fold predictors. Its predictions are then used in three ways: as a reversed risk score, as an estimated normal-tail probability below WHZ -3, and as an input to a stacked logistic model alongside age and sex.

This is kept separate to prevent the actual test child's WHZ from leaking into the severe-wasting prediction.

## 8. How model performance is measured

Accuracy is misleading when the outcome is rare. In this dataset, about 97.5% of children are not severe-wasting cases. A model that predicts “not severe wasting” for everyone would appear about 97.5% accurate but would identify no cases.

The notebook therefore reports several measures:

- **ROC-AUC:** how well the model ranks a randomly selected case above a randomly selected non-case. Around 0.50 is chance-level ranking; higher is better.
- **PR-AUC (average precision):** focuses more on finding the relatively rare positive cases. It should be compared with the weighted prevalence, not interpreted in isolation.
- **Brier score:** measures the average squared difference between predicted probabilities and actual outcomes. Lower is better.
- **Calibration slope and intercept:** check whether predicted probabilities are too extreme or systematically too high/low. A slope near 1 is generally desirable.
- **Top-decile case capture:** among the 10% of children assigned the highest risk, what share of all cases is found? Around 10% is the rough no-ranking benchmark.
- **Precision, recall and F-scores:** describe the trade-off at a chosen risk threshold. The threshold for tuned models is selected inside the training data by maximising weighted F2, then applied to the held-out fold.

Both weighted and unweighted metrics are reported. The weighted metrics use `chweight` as a **predictive sample weight** so children contribute according to their survey weight. This is not the same as a full design-based survey analysis with design-based standard errors.

## 9. Checking overfitting and uncertainty

The notebook includes several checks:

1. **Training versus held-out scores:** a large difference suggests the model has memorised the training data rather than learned patterns that transfer to new PSUs.
2. **Tuning optimism:** compares the best inner-fold score with the outer held-out score. Selecting the best of many settings can make the inner score look better than future performance.
3. **Stability across seeds:** checks whether the model's performance is consistent across the three fold assignments.
4. **PSU cluster bootstrap:** resamples whole PSUs, rather than individual children, 300 times in the standard run. It produces uncertainty intervals for AUC and paired differences between models. The same resampled PSUs are used for each model so comparisons are paired.
5. **Permutation check:** shuffles the outcome labels and repeats the held-out prediction evaluation for the selected tuned model. If shuffled labels produce similar scores, the original result may not contain much signal. The standard run uses 30 permutations.

These checks do not eliminate all uncertainty. The bootstrap does not repeat the full tuning process, and the same out-of-fold predictions are used for model selection and reporting. An untouched external dataset would provide a stronger final test.

## 10. How the final model is selected

The notebook uses a rule that favours a simple model unless a more complicated one shows a reliable improvement.

A candidate is treated as a reproducible improvement over age + sex logistic regression only if:

1. Its paired AUC improvement is positive in every random seed; and
2. The 95% PSU-bootstrap confidence interval for that improvement excludes zero.

If no candidate meets both conditions, the notebook recommends age + sex logistic regression. A larger apparent gain that fails these checks is labelled provisional, not a confirmed improvement.

This rule matters because trying many models makes it easy for one to look best by chance.

## 11. SHAP: understanding the selected tree models

SHAP is an explanation method. It estimates how much each feature contributes to a model's prediction.

The notebook calculates SHAP values only for the best tuned tree family in each primary analysis, and it does so out of fold: each fold's model is fitted on its training PSUs and explained on held-out children.

SHAP is used to describe which variables the fitted model relies on. It does **not** prove that those variables cause severe wasting. It is also not used to select predictors or choose the final model.

In the saved run, SHAP was available. The leading shares were:

- **All children:** age × wealth (22.0%), division (11.0%), age × sex (8.3%), and sex (6.6%).
- **Under 2:** dietary diversity score (10.9%), flesh foods (8.3%), education × wealth (7.3%), ANC category (7.3%), and missingness of meal frequency (7.0%).

These are importance shares within the selected fitted models. They should be interpreted cautiously because overall predictive performance is weak.

## 12. What happened in the saved run?

The committed notebook outputs show the following:

- The standard profile used seeds 42, 43 and 44, five outer folds, three inner folds, four tuning configurations per model family, 300 PSU-bootstrap replicates and 30 permutations.
- XGBoost, LightGBM and SHAP were available. CatBoost was not installed and was skipped.
- FS0 and FS1 were run for all three cohorts. FS2 was not run because the revised data file failed the shared-data checks.
- The model-selection rule recommended **age + sex logistic regression** for all three cohorts and both executed feature sets.

The strongest candidate AUCs were:

| Cohort | Feature set | Age + sex AUC | Highest candidate AUC | Candidate | Was the gain confirmed? |
|---|---|---:|---:|---|---|
| All children | FS0 | 0.584 | 0.588 | Auxiliary WHZ stacked logistic | No |
| All children | FS1 | 0.584 | 0.587 | Auxiliary WHZ stacked logistic | No |
| Under 2 | FS0 | 0.548 | 0.576 | Tuned XGBoost | No — provisional |
| Under 2 | FS1 | 0.548 | 0.583 | Weighted ridge logistic | No — provisional |
| Ages 2–4 | FS0 | 0.531 | 0.540 | Auxiliary WHZ stacked logistic | No |
| Ages 2–4 | FS1 | 0.531 | 0.539 | Auxiliary WHZ stacked logistic | No |

An AUC of 0.50 is approximately chance-level ranking. Values around 0.53–0.58 indicate only modest discrimination. In the under-2 group, some models had gains of roughly 0.03 AUC, but the gains did not pass the notebook's reproducibility and uncertainty rule. They are interesting leads for further study, not established improvements.

The permutation checks showed that the selected FS1 model for all children and the under-2 cohort performed better than most shuffled-label runs, while the ages 2–4 result did not. This is a pipeline sanity check, not proof of useful predictive performance.

## 13. Important limitations

- **Weak prediction:** the models distinguish cases from non-cases only modestly better than chance. They are not suitable for individual diagnosis, screening decisions or deployment.
- **Rare outcome:** severe-wasting cases are a small share of the sample, which makes model fitting and evaluation difficult.
- **Small subgroup event counts:** results for under-2 and ages 2–4 are less stable because each fold contains relatively few cases.
- **Survey weights:** weighted predictive metrics are reported, but they are not full design-based inference. The PSU bootstrap does not fully reproduce every aspect of the MICS sampling design.
- **Post-hoc feature set:** FS2 was not run; if run later, its exploratory origin should be made clear.
- **Feature coding:** WASH and asset scores are heuristic and need codebook confirmation. Maternal age at birth is approximate because age is measured in completed years.
- **No external validation:** the models have not been tested on an independent survey or a separate population.
- **No causal conclusions:** SHAP values and predictive associations do not show that changing a feature would change a child's nutritional status.

## 14. How to run the notebook

1. Place `MICS-child-ISRC.dta` beside `models_m.ipynb`.
2. Install the main packages: `pandas`, `numpy`, `scipy`, `scikit-learn>=1.2`, and `matplotlib`.
3. Optional packages enable additional models or explanations: `xgboost`, `lightgbm`, `catboost`, and `shap`. Missing optional packages are skipped.
4. Choose a compute profile with `WASTING_PROFILE`:
   - `smoke`: small PSU subsample for checking that the code runs; **not for reporting results**.
   - `standard`: the saved default profile.
   - `extended`: more seeds, tuning configurations, bootstrap replicates and permutations; takes longer.
5. Restart the notebook kernel and select **Run All**.

Completed experiment blocks are cached under `outputs/cache/`, so a run can resume after interruption. The generated tables are saved in `outputs/` and figures in `figures/`.

---

## In one sentence

The notebook carefully compares simple and machine-learning models using held-out groups of survey clusters, checks for leakage and overfitting, and finds that although some complex models show small provisional gains, **there is not yet reliable evidence that they predict severe wasting substantially better than a simple age-and-sex model**.
