# ĐỨC THẮNG — DATA MODELING
# Người phụ trách: Đức Thắng (ML Engineer)
# Mô tả: 3 mô hình dự đoán doanh số: Linear Regression, Random Forest, XGBoost
#         Có hyperparameter tuning cho RF và XGBoost
# Input:  data/processed/train_data.rds
#         data/processed/val_data.rds
# Output: output/tables/models.rds            → trained models
#         output/tables/predictions.rds        → predictions + actual
#         output/tables/feature_importance.rds → RF + XGBoost importance
#         output/tables/logit_results.rds      → Logistic Regression classification results

library(dplyr)
library(caret)
library(ranger)
library(xgboost)
library(here)
library(rpart)
library(rpart.plot)

cat(" ĐỨC THẮNG — DATA MODELING\n")

# TASK 2: ĐỌC DỮ LIỆU TRAIN/VAL TỪ QUỐC ANH (readRDS)
cat(" TASK 2: ĐỌC DỮ LIỆU TRAIN/VAL \n")

train_data <- readRDS(here("data", "processed", "train_data.rds"))
test_data  <- readRDS(here("data", "processed", "val_data.rds"))

cat("✅ Đã đọc train_data.rds:", nrow(train_data), "dòng,",
    ncol(train_data), "cột\n")
cat("✅ Đã đọc val_data.rds:  ", nrow(test_data), "dòng,",
    ncol(test_data), "cột\n")

# Kiểm tra dữ liệu input
stopifnot("sales" %in% names(train_data))
stopifnot("sales" %in% names(test_data))
cat("Sales range (train):", range(train_data$sales), "\n")
cat("Sales range (val):  ", range(test_data$sales), "\n")

# TASK 1: prepare_features() — Encode categorical, chọn features
cat("\n TASK 1: CHUẨN BỊ FEATURES \n")

# Danh sách features cho modeling
# ⚠️ KHÔNG bao gồm sales_per_customer (Target Leakage: sales/customers → dự đoán sales)
# ⚠️ competition_open_months: -1 = không có đối thủ (mô hình cây tự xử lý)
feature_cols <- c("customers", "day_of_week", "promo", "state_holiday",
                  "school_holiday", "store_type", "assortment",
                  "competition_distance", "promo2", "month",
                  "week_of_year", "is_weekend",
                  "competition_open_months", "has_competition")

cat("⚠️ sales_per_customer ĐÃ BỊ LOẠI khỏi features (Target Leakage)\n")
cat("ℹ️ customers được giữ để phục vụ phân tích khi đã biết số khách; nếu dự báo tương lai nên loại bỏ.\n")
cat("Số features đầu vào:", length(feature_cols), "\n")

# Hàm encode categorical → numeric cho Random Forest và XGBoost
prepare_features <- function(df, feature_cols, factor_levels = NULL) {
  available_cols <- feature_cols[feature_cols %in% names(df)]

  if (length(available_cols) < length(feature_cols)) {
    missing <- setdiff(feature_cols, names(df))
    cat("⚠️ Cột không tồn tại (bỏ qua):", paste(missing, collapse = ", "), "\n")
  }

  df_features <- df %>% select(all_of(available_cols))

  for (col in names(df_features)) {
    if (is.factor(df_features[[col]])) {
      char_vals <- as.character(df_features[[col]])
      num_vals <- suppressWarnings(as.numeric(char_vals))
      if (all(is.na(char_vals) | !is.na(num_vals))) {
        df_features[[col]] <- num_vals
      } else {
        ref_levels <- if (!is.null(factor_levels) && col %in% names(factor_levels)) {
          factor_levels[[col]]
        } else {
          levels(df_features[[col]])
        }
        df_features[[col]] <- as.numeric(factor(char_vals, levels = ref_levels))
      }
    }
  }

  return(as.data.frame(df_features))
}

# Áp dụng prepare_features cho train và val
train_factor_levels <- lapply(
  train_data[intersect(feature_cols, names(train_data))],
  function(x) if (is.factor(x)) levels(x) else NULL
)
train_factor_levels <- train_factor_levels[!vapply(train_factor_levels, is.null, logical(1))]

train_X <- prepare_features(train_data, feature_cols, train_factor_levels)
train_y <- train_data$sales
test_X  <- prepare_features(test_data, feature_cols, train_factor_levels)
test_y  <- test_data$sales

common_cols <- intersect(names(train_X), names(test_X))
train_X <- train_X[, common_cols]
test_X  <- test_X[, common_cols]

cat("✅ Features đã encode:", ncol(train_X), "biến\n")
cat("Features:", paste(names(train_X), collapse = ", "), "\n")
cat("Train X:", nrow(train_X), "dòng | Val X:", nrow(test_X), "dòng\n")

# TASK 3: MÔ HÌNH 1 — LINEAR REGRESSION + summary()
cat("\n TASK 3: MÔ HÌNH 1 — LINEAR REGRESSION \n")
cat("========== MODEL 1: LINEAR REGRESSION ==========\n")

lm_features <- intersect(feature_cols, names(train_data))
lm_formula <- as.formula(paste("sales ~", paste(lm_features, collapse = " + ")))
cat("LM Formula:", deparse(lm_formula), "\n")

model_lm <- lm(lm_formula, data = train_data)

cat("--- LM Summary ---\n")
lm_summary <- summary(model_lm)
print(lm_summary)

cat("LM R²:", round(lm_summary$r.squared, 4), "\n")
cat("LM Adjusted R²:", round(lm_summary$adj.r.squared, 4), "\n")
cat("LM Residual SE:", round(lm_summary$sigma, 2), "\n")

# Predictions trên validation set
pred_lm <- predict(model_lm, newdata = test_data)
pred_lm <- pmax(pred_lm, 0)  # Sales không thể âm

cat("✅ LR predictions — range:", round(range(pred_lm), 2), "\n")

# TASK 3B: LOGISTIC REGRESSION — HIGH SALES CLASSIFICATION
cat("\n TASK 3B: LOGISTIC REGRESSION — HIGH SALES CLASSIFICATION \n")
cat("========== MODEL 1B: LOGISTIC REGRESSION ==========\n")

# Logistic Regression không dự đoán trực tiếp sales, mà dự đoán xác suất
# một quan sát thuộc nhóm doanh thu cao (high_sales = 1).
sales_threshold <- 10000

train_data$high_sales <- ifelse(train_data$sales >= sales_threshold, 1, 0)
test_data$high_sales  <- ifelse(test_data$sales >= sales_threshold, 1, 0)

cat("Sales threshold:", sales_threshold, "\n")

cat("Train high_sales distribution:\n")
print(table(train_data$high_sales))

cat("Val high_sales distribution:\n")
print(table(test_data$high_sales))

logit_features <- intersect(feature_cols, names(train_data))
missing_logit_features <- setdiff(feature_cols, logit_features)
if (length(missing_logit_features) > 0) {
  cat("⚠️ Logistic features không tồn tại (bỏ qua):",
      paste(missing_logit_features, collapse = ", "), "\n")
}

leakage_cols <- c("sales", "sales_per_customer", "high_sales")
logit_features <- setdiff(logit_features, leakage_cols)

logit_formula <- as.formula(paste("high_sales ~", paste(logit_features, collapse = " + ")))
cat("Logistic Regression Formula:", deparse(logit_formula), "\n")

model_logit <- glm(logit_formula, data = train_data, family = binomial)

cat("--- Logistic Regression Summary ---\n")
logit_summary <- summary(model_logit)
print(logit_summary)

logit_odds_ratio <- exp(coef(model_logit))
cat("--- Odds Ratio: exp(coef(model_logit)) ---\n")
print(logit_odds_ratio)

pred_logit_prob <- predict(model_logit, newdata = test_data, type = "response")
pred_logit_class <- ifelse(pred_logit_prob >= 0.5, 1, 0)

cat("✅ Logistic predicted probabilities — range:",
    round(range(pred_logit_prob), 4), "\n")
cat("✅ Logistic class threshold: 0.5\n")

logit_actual <- test_data$high_sales
logit_confusion_matrix <- table(
  Actual = factor(logit_actual, levels = c(0, 1)),
  Predicted = factor(pred_logit_class, levels = c(0, 1))
)

cat("--- Logistic Confusion Matrix ---\n")
print(logit_confusion_matrix)

tn <- logit_confusion_matrix["0", "0"]
fp <- logit_confusion_matrix["0", "1"]
fn <- logit_confusion_matrix["1", "0"]
tp <- logit_confusion_matrix["1", "1"]

logit_accuracy <- (tp + tn) / sum(logit_confusion_matrix)
logit_precision <- ifelse((tp + fp) == 0, NA, tp / (tp + fp))
logit_recall <- ifelse((tp + fn) == 0, NA, tp / (tp + fn))
logit_f1 <- ifelse(
  is.na(logit_precision) || is.na(logit_recall) || (logit_precision + logit_recall) == 0,
  NA,
  2 * logit_precision * logit_recall / (logit_precision + logit_recall)
)
logit_f1_display <- ifelse(is.na(logit_f1), "N/A", round(logit_f1, 4))

logit_metrics <- data.frame(
  Metric = c("Accuracy", "Precision", "Recall", "F1-score"),
  Value = c(logit_accuracy, logit_precision, logit_recall, logit_f1)
)

cat(sprintf("Logistic Accuracy:  %.4f\n", logit_accuracy))
cat(sprintf("Logistic Precision: %.4f\n", logit_precision))
cat(sprintf("Logistic Recall:    %.4f\n", logit_recall))
cat("Logistic F1-score: ", logit_f1_display, "\n")

# TASK 4: MÔ HÌNH 2 — RANDOM FOREST (ranger) + importance + TUNING
cat("\n TASK 4: MÔ HÌNH 2 — RANDOM FOREST + TUNING \n")
cat("========== MODEL 2: RANDOM FOREST (ranger) ==========\n")

# Hyperparameter Tuning: thử nhiều giá trị mtry
n_features <- ncol(train_X)
mtry_candidates <- unique(c(
  max(1, floor(n_features / 3)),     # p/3 (regression default)
  max(1, floor(sqrt(n_features))),    # sqrt(p)
  max(1, floor(n_features / 2))      # p/2
))

cat("Tuning mtry: thử", length(mtry_candidates), "giá trị:",
    paste(mtry_candidates, collapse = ", "), "\n")

best_oob_rmse <- Inf
best_mtry <- mtry_candidates[1]

for (m in mtry_candidates) {
  set.seed(42)
  rf_temp <- ranger(
    sales ~ .,
    data       = cbind(train_X, sales = train_y),
    num.trees  = 200,
    mtry       = m,
    importance = "impurity",
    seed       = 42,
    verbose    = FALSE
  )
  oob_rmse <- sqrt(rf_temp$prediction.error)
  cat("  mtry =", m, "→ OOB RMSE:", round(oob_rmse, 2),
      "| OOB R²:", round(rf_temp$r.squared, 4), "\n")
  if (oob_rmse < best_oob_rmse) {
    best_oob_rmse <- oob_rmse
    best_mtry <- m
  }
}

cat("✅ Best mtry:", best_mtry, "(OOB RMSE:", round(best_oob_rmse, 2), ")\n")

# Train final RF với best mtry
set.seed(42)
model_rf <- ranger(
  sales ~ .,
  data       = cbind(train_X, sales = train_y),
  num.trees  = 200,
  mtry       = best_mtry,
  importance = "impurity",                   # Gini importance
  seed       = 42,
  verbose    = TRUE
)

cat("RF OOB Prediction Error (MSE):", round(model_rf$prediction.error, 2), "\n")
cat("RF OOB R²:", round(model_rf$r.squared, 4), "\n")
cat("RF Num Trees:", model_rf$num.trees, "\n")
cat("RF Mtry:", model_rf$mtry, "\n")

# Predictions trên validation set
pred_rf <- predict(model_rf, data = test_X)$predictions
pred_rf <- pmax(pred_rf, 0)

cat("✅ RF predictions — range:", round(range(pred_rf), 2), "\n")

# Feature Importance (RF)
rf_importance <- data.frame(
  Feature    = names(model_rf$variable.importance),
  Importance = model_rf$variable.importance,
  row.names  = NULL
) %>% arrange(desc(Importance))

cat("--- Top 5 features (Random Forest) ---\n")
print(head(rf_importance, 5))

# TASK 5: MÔ HÌNH 3 — XGBOOST + xgb.cv() + GRID SEARCH
cat("\n TASK 5: MÔ HÌNH 3 — XGBOOST + GRID SEARCH \n")
cat("========== MODEL 3: XGBOOST ==========\n")

# Tạo DMatrix
dtrain <- xgb.DMatrix(data = as.matrix(train_X), label = train_y)
dtest  <- xgb.DMatrix(data = as.matrix(test_X),  label = test_y)

# Grid Search: thử nhiều tổ hợp hyperparameters
param_grid <- expand.grid(
  max_depth = c(4, 6, 8),
  eta       = c(0.05, 0.1, 0.2)
)

cat("Grid Search:", nrow(param_grid), "tổ hợp hyperparameters\n")

best_cv_rmse <- Inf
best_params  <- NULL
best_nrounds_final <- 100

for (i in seq_len(nrow(param_grid))) {
  params_i <- list(
    objective        = "reg:squarederror",
    max_depth        = param_grid$max_depth[i],
    eta              = param_grid$eta[i],
    subsample        = 0.8,
    colsample_bytree = 0.8,
    min_child_weight = 5,
    gamma            = 0,
    lambda           = 1
  )

  set.seed(42)
  cv_i <- xgb.cv(
    params                = params_i,
    data                  = dtrain,
    nrounds               = 500,
    nfold                 = 5,
    early_stopping_rounds = 20,
    print_every_n         = 100,
    verbose               = 0
  )

  best_iter_i <- cv_i$best_iteration
  if (is.null(best_iter_i) ||
      length(best_iter_i) == 0 ||
      is.na(best_iter_i[1]) ||
      best_iter_i[1] <= 0) {
    eval_log_i <- cv_i$evaluation_log
    if (!is.null(eval_log_i)) {
      rmse_col_i <- grep("test.*rmse.*mean", names(eval_log_i), value = TRUE)
      if (length(rmse_col_i) > 0) {
        best_iter_i <- which.min(eval_log_i[[rmse_col_i[1]]])
      } else {
        best_iter_i <- 100
      }
    } else {
      best_iter_i <- 100
    }
  }

  eval_log_i <- cv_i$evaluation_log
  rmse_col_i <- grep("test.*rmse.*mean", names(eval_log_i), value = TRUE)
  if (length(rmse_col_i) > 0) {
    cv_rmse_i <- eval_log_i[[rmse_col_i[1]]][best_iter_i]
  } else {
    cv_rmse_i <- Inf
  }

  cat("  max_depth =", param_grid$max_depth[i],
      "| eta =", param_grid$eta[i],
      "| nrounds =", best_iter_i,
      "| CV RMSE:", round(cv_rmse_i, 2), "\n")

  if (cv_rmse_i < best_cv_rmse) {
    best_cv_rmse <- cv_rmse_i
    best_params  <- params_i
    best_nrounds_final <- best_iter_i
  }
}

cat("\n✅ Best XGBoost Params:\n")
cat("  max_depth:", best_params$max_depth, "\n")
cat("  eta:", best_params$eta, "\n")
cat("  subsample:", best_params$subsample, "\n")
cat("  colsample_bytree:", best_params$colsample_bytree, "\n")
cat("  min_child_weight:", best_params$min_child_weight, "\n")
cat("  Best nrounds (CV):", best_nrounds_final, "\n")
cat("  Best CV RMSE:", round(best_cv_rmse, 2), "\n")

# Train final model với best params
cat("\n--- Training Final XGBoost Model ---\n")
model_xgb <- xgb.train(
  params        = best_params,
  data          = dtrain,
  nrounds       = best_nrounds_final,
  evals         = list(train = dtrain, val = dtest),
  print_every_n = 50,
  verbose       = 1
)

# TASK 6: predict() trên validation set (3 models)
cat("\n TASK 6: PREDICTIONS TRÊN VALIDATION SET \n")

# XGBoost predictions
pred_xgb <- predict(model_xgb, newdata = dtest)
pred_xgb <- pmax(pred_xgb, 0)

cat("✅ XGBoost predictions — range:", round(range(pred_xgb), 2), "\n")

# Feature Importance (XGBoost)
xgb_importance <- xgb.importance(model = model_xgb)
cat("--- Top 5 features (XGBoost) ---\n")
print(head(xgb_importance, 5))

cat("\n XGBOOST EXPLAINABILITY TREES \n")

if (!exists("model_xgb") || !inherits(model_xgb, "xgb.Booster")) {
  stop("model_xgb chưa tồn tại hoặc không phải xgb.Booster.")
}

dir.create(here("output", "figures"), recursive = TRUE, showWarnings = FALSE)

xgb_train_prediction <- predict(model_xgb, newdata = dtrain)

surrogate_features <- c(
  "customers", "promo", "competition_distance",
  "competition_open_months", "assortment",
  "store_type", "day_of_week"
)
surrogate_features <- intersect(surrogate_features, names(train_X))

surrogate_train_data <- train_X[, surrogate_features, drop = FALSE]
surrogate_train_data$xgb_predicted_sales <- xgb_train_prediction

surrogate_formula <- as.formula(
  paste("xgb_predicted_sales ~", paste(surrogate_features, collapse = " + "))
)

set.seed(42)
model_xgb_surrogate <- rpart(
  formula = surrogate_formula,
  data = surrogate_train_data,
  method = "anova",
  control = rpart.control(maxdepth = 4, minsplit = 80, cp = 0.002)
)

png(
  here("output", "figures", "surrogate_tree_explain_xgboost.png"),
  width = 2400, height = 1500, res = 180
)
rpart.plot(
  model_xgb_surrogate,
  type = 2,
  extra = 101,
  fallen.leaves = TRUE,
  box.palette = "Blues",
  shadow.col = "gray",
  branch.lty = 3,
  faclen = 0,
  tweak = 1.15,
  main = "Surrogate Tree Explaining XGBoost Sales Predictions"
)
dev.off()
cat("✅ Đã lưu: output/figures/surrogate_tree_explain_xgboost.png\n")

cat("\n═══ GHI CHÚ GIẢI THÍCH XGBOOST ═══\n")
cat("• XGBoost là mô hình chính dùng để đánh giá hiệu năng.\n")
cat("• Không thể biểu diễn toàn bộ XGBoost bằng một cây duy nhất vì XGBoost gồm nhiều booster trees.\n")
cat("• Cây surrogate chỉ dùng để minh họa logic dự đoán tổng quát.\n")
cat("• Khi đưa vào slide, không nên dùng hình full XGBoost tree vì quá phức tạp và khó đọc.\n")

# Tổng kết predictions
cat("\n═══ TỔNG KẾT PREDICTIONS ═══\n")
cat("Actual range:      ", round(range(test_y), 2), "\n")
cat("LR predictions:    ", round(range(pred_lm), 2), "\n")
cat("RF predictions:    ", round(range(pred_rf), 2), "\n")
cat("XGBoost predictions:", round(range(pred_xgb), 2), "\n")

# Tính metrics để kiểm tra
rmse_lm  <- sqrt(mean((test_y - pred_lm)^2))
rmse_rf  <- sqrt(mean((test_y - pred_rf)^2))
rmse_xgb <- sqrt(mean((test_y - pred_xgb)^2))

mae_lm  <- mean(abs(test_y - pred_lm))
mae_rf  <- mean(abs(test_y - pred_rf))
mae_xgb <- mean(abs(test_y - pred_xgb))

# RMSPE — metric chính của cuộc thi Rossmann trên Kaggle
calc_rmspe <- function(actual, predicted) {
  mask <- actual > 0
  sqrt(mean(((actual[mask] - predicted[mask]) / actual[mask])^2))
}

rmspe_lm  <- calc_rmspe(test_y, pred_lm)
rmspe_rf  <- calc_rmspe(test_y, pred_rf)
rmspe_xgb <- calc_rmspe(test_y, pred_xgb)

# R²
calc_r2 <- function(actual, predicted) {
  1 - sum((actual - predicted)^2) / sum((actual - mean(actual))^2)
}

r2_lm  <- calc_r2(test_y, pred_lm)
r2_rf  <- calc_r2(test_y, pred_rf)
r2_xgb <- calc_r2(test_y, pred_xgb)

cat("\n═══ METRICS TRÊN VALIDATION SET ═══\n")
cat(sprintf("%-20s RMSE: %10.2f | MAE: %10.2f | R²: %.4f | RMSPE: %.4f\n",
            "Linear Regression", rmse_lm, mae_lm, r2_lm, rmspe_lm))
cat(sprintf("%-20s RMSE: %10.2f | MAE: %10.2f | R²: %.4f | RMSPE: %.4f\n",
            "Random Forest", rmse_rf, mae_rf, r2_rf, rmspe_rf))
cat(sprintf("%-20s RMSE: %10.2f | MAE: %10.2f | R²: %.4f | RMSPE: %.4f\n",
            "XGBoost", rmse_xgb, mae_xgb, r2_xgb, rmspe_xgb))
cat("🏆 Best (RMSE):", c("LR", "RF", "XGB")[which.min(c(rmse_lm, rmse_rf, rmse_xgb))], "\n")
cat("🏆 Best (RMSPE):", c("LR", "RF", "XGB")[which.min(c(rmspe_lm, rmspe_rf, rmspe_xgb))], "\n")

# TASK 7: saveRDS() — models + predictions + feature importance
cat("\n TASK 7: LƯU KẾT QUẢ \n")

dir.create(here("output", "tables"), recursive = TRUE, showWarnings = FALSE)

# Lưu trained models
saveRDS(
  list(lm = model_lm, rf = model_rf, xgb = model_xgb, logit = model_logit),
  here("output", "tables", "models.rds")
)
cat("✅ Đã lưu: output/tables/models.rds (LM + RF + XGBoost + Logistic)\n")

# Lưu predictions + actual (cho Thành Tài đánh giá)
saveRDS(
  list(
    lm = pred_lm,
    rf = pred_rf,
    xgb = pred_xgb,
    actual = test_y,
    logit_prob = pred_logit_prob,
    logit_class = pred_logit_class,
    high_sales_actual = logit_actual
  ),
  here("output", "tables", "predictions.rds")
)
cat("✅ Đã lưu: output/tables/predictions.rds (predictions + actual)\n")

# Lưu feature importance (cho Thành Tài vẽ biểu đồ)
saveRDS(
  list(rf = rf_importance, xgb = xgb_importance),
  here("output", "tables", "feature_importance.rds")
)
cat("✅ Đã lưu: output/tables/feature_importance.rds (RF + XGBoost)\n")

# Lưu kết quả Logistic Regression riêng cho phân loại high_sales
saveRDS(
  list(
    model_logit = model_logit,
    logit_metrics = logit_metrics,
    logit_confusion_matrix = logit_confusion_matrix,
    logit_odds_ratio = logit_odds_ratio
  ),
  here("output", "tables", "logit_results.rds")
)
cat("✅ Đã lưu: output/tables/logit_results.rds (model_logit + metrics + confusion matrix + odds ratio)\n")

# TÓM TẮT
cat("\n📊 TÓM TẮT MODELING\n")
cat("Model 1: Linear Regression\n")
cat("  → R²:", round(r2_lm, 4), "| RMSE:", round(rmse_lm, 2), "\n")
cat("Model 1B: Logistic Regression (high_sales)\n")
cat("  → Accuracy:", round(logit_accuracy, 4), "| F1:", logit_f1_display, "\n")
cat("Model 2: Random Forest (ranger, 200 trees, mtry =", best_mtry, ")\n")
cat("  → OOB R²:", round(model_rf$r.squared, 4), "| RMSE:", round(rmse_rf, 2), "\n")
cat("Model 3: XGBoost (nrounds =", best_nrounds_final, ")\n")
cat("  → CV Best | RMSE:", round(rmse_xgb, 2), "\n")
cat("🏆 Best Model:", c("Linear Regression", "Random Forest", "XGBoost")[which.min(c(rmse_lm, rmse_rf, rmse_xgb))], "\n")
cat("Features:", ncol(train_X), "biến (sales_per_customer loại bỏ)\n")
cat("Train:", format(nrow(train_X), big.mark = ","), "| Val:", format(nrow(test_X), big.mark = ","), "\n")
cat("Tuning: RF mtry grid + XGB grid search (9 combos)\n")
cat("Output files:\n")
cat("  ✅ output/tables/models.rds\n")
cat("  ✅ output/tables/predictions.rds\n")
cat("  ✅ output/tables/feature_importance.rds\n")
cat("  ✅ output/tables/logit_results.rds\n")

cat("✅ MODELING HOÀN TẤT!\n")
