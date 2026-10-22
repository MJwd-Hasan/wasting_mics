# Severe Wasting among Children Under 5: MICS Survey Analysis

Design-aware exploratory and inferential analysis of **severe wasting** (`severe_wasting`) in children under five, using a Multiple Indicator Cluster Survey (MICS) child dataset.

## Repository contents

| File | Description |
|---|---|
| `MICS-child-ISRC.dta` | Stata dataset: 22,311 children, 49 variables |
| `eda.ipynb` | Main notebook: data preparation, univariate tests, multivariable models, and model-checking steps |
| `analysis.ipynb` | Preliminary side analysis: survey-weighted GLM, random forest (cluster-grouped CV) and SHAP |
| `Weighting code stata.png` | Reference Stata `svyset` command that the survey design follows |

## Data and survey design

- **Outcome:** `severe_wasting` (binary). 552 of 22,311 children are severe wasting cases (unweighted).
- **Survey design variables:**
  - PSU / cluster: `hh1`
  - Stratum: `strata` (area × division)
  - Weight: `chweight` (child sample weight)
- The design follows the Stata specification `svyset hh1 [pweight = chweight], strata(strata) singleunit(centered)`.
- **Cleaning:** records with missing `hh1`, `chweight`, `strata` or `severe_wasting`, or with `chweight <= 0`, are dropped (final N = 22,311).
- **Leakage control:** `whz2`, `mod_wasting`, `any_wasting` and `wast_cat` are removed because they are the same measurement as the outcome.
- **Infant-only variables** (`dds`, `fvs`, `fg_*`, `bf_status`, `bottle`, `anc_cat`) exist mostly for children aged 0-1 (`young == 1`), so they are analysed in a separate infant subpopulation rather than in the full-sample model.

## Methods (`eda.ipynb`)

1. **Descriptives:** unweighted counts and survey-weighted percentages for categorical variables; weighted mean, SD, median and IQR for continuous variables.
2. **Design-based prevalence:** weighted prevalence of severe wasting per category, with Taylor-linearization 95% CIs (logit-transformed, df = PSUs − strata), implemented manually to mimic Stata.
3. **Univariate tests:**
   - Rao-Scott-type F-tests for binary and nominal predictors.
   - Design-adjusted trend tests for ordered predictors (`wealth`, `edu_level`, `ub2`, `parity_cat`, `mage_cat`).
   - Univariable weighted logistic regression for continuous and count variables (`wb4`, `cm11`), with quartile and spline linearity checks.
   - The same tests repeated within infants (`young == 1`) for feeding and antenatal care variables.
4. **Multivariable models:** survey-weighted logistic regression (weights plus cluster-robust standard errors on `hh1`) for all children aged 0-4, for infants aged 0-1 (adding feeding and ANC predictors), and for children aged 2-4.
5. **Model assessment:** joint Wald tests for multi-level factors, survey-weighted ROC-AUC and a decile calibration table.
6. **Further analyses (see known issues below):** Poisson regression for prevalence ratios, interaction tests, a multilevel model and an L2-penalized logistic model.

## Key findings

**Univariate (all children, 0-4)**

| Predictor | Result |
|---|---|
| Child's age (`ub2`) | Strongest association: prevalence falls from 3.86% at age 0 to 1.75% at age 4 (trend OR 0.81 per year, p < 0.001) |
| Sex | Boys 2.89% vs girls 2.11% (Rao-Scott F = 9.90, p = 0.0017) |
| Illness in last 2 weeks | Diarrhoea 3.72% vs 2.42% (p = 0.009); cough (p = 0.026); any illness (p = 0.007) |
| Wealth quintile | Declining trend, OR 0.92 per quintile (p = 0.024) |
| Toilet type | Borderline (p = 0.056) |
| Not significant | Urban/rural, division, water source, fuel type, electricity, maternal education trend, parity, maternal age (as a continuous variable) |

**Infants aged 0-1 (univariate)**
- Grain consumption (p = 0.0002), flesh foods (p = 0.0001) and ANC visit category (p = 0.007) are associated with lower prevalence.
- Dietary diversity score: OR 0.86 per item (95% CI 0.80-0.94). Food variety score: OR 0.91 (0.85-0.97). ANC category trend: OR 0.71 (0.57-0.88).
- Breastfeeding status and bottle feeding show no association.

**Multivariable, all children 0-4 (N = 22,017)**
- Older age: AOR 0.80 per year (95% CI 0.74-0.86).
- Female sex: AOR 0.72 (0.58-0.88).
- Older maternal age categories 4 and 5: AOR 1.75 (1.07-2.86) and 1.82 (1.08-3.05).
- Toilet category 3: AOR 2.34 (1.06-5.13). This category is small, so treat it with caution.
- Joint Wald test: division is significant (p = 0.017). Education, water source, fuel, toilet type and wealth are not significant jointly.
- Discrimination is modest (survey-weighted ROC-AUC = 0.635), but calibration is good across deciles: mean predicted risk 1.0%-5.4% vs observed 1.2%-5.1%.

**Multivariable, infants 0-1 (N = 8,713)**
- Female sex: AOR 0.73 (0.56-0.96).
- Older maternal age categories 4 and 5: AOR 2.09 and 2.36.
- Wealth quintile 4: AOR 0.54 (0.31-0.96).

## Known issues and limitations

- **Regression and design:** regression models use weights with cluster-robust SEs on `hh1`, but strata are not used in the regression variance. Rao-Scott F-tests use an average design effect across categories, so they approximate the full survey-package procedure. For publication-grade results, confirm key estimates in Stata (`svy:`) or R (`survey`).
- **Sparse categories:** `parity_cat == 0` has 29 children and no cases (collapsed into category 1 in the main models). Where it is not collapsed, the estimates become unstable (e.g. extreme prevalence ratios and an infinite-width CI in the 2-4 model).
- **Interaction tests:** `young × wealth`, `young × urban` and `female × young` produce degenerate output (enormous coefficients, missing SEs). `young` is a deterministic function of `ub2`, so the model is collinear and the interaction results are not interpretable yet.
- **Multilevel model:** the mixed-effects cell has no output and uses a function that does not exist in `statsmodels.formula.api`; it needs to be replaced with `BinomialBayesMixedGLM` or an R/Stata mixed model.
- **Reproducibility:** some cells (Poisson, interactions, joint Wald tests, ROC-AUC and calibration, ridge) use `df_multi`, `glm_main` and `main_formula`, which are not defined in the notebook. They should be defined in an earlier cell before the notebook can be run top to bottom.
- **Sample size:** with only 552 events, models are limited to a moderate number of parameters and many subgroup estimates are imprecise.

## How to run

1. Place `MICS-child-ISRC.dta` in the same folder as the notebooks.
2. Install dependencies: `pip install pandas numpy scipy statsmodels scikit-learn shap jupyter`.
3. Open `eda.ipynb` and run cells in order (fix the undefined-variable issue above first).

## Next steps

- Fix the undefined variables and the multilevel and interaction cells.
- Replace `young` with `ub2` (or drop it) in interaction models.
- Confirm design-based estimates in Stata or R.
- Add penalized or Firth models for sparse categories.
