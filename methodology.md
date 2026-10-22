# Methodology so far — plain-language guide

## 1. What is the study about?

The project explores which characteristics are associated with **severe wasting among children under five** in a MICS child dataset. It looks at child characteristics, recent illness, maternal/caretaker characteristics, and household circumstances.

At this stage, it is an observational analysis. It can identify patterns and associations, but it cannot by itself prove that a factor causes severe wasting.

## 2. What data are being used?

The analysis uses the local Stata dataset `MICS-child-ISRC.dta`. The project notebook reports 22,311 eligible children and 49 variables after the initial data selection, with 552 severe-wasting cases. These counts need to be reproduced in the follow-up pipeline and checked against the dataset's codebook.

The main outcome is `severe_wasting`, intended to indicate severe wasting based on a child's weight-for-height z-score. The exact coding and cut-off must be confirmed from the source documentation.

## 3. How was the data prepared?

The existing notebook:

1. Reads the Stata dataset into Python.
2. Removes records missing the survey design variables or outcome, and excludes non-positive child weights.
3. Removes variables derived from the same weight-for-height outcome (including `whz2`, `mod_wasting`, `any_wasting`, and `wast_cat`) from the predictor set to avoid giving a model information that directly defines its outcome.
4. Separates variables available mainly for infants from the full sample, rather than treating infant-only feeding and antenatal-care variables as if they were measured for every child.
5. Summarizes categorical and continuous variables and explores their relationships with severe wasting.

The R follow-up is designed to repeat the eligibility checks and record the number of observations and cases retained. It also reports missingness and complete-case sample flow so that losses from the adjusted model can be seen.

## 4. How does the survey design matter?

MICS uses a complex sample rather than a simple random sample. The analysis needs to account for:

- **Sampling weights (`chweight`):** account for unequal selection probabilities and help the estimates represent the target population.
- **Clusters / primary sampling units (`hh1`):** children sampled in the same cluster may be more alike than children from different clusters.
- **Strata (`strata`):** the sample was organized into groups for sampling and variance estimation.

The reference Stata command in the project is:

```stata
svyset hh1 [pweight = chweight], strata(strata) singleunit(centered)
```

The new R script uses the `survey` package to describe the same cluster, stratum, and weight variables. It currently uses the package's `survey.lonely.psu = "adjust"` setting. This is a specific choice for strata with only one sampled PSU and must be compared with Stata's `singleunit(centered)` behavior. The R results have not yet been generated and checked, so the two implementations should not be assumed equivalent.

## 5. What analyses have been done so far?

### A. Descriptive analysis

The notebook calculates counts and percentages for categorical variables and summaries for continuous variables. It also reports weighted summaries and explores severe-wasting prevalence across groups.

**Purpose:** understand the sample and see how common severe wasting is overall and in different groups.

### B. Univariate analysis

Each candidate predictor is examined separately using weighted summaries, design-related tests, or a regression where appropriate. The notebook reports associations involving child age, sex, recent illness, wealth, and some infant feeding or antenatal-care variables.

**Purpose:** identify patterns that may deserve further investigation. A one-predictor-at-a-time analysis does not adjust for other characteristics, so it is not enough to establish an independent association.

### C. Preliminary multivariable regression

The notebook fits logistic regression models with several predictors at once, including an all-child model and age-specific analyses. Logistic regression estimates odds ratios: values above 1 indicate higher odds relative to a reference, and values below 1 indicate lower odds, conditional on the model's other variables.

The existing notebook reports an adjusted odds ratio around 0.80 per additional year of age and around 0.72 for girls compared with boys in the all-child model. These are preliminary notebook estimates; the survey variance approach and reproducibility issues still need checking.

### D. Preliminary prediction experiment

A secondary notebook fits a random forest and reports a mean weighted ROC-AUC around 0.536 using folds grouped by cluster. The main notebook reports an in-sample ROC-AUC around 0.635 for a different model/sample.

ROC-AUC describes how well a model ranks cases above non-cases. A value near 0.5 is close to random ranking. These two values come from different procedures and should not be treated as a direct comparison. The current results do not establish a useful prediction tool.

### E. R follow-up plan

The new `analysis_followup.R` script is intended to:

1. Use the R `survey` package to represent weights, clusters, and strata explicitly.
2. Produce overall and subgroup weighted prevalence.
3. report missingness and sample flow.
4. Fit a survey-design-based logistic model and a modified-Poisson model for prevalence ratios.
5. Run joint tests for multi-category predictors and exploratory checks for age non-linearity and selected interactions.
6. Produce in-sample calibration diagnostics and optional sensitivity summaries for alternative wasting outcomes.

**Important:** the R script has not completed successfully yet. Windows Application Control blocked a dependency DLL (`readr.dll`), so its output files and estimates are not yet available for interpretation.

## 6. What do the results suggest so far?

Based on the saved notebook output, the clearest preliminary patterns are:

- Severe wasting appears more common among younger children.
- The notebook reports lower odds among girls than boys in the adjusted all-child model.
- Wealth and recent illness show some associations in univariate analysis, but the adjusted evidence is less consistent.
- Some maternal and household categories appear associated in preliminary adjusted results, but small groups and few outcome events make those estimates uncertain.
- Current predictive results are weak or modest and have not been validated sufficiently to support real-world use.

These are **signals to verify**, not final conclusions. They must be revisited after the design-aware R analysis runs and is checked against Stata.

## 7. What are the main limitations?

1. **Survey variance still needs validation.** Earlier Python regression uses weights and cluster-robust standard errors, but does not fully represent the stratified design in the same way as a dedicated complex-survey estimator.
2. **The R script is untested on the local data.** The Windows DLL block must be resolved, and any script errors must be fixed.
3. **The notebooks are not fully reproducible yet.** Some cells refer to variables not defined in the visible run order; the secondary GLM has very large coefficients and missing standard errors for some sparse terms.
4. **Rare outcome and sparse categories.** The initial sample has 552 cases, and some categories have few or no cases. This can produce unstable estimates and wide intervals.
5. **Missing data.** Complete-case analysis may change the sample and bias estimates if missingness is systematic.
6. **Prediction is preliminary.** Out-of-sample validation, rare-outcome metrics, and calibration on held-out clusters are needed.
7. **No causal identification.** The current design supports association analysis, not causal claims.
8. **Multiple testing.** Many predictors and categories are being explored. Prioritize a small set of pre-specified hypotheses, effect sizes, and confidence intervals.

## 8. What should happen next?

1. Resolve the Windows Application Control issue without disabling security globally.
2. Run `analysis_followup.R` and inspect every output and warning.
3. Confirm variable coding and labels against the source data dictionary.
4. Compare key prevalence estimates and a pre-specified regression model with Stata `svy:` results.
5. Review sample flow, missingness, sparse categories, convergence, and confidence intervals.
6. Re-run the notebooks from a clean kernel and repair undefined-variable/model-diagnostic problems.
7. Update the interpretation with the validated R results.
8. Only if prediction remains a research objective, conduct PSU-grouped validation and report weighted ROC-AUC, precision–recall metrics, and held-out calibration.

## Bottom line

The project has completed an exploratory pass and has identified age and sex as promising correlates to examine further. The next stage is validation—not making stronger claims. Final research conclusions should wait until the survey-design-aware estimates have been produced, checked against Stata, and documented with their uncertainty and limitations.
