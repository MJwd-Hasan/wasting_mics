# Severe Wasting among Children Under Five: MICS Analysis

This project explores child, maternal, and household factors associated with severe wasting among children under five in a MICS child dataset. It combines Python exploratory notebooks with an R follow-up using the `survey` package.

> **Status: preliminary.** Output CSVs from the R follow-up are present on this branch, but the current local run is blocked because Windows Application Control prevents R from loading `readr.dll`. The outputs have not yet been independently reproduced on the current machine or compared with Stata. Treat all estimates as provisional, not publication-ready.

## Start here

- [Methodology in simple words](methodology.md) — what was done and why.
- [Follow-up results, interpretation, and gaps](FOLLOWUP_ANALYSIS.md) — readable summary of current outputs.
- [R follow-up script](analysis_followup.R)
- [Main exploratory notebook](eda.ipynb)
- [Secondary modelling notebook](analysis.ipynb)

## Research question and data

**Question:** Which child, maternal, and household characteristics are associated with severe wasting among children under five?

The notebook reports 22,311 eligible records and 552 severe-wasting cases (2.47% unweighted). The R output reports design-weighted prevalence of **2.52%**. The outcome is `severe_wasting`, intended to represent severe wasting based on weight-for-height z-score; confirm its exact coding and cut-off in the source codebook before final reporting.

Survey design variables: cluster/PSU `hh1`, stratum `strata`, child weight `chweight`. The Stata reference uses `svyset hh1 [pweight=chweight], strata(strata) singleunit(centered)`. The R script uses `survey.lonely.psu = "adjust"`; this may not be identical to Stata's setting and must be checked.

## Current outcome of the research so far

These values are from CSV output files committed to this branch. They are **provisional** until the script is reproduced and estimates are checked against Stata.

- **Age:** the core logistic model reports OR **0.80 per additional year** (95% CI 0.74–0.86). A natural-spline test indicates that the age relationship is not fully linear (F = 12.35, p < 0.001). The final model should represent age flexibly.
- **Sex:** adjusted OR for girls versus boys is **0.72** (95% CI 0.58–0.88). Weighted prevalence is about **2.11% for girls and 2.89% for boys**.
- **Recent illness:** diarrhoea OR ≈ 1.35 (95% CI 0.94–1.93); cough OR ≈ 1.17 (0.92–1.48); breathing difficulty OR ≈ 0.92 (0.65–1.29). These adjusted intervals include 1, so the current model does not provide clear evidence of associations.
- **Maternal age:** two categories have individual ORs around 1.75 and 1.82, but the overall joint test is not significant (p = 0.177). Treat individual category results as exploratory.
- **Toilet category:** one small category has OR ≈ 2.34 (95% CI 1.06–5.14), but the joint test is not significant (p = 0.151). Do not claim an overall toilet-type association from this one category.
- **Division:** the joint test is significant in the current output (p = 0.0176), suggesting geographic differences may merit follow-up. This does not identify a cause.
- **Wealth and education:** their joint tests are not significant in the current model (wealth p = 0.632; education p = 0.633).
- **Alternative outcomes:** weighted prevalence is about **10.37% for moderate wasting** and **12.88% for any wasting**, subject to verifying outcome definitions.
- **Sample flow:** 22,311 eligible children / 552 cases; complete-case core model: 22,017 children / 543 cases.
- **Prediction:** the secondary notebook reports grouped-fold random-forest ROC-AUC ≈ 0.536; the main notebook reports in-sample AUC ≈ 0.635 for a different model/sample. These are not directly comparable, and useful predictive performance has not been demonstrated.
- **Calibration:** the current decile table is in-sample. In the highest-risk decile, predicted prevalence is 5.24% versus observed 5.96%; this is not external validation.

## Main gaps

1. Reproduce the output CSVs locally. Resolve the Windows Application Control block on `readr.dll` with appropriate security/administrator support; do not disable security globally.
2. Compare weighted prevalence, confidence intervals, coefficients, and tests with Stata `svy:`. R's `adjust` lonely-PSU option may differ from Stata's `singleunit(centered)`.
3. Verify outcome and predictor coding against the source codebook.
4. Use a flexible age term in the primary model because the spline test suggests non-linearity.
5. Review sparse categories, multiple testing, convergence, and complete-case selection. Some maternal-age and toilet-category results are individual-level findings while their overall factor tests are not significant.
6. Feeding and infant variables have roughly 60% missingness in the full child dataset because they are mainly collected for younger children; analyze them in the correct age subpopulation.
7. Repair notebook reproducibility issues and investigate the secondary GLM's large coefficients/missing standard errors.
8. For prediction, use PSU-grouped held-out validation and report weighted ROC-AUC, precision–recall metrics, and held-out calibration.
9. Describe findings as observational associations, not causes.

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

## Bottom line

The clearest provisional signals are child age and sex; the age relationship appears non-linear. The division joint test suggests geographic differences may be present. Evidence for wealth, education, recent illness, maternal age overall, and toilet category overall is less conclusive. Reproduce the outputs and validate the survey estimates before presenting final findings.
