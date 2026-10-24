# Interpretable neural-network analysis (PyTorch)

## Purpose

Two **Neural Additive Models (NAMs)** were added as an interpretable neural-network check on the existing severe-wasting prediction work. They use the exact predictor sets defined in `models.ipynb`: 17 child/maternal/household predictors for all children aged 0–4, and those same variables plus 11 feeding/ANC predictors for children aged 0–1 completed years (under 2). The target is `severe_wasting`.

A NAM is deliberately more transparent than a standard multilayer perceptron. Its log-odds are an additive sum of one learned function per original variable. Continuous predictors (`ub2`, `wb4`, `cm11`, and `dds` in the under-2 model) use small one-dimensional neural subnetworks; categorical predictors use learned category contributions. This allows nonlinear single-variable patterns without hiding them inside a large network of interactions.

## Validation and modelling choices

The analysis uses the same core validation principle as the tree work: **stratified, PSU-grouped 5-fold cross-validation**, so children from the same `hh1` cluster never appear in both training and test data. Outcome-derived variables are excluded. Numeric missingness is median-imputed within the training fold and standardized; categorical missing/unseen values receive a dedicated category. Models are trained with binary cross-entropy and AdamW with strong weight decay because the outcome is rare and the earlier tree models showed overfitting. Survey weights are used for the primary reported evaluation metrics, but not as design-based neural-network inference.

## Results

| Analysis | N | Cases | Weighted prevalence | Weighted ROC AUC | Unweighted ROC AUC | Weighted PR AUC | Weighted Brier |
|---|---:|---:|---:|---:|---:|---:|---:|
| Ages 0–4 | 22,311 | 552 | 0.0252 | **0.4923** | 0.5016 | 0.0254 | 0.0354 |
| Ages 0–1 | 8,888 | 297 | 0.0332 | **0.5218** | 0.5222 | 0.0368 | 0.0408 |

The all-child NAM is essentially at chance. The under-2 NAM is only slightly above chance and is substantially below the best tuned models already reported in the project (roughly 0.58–0.60 AUC). The neural-network experiment therefore provides **no evidence that an additive neural representation extracts useful extra predictive signal from these variables**.

Fold-to-fold performance was also unstable. For ages 0–4, weighted fold AUCs ranged from about 0.45 to 0.54. For ages 0–1, they ranged from about 0.44 to 0.56. This instability is important because there are only 552 and 297 severe-wasting cases respectively, and the grouped folds must generalize to unseen PSUs.

## What the model used

For ages 0–4, the largest absolute NAM contributions included cough, electricity, diarrhoea, sex, insurance, wealth, water source, marital status, fuel and education. For ages 0–1, diarrhoea was the largest contribution, followed by water source; feeding/ANC variables such as flesh foods, other fruits/vegetables, ANC, egg, legumes and grains also appeared among the larger contributions.

These rankings **should not be interpreted as a new list of risk factors**. A feature can receive a large contribution in a poorly discriminating model because the network is fitting noise or unstable category differences. In particular, the all-child model's near-0.50 AUC means its ranking is not credible as independent epidemiologic evidence. The survey-weighted regression remains the better source for association estimates and uncertainty.

## Public-health interpretation

The negative result is informative. Severe wasting is a rare, multifactorial outcome, while these MICS predictors are mostly broad demographic, household and recent-recall measures. The cross-sectional snapshot does not contain the longitudinal growth trajectory, repeated morbidity, detailed dietary intake, birth size/gestational information, infection burden, or clinical measurements that a neural network would usually need to learn a strong individual-risk function. More model complexity therefore cannot manufacture information that is absent from the predictors.

The under-2 model gives a small hint that feeding and ANC variables contain additional structure, which is consistent with the earlier regression and tuned-tree analyses. However, its AUC of 0.522 is too weak to support screening or individual risk prediction, and the cross-sectional 24-hour feeding recall remains vulnerable to age confounding and reverse causation.

## Comparison with the existing models

The neural results strengthen the project's current conclusion rather than changing it. For all children, age + sex logistic regression, the full weighted logistic model, tuned Random Forest and tuned XGBoost all performed around 0.58–0.59 AUC, while the NAM was about 0.49–0.50. Under 2, the tuned Random Forest reached about 0.595 and regularised logistic regression about 0.58, while the NAM reached about 0.52. Thus a more flexible neural architecture is not justified by predictive performance here.

## Limitations

This is an interpretable predictive experiment, not survey-design neural-network inference. The NAM intentionally excludes interactions to preserve additivity and transparency. Hyperparameters were kept conservative rather than exhaustively tuned, because aggressive tuning on only 552/297 events would increase researcher degrees of freedom and overfitting risk. Contribution magnitudes have no confidence intervals and are not causal effects. External validation is absent.

## Bottom line

The PyTorch NAMs do **not** improve severe-wasting prediction. Their main contribution is methodological: they show that even a nonlinear but interpretable neural model cannot recover stable predictive signal from the current cross-sectional predictor set. The project should continue to prioritize survey-aware regression for inference, simple/tuned models for prediction, careful age modelling, and external or repeated grouped validation rather than increasing neural-network complexity.
