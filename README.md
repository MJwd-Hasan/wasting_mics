# Severe Wasting among Children Under Five: MICS Analysis

This project studies **severe wasting among children under five** using a child-level MICS dataset. The current work is exploratory: it combines the existing Python notebooks with a new R follow-up intended to account for the survey's clustered, stratified sample design.

> **Research status:** preliminary analysis only. The existing notebooks contain useful descriptive and regression results, but the R follow-up has not yet run successfully on the researcher's computer. Therefore, the design-aware estimates have not yet been produced or cross-checked against Stata. Do not present the preliminary results below as final publication-ready findings.

## Start here

- [Methodology in simple words](methodology.md): what has been done, in what order, and why.
- [Follow-up analysis and interpretation](FOLLOWUP_ANALYSIS.md): preliminary findings, what they might mean, and what remains uncertain.
- [R analysis script](analysis_followup.R): planned survey-design-aware follow-up.
- [Main exploratory notebook](eda.ipynb): descriptive statistics, tests, and initial multivariable models.
- [Secondary notebook](analysis.ipynb): an additional model and preliminary machine-learning experiment.

## Files

| File | Purpose |
|---|---|
| `MICS-child-ISRC.dta` | Stata-format child dataset used by the analysis (22,311 records and 49 variables as reported by the notebook). |
| `eda.ipynb` | Main exploratory data analysis and preliminary association models. |
| `analysis.ipynb` | Secondary GLM and random-forest experiment; results need methodological review. |
| `analysis_followup.R` | Follow-up using R's `survey` package to represent weights, strata, and clusters. |
| `FOLLOWUP_ANALYSIS.md` | Follow-up outputs, interpretation guidance, and validation checklist. |
| `methodology.md` | Plain-language summary of the work completed so far. |
| `Weighting code stata.png` | Reference image of the Stata survey-design specification. |

## Research question and outcome

**Question so far:** Which child, maternal, and household characteristics are associated with severe wasting among children under five in this dataset?

The outcome is `severe_wasting`, intended to represent severe wasting based on weight-for-height z-score. The source coding and definition must be confirmed against the data dictionary before final reporting. The notebook reports **552 cases among 22,311 records** in the initial eligible sample (about 2.5% unweighted).

Variables derived from the same weight-for-height measurement—such as `whz2`, `mod_wasting`, `any_wasting`, and `wast_cat`—are excluded as predictors to avoid outcome leakage. Alternative wasting outcomes, if examined, should be treated as separate sensitivity outcomes.

## Preliminary results reported by the existing notebook

These are **exploratory results from the existing notebook**, not newly calculated R follow-up results. Their uncertainty estimates and survey-design handling still need to be checked.

- **Age:** the notebook reports that severe wasting prevalence is higher among younger children and declines with age. Its univariate estimate is an odds ratio of about 0.81 per additional year; the preliminary all-child adjusted model reports about 0.80 per year (95% CI 0.74–0.86).
- **Sex:** the notebook reports higher prevalence among boys than girls. In the preliminary all-child adjusted model, the female indicator has an adjusted odds ratio of about 0.72 (95% CI 0.58–0.88).
- **Household wealth:** the notebook reports a modest decreasing univariate trend across wealth quintiles. In the adjusted analysis, the overall evidence for wealth is less clear; one infant-model category is reported as lower than its reference category.
- **Recent illness:** diarrhoea, cough, and any recent illness are reported as associated with wasting in univariate analyses. These associations should not be interpreted as causal, and the adjusted evidence needs to be checked.
- **Maternal age, division, and toilet category:** the preliminary adjusted model reports some category-level associations. Small categories and multiple comparisons make these results uncertain.
- **Prediction:** the main notebook reports a survey-weighted ROC-AUC of about 0.635 for an in-sample model assessment. The secondary notebook reports a mean weighted cross-validation ROC-AUC of about 0.536 for a random forest using PSU-grouped folds. These are different procedures and model samples; they should not be compared as if they were a controlled head-to-head experiment. Neither establishes a useful prediction tool without further validation.

No causal conclusion is justified by these analyses. Associations may reflect confounding, measurement, sampling, or missing-data patterns.

## Survey design

The design variables currently used are:

- **Cluster / PSU:** `hh1`
- **Stratum:** `strata`
- **Child sampling weight:** `chweight`

The reference Stata setup shown in the project is `svyset hh1 [pweight=chweight], strata(strata) singleunit(centered)`. The new R script uses `svydesign()` with these three design variables and a lonely-PSU adjustment. That adjustment is not automatically identical to Stata's `singleunit(centered)`; compare results before treating the implementations as equivalent.

## Run the R follow-up

Install R, then install the required packages from an R console:

```r
install.packages(c("haven", "dplyr", "survey"), repos = "https://cloud.r-project.org")
```

From the repository root, run:

```bash
Rscript analysis_followup.R MICS-child-ISRC.dta outputs
```

On Windows PowerShell, if R is installed but not on PATH:

```powershell
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" analysis_followup.R MICS-child-ISRC.dta outputs
```

The current machine has reported a Windows Application Control block on `readr.dll`, a dependency loaded by the R package stack. This is an environment/security-policy problem to resolve before the script can be tested; it is not evidence that the analysis completed. Do not disable Windows security globally.

Expected output tables include sample/prevalence summaries, missingness and sample flow, subgroup prevalence, adjusted odds ratios, modified-Poisson prevalence ratios, joint tests, exploratory tests, non-linearity/interaction checks, and in-sample calibration. Some files are conditional on the data and model fitting successfully. **These files have not yet been generated and verified by the R follow-up.**

## Main gaps before reporting results

1. **Run and debug the R script** and check that every output is produced as intended.
2. **Validate the survey design** by comparing overall prevalence and a pre-specified core model with Stata `svy:` results.
3. **Verify coding and labels** for the outcome, weights, strata, cluster IDs, and categorical predictors using the source codebook.
4. **Report missingness and sample flow**, including the number of children and severe-wasting cases retained in each model.
5. **Address sparse cells and separation.** There are only 552 outcome events in the initial sample, and some categories are small or have no cases.
6. **Repair and rerun the notebooks from a clean kernel.** Some earlier cells rely on variables that are not defined in the notebook sequence; the secondary GLM has very large coefficients and missing standard errors for some terms.
7. **Keep prediction separate from association analysis.** If prediction remains a goal, use cluster/PSU-grouped validation, appropriate survey weights, held-out calibration and precision–recall metrics.
8. **Document limitations and avoid causal language.** Cross-sectional observational associations do not establish cause and effect.

## Current conclusion

The preliminary analysis suggests that age and child sex may be important correlates of severe wasting in this sample, while evidence for wealth, recent illness, maternal characteristics, and household conditions is less consistent across analyses. The next defensible step is not to declare a final set of risk factors: it is to get the R follow-up running, verify its coding and survey variance estimates against Stata, and then revise the interpretation using the validated output tables.
