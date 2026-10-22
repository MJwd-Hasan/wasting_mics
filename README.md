# Severe Wasting among Children Under Five: MICS Analysis

This project explores child, maternal, and household factors associated with **severe wasting** (weight-for-height z-score < -3) among children under five in a MICS child dataset. It combines Python exploratory notebooks with a survey-design-aware R follow-up (`survey` package).

> **Status: preliminary, but reproduced.** The R script was re-run independently (R 4.3.3, Linux) and its original 14 output tables matched the committed CSVs to about 1e-14. Estimates have **not** yet been compared with Stata `svy:`, so treat them as provisional, not publication-ready.

## Start here

- [Methodology in simple words](methodology.md): what was done and why.
- [Follow-up results, interpretation, and gaps](FOLLOWUP_ANALYSIS.md): readable summary of current outputs.
- [R follow-up script](analysis_followup.R): survey models, infant-subpopulation models, tests, diagnostics.
- [Main exploratory notebook](eda.ipynb): data prep, **extended EDA (sections 1-12)**, univariate and multivariable tests.
- [Secondary modelling notebook](analysis.ipynb): preliminary GLM, random forest, SHAP.
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

The weighted in-sample Brier score of the core model (0.02436) is nearly the same as a no-skill model that predicts the average prevalence (0.02453), and the cluster-grouped random-forest ROC-AUC is about 0.54. The models describe risk factors; they are not useful for prediction. The 0.635 in-sample AUC in `eda.ipynb` is optimistic and from a different sample.

## Extended EDA added to `eda.ipynb`

Section "Extended Exploratory Data Analysis" (right after data preparation) covers: structural missingness; outcome definition check against WHZ; survey-design diagnostics; age-by-sex and age-by-wealth patterns; division and district funnel plot; predictor profiles; illness-by-age confounding; predictor overlap (Cramer's V, VIF); infant feeding and ANC; data-validity checks. Main takeaways:

- The design effect (about 1.34) comes from the weights, not clustering: PSU dispersion ratio 1.04 and ICC about 0.0003.
- Missingness is mostly structural: infant-only variables are about 60% missing overall but only 0-1% missing at ages 0-1 (meal frequency `bd9` is the exception at 27%).
- Several categories are too small for stable estimates (`toilet_cat` 3: 12 cases; `fuel_cat` 4: 5; unmarried mothers: 9; `parity_cat` 0: 29 children, 0 cases, likely non-mother caretakers).

## Main gaps

1. Compare weighted prevalence, confidence intervals, coefficients, and tests with Stata `svy:`.
2. Verify predictor coding against the source codebook (the outcome coding is now verified).
3. Use a flexible (spline) age term in the primary model.
4. Review sparse categories, multiple testing, and complete-case selection. Consider Firth or penalized models for sparse categories and multiple imputation for the infant models.
5. Repair the remaining notebook reproducibility issues: several cells in `eda.ipynb` (Poisson, interaction, joint-Wald, ROC, mixed-model cells) use variables never defined in the notebook (`df_model`, `df_multi`, `glm_main`, `main_formula`); the multilevel cell calls a function that does not exist in `statsmodels`. The R script supersedes the Poisson and interaction analyses but not the multilevel model.
6. For any prediction claim, use PSU-grouped held-out validation, weighted ROC-AUC, precision-recall metrics, and held-out calibration.
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
