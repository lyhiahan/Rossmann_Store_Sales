# =============================================================================
# ĐỨC THẮNG — DATA MODELING
# File: R/modeling.R
# Người phụ trách: Đức Thắng (ML Engineer)
# Mô tả: 3 mô hình dự đoán doanh số: Linear Regression, Random Forest, XGBoost
#         Có hyperparameter tuning cho RF và XGBoost
# =============================================================================
# CHÚ Ý: Chỉ Đức Thắng được chỉnh sửa file này!
# Input:  data/processed/train_data.rds  (Quốc Anh tạo — 70% train)
#         data/processed/val_data.rds    (Quốc Anh tạo — 30% validation)
# Output: output/tables/models.rds            → trained models (Thành Tài đọc)
#         output/tables/predictions.rds        → predictions + actual (Thành Tài đọc)
#         output/tables/feature_importance.rds → RF + XGBoost importance (Thành Tài đọc)
#         output/tables/logit_results.rds      → Logistic Regression classification results
# =============================================================================

library(dplyr)
library(caret)
library(ranger)
library(xgboost)
library(here)

cat("\n╔══════════════════════════════════════════════════════════╗\n")
cat("║  ĐỨC THẮNG — DATA MODELING                             ║\n")
cat("║  Linear Regression · Random Forest · XGBoost             ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n\n")

# =============================================================================
# TASK 2: ĐỌC DỮ LIỆU TRAIN/VAL TỪ QUỐC ANH (readRDS)
# =============================================================================
cat("━━━ TASK 2: ĐỌC DỮ LIỆU TRAIN/VAL ━━━\n")

train_data <- readRDS(here("data", "processed", "train_data.rds"))
test_data  <- readRDS(here("data", "processed", "val_data.rds"))

cat("[Đức Thắng] ✅ Đã đọc train_data.rds:", nrow(train_data), "dòng,",
    ncol(train_data), "cột\n")
cat("[Đức Thắng] ✅ Đã đọc val_data.rds:  ", nrow(test_data), "dòng,",
    ncol(test_data), "cột\n")

# Kiểm tra dữ liệu input
stopifnot("sales" %in% names(train_data))
stopifnot("sales" %in% names(test_data))
cat("[Đức Thắng] Sales range (train):", range(train_data$sales), "\n")
cat("[Đức Thắng] Sales range (val):  ", range(test_data$sales), "\n")

# =============================================================================
# TASK 1: prepare_features() — Encode categorical, chọn features
# =============================================================================
cat("\n━━━ TASK 1: CHUẨN BỊ FEATURES ━━━\n")

# Danh sách features cho modeling
# ⚠️ KHÔNG bao gồm sales_per_customer (Target Leakage: sales/customers → dự đoán sales)
# ⚠️ competition_open_months: -1 = không có đối thủ (mô hình cây tự xử lý)
feature_cols <- c("customers", "day_of_week", "promo", "state_holiday",
                  "school_holiday", "store_type", "assortment",
                  "competition_distance", "promo2", "month",
                  "week_of_year", "is_weekend",
                  "competition_open_months", "has_competition")

cat("[Đức Thắng] ⚠️ sales_per_customer ĐÃ BỊ LOẠI khỏi features (Target Leakage)\n")
cat("[Đức Thắng] ℹ️ customers được giữ để phục vụ phân tích khi đã biết số khách; nếu dự báo tương lai nên loại bỏ.\n")
cat("[Đức Thắng] Số features đầu vào:", length(feature_cols), "\n")

# Hàm encode categorical → numeric cho Random Forest và XGBoost
# ⚠️ BUG FIX: as.numeric(factor) trả về integer codes (1,2,3...),
#    KHÔNG phải giá trị gốc. Ví dụ: day_of_week factor(1,2,...,7) →
#    as.numeric() cho 1,2,...,7 đúng THỨ TỰ LEVEL chứ không phải giá trị.
#    Giải pháp: as.numeric(as.character(.)) cho biến có giá trị số gốc.
prepare_features <- function(df, feature_cols, factor_levels = NULL) {
  # Lọc chỉ các cột tồn tại trong data
  available_cols <- feature_cols[feature_cols %in% names(df)]

  if (length(available_cols) < length(feature_cols)) {
    missing <- setdiff(feature_cols, names(df))
    cat("[Đức Thắng] ⚠️ Cột không tồn tại (bỏ qua):", paste(missing, collapse = ", "), "\n")
  }

  df_features <- df %>% select(all_of(available_cols))

  # Convert factors → numeric ĐÚNG CÁCH
  # Biến có giá trị số gốc (day_of_week, promo, school_holiday): dùng as.character trước
  # Biến categorical thực sự (store_type, assortment, state_holiday): dùng integer codes
  for (col in names(df_features)) {
    if (is.factor(df_features[[col]])) {
      char_vals <- as.character(df_features[[col]])
      # Kiểm tra xem tất cả giá trị có phải số không
      num_vals <- suppressWarnings(as.numeric(char_vals))
      if (all(is.na(char_vals) | !is.na(num_vals))) {
        # Factor có giá trị số gốc → giữ giá trị số
        df_features[[col]] <- num_vals
      } else {
        # Factor categorical → dùng integer codes theo level của train để train/val nhất quán
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

# Đảm bảo train và test có cùng cột (consistency check)
common_cols <- intersect(names(train_X), names(test_X))
train_X <- train_X[, common_cols]
test_X  <- test_X[, common_cols]

cat("[Đức Thắng] ✅ Features đã encode:", ncol(train_X), "biến\n")
cat("[Đức Thắng] Features:", paste(names(train_X), collapse = ", "), "\n")
cat("[Đức Thắng] Train X:", nrow(train_X), "dòng | Val X:", nrow(test_X), "dòng\n")

# =============================================================================
# TASK 3: MÔ HÌNH 1 — LINEAR REGRESSION + summary()
# =============================================================================
cat("\n━━━ TASK 3: MÔ HÌNH 1 — LINEAR REGRESSION ━━━\n")
cat("========== MODEL 1: LINEAR REGRESSION ==========\n")

# Xây dựng formula động từ feature_cols có sẵn trong data
# Đảm bảo nhất quán giữa LM và các model khác
lm_features <- intersect(feature_cols, names(train_data))
lm_formula <- as.formula(paste("sales ~", paste(lm_features, collapse = " + ")))
cat("[Đức Thắng] LM Formula:", deparse(lm_formula), "\n")

model_lm <- lm(lm_formula, data = train_data)

cat("[Đức Thắng] --- LM Summary ---\n")
lm_summary <- summary(model_lm)
print(lm_summary)

cat("[Đức Thắng] LM R²:", round(lm_summary$r.squared, 4), "\n")
cat("[Đức Thắng] LM Adjusted R²:", round(lm_summary$adj.r.squared, 4), "\n")
cat("[Đức Thắng] LM Residual SE:", round(lm_summary$sigma, 2), "\n")

# Predictions trên validation set
pred_lm <- predict(model_lm, newdata = test_data)
pred_lm <- pmax(pred_lm, 0)  # Sales không thể âm

cat("[Đức Thắng] ✅ LR predictions — range:", round(range(pred_lm), 2), "\n")

# =============================================================================
# TASK 3B: LOGISTIC REGRESSION — HIGH SALES CLASSIFICATION
# =============================================================================
cat("\n━━━ TASK 3B: LOGISTIC REGRESSION — HIGH SALES CLASSIFICATION ━━━\n")
cat("========== MODEL 1B: LOGISTIC REGRESSION ==========\n")

# Logistic Regression không dự đoán trực tiếp sales, mà dự đoán xác suất
# một quan sát thuộc nhóm doanh thu cao (high_sales = 1).
sales_threshold <- 10000

train_data$high_sales <- ifelse(train_data$sales >= sales_threshold, 1, 0)
test_data$high_sales  <- ifelse(test_data$sales >= sales_threshold, 1, 0)

cat("[Đức Thắng] Sales threshold:", sales_threshold, "\n")

cat("[Đức Thắng] Train high_sales distribution:\n")
print(table(train_data$high_sales))

cat("[Đức Thắng] Val high_sales distribution:\n")
print(table(test_data$high_sales))

logit_features <- intersect(feature_cols, names(train_data))
missing_logit_features <- setdiff(feature_cols, logit_features)
if (length(missing_logit_features) > 0) {
  cat("[Đức Thắng] ⚠️ Logistic features không tồn tại (bỏ qua):",
      paste(missing_logit_features, collapse = ", "), "\n")
}

# Đảm bảo không đưa target/leakage vào feature của Logistic Regression.
leakage_cols <- c("sales", "sales_per_customer", "high_sales")
logit_features <- setdiff(logit_features, leakage_cols)

logit_formula <- as.formula(paste("high_sales ~", paste(logit_features, collapse = " + ")))
cat("[Đức Thắng] Logistic Regression Formula:", deparse(logit_formula), "\n")

model_logit <- glm(logit_formula, data = train_data, family = binomial)

cat("[Đức Thắng] --- Logistic Regression Summary ---\n")
logit_summary <- summary(model_logit)
print(logit_summary)

logit_odds_ratio <- exp(coef(model_logit))
cat("[Đức Thắng] --- Odds Ratio: exp(coef(model_logit)) ---\n")
print(logit_odds_ratio)

pred_logit_prob <- predict(model_logit, newdata = test_data, type = "response")
pred_logit_class <- ifelse(pred_logit_prob >= 0.5, 1, 0)

cat("[Đức Thắng] ✅ Logistic predicted probabilities — range:",
    round(range(pred_logit_prob), 4), "\n")
cat("[Đức Thắng] ✅ Logistic class threshold: 0.5\n")

logit_actual <- test_data$high_sales
logit_confusion_matrix <- table(
  Actual = factor(logit_actual, levels = c(0, 1)),
  Predicted = factor(pred_logit_class, levels = c(0, 1))
)

cat("[Đức Thắng] --- Logistic Confusion Matrix ---\n")
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

logit_metrics <- data.frame(
  Metric = c("Accuracy", "Precision", "Recall", "F1-score"),
  Value = c(logit_accuracy, logit_precision, logit_recall, logit_f1)
)

cat(sprintf("[Đức Thắng] Logistic Accuracy:  %.4f\n", logit_accuracy))
cat(sprintf("[Đức Thắng] Logistic Precision: %.4f\n", logit_precision))
cat(sprintf("[Đức Thắng] Logistic Recall:    %.4f\n", logit_recall))
cat(sprintf("[Đức Thắng] Logistic F1-score:  %.4f\n", logit_f1))

# =============================================================================
# TASK 4: MÔ HÌNH 2 — RANDOM FOREST (ranger) + importance + TUNING
# =============================================================================
cat("\n━━━ TASK 4: MÔ HÌNH 2 — RANDOM FOREST + TUNING ━━━\n")
cat("========== MODEL 2: RANDOM FOREST (ranger) ==========\n")

# --- Hyperparameter Tuning: thử nhiều giá trị mtry ---
n_features <- ncol(train_X)
mtry_candidates <- unique(c(
  max(1, floor(n_features / 3)),     # p/3 (regression default)
  max(1, floor(sqrt(n_features))),    # sqrt(p)
  max(1, floor(n_features / 2))      # p/2
))

cat("[Đức Thắng] Tuning mtry: thử", length(mtry_candidates), "giá trị:",
    paste(mtry_candidates, collapse = ", "), "\n")

best_oob_rmse <- Inf
best_mtry <- mtry_candidates[1]

for (m in mtry_candidates) {
  set.seed(42)
  rf_temp <- ranger(
    sales ~ .,
    data       = cbind(train_X, sales = train_y),
    num.trees  = 500,
    mtry       = m,
    importance = "impurity",
    seed       = 42,
    verbose    = FALSE
  )
  oob_rmse <- sqrt(rf_temp$prediction.error)
  cat("[Đức Thắng]   mtry =", m, "→ OOB RMSE:", round(oob_rmse, 2),
      "| OOB R²:", round(rf_temp$r.squared, 4), "\n")
  if (oob_rmse < best_oob_rmse) {
    best_oob_rmse <- oob_rmse
    best_mtry <- m
  }
}

cat("[Đức Thắng] ✅ Best mtry:", best_mtry, "(OOB RMSE:", round(best_oob_rmse, 2), ")\n")

# Train final RF với best mtry
set.seed(42)
model_rf <- ranger(
  sales ~ .,
  data       = cbind(train_X, sales = train_y),
  num.trees  = 500,
  mtry       = best_mtry,
  importance = "impurity",                   # Gini importance
  seed       = 42,
  verbose    = TRUE
)

cat("[Đức Thắng] RF OOB Prediction Error (MSE):", round(model_rf$prediction.error, 2), "\n")
cat("[Đức Thắng] RF OOB R²:", round(model_rf$r.squared, 4), "\n")
cat("[Đức Thắng] RF Num Trees:", model_rf$num.trees, "\n")
cat("[Đức Thắng] RF Mtry:", model_rf$mtry, "\n")

# Predictions trên validation set
pred_rf <- predict(model_rf, data = test_X)$predictions
pred_rf <- pmax(pred_rf, 0)

cat("[Đức Thắng] ✅ RF predictions — range:", round(range(pred_rf), 2), "\n")

# Feature Importance (RF)
rf_importance <- data.frame(
  Feature    = names(model_rf$variable.importance),
  Importance = model_rf$variable.importance,
  row.names  = NULL
) %>% arrange(desc(Importance))

cat("[Đức Thắng] --- Top 5 features (Random Forest) ---\n")
print(head(rf_importance, 5))

# =============================================================================
# TASK 5: MÔ HÌNH 3 — XGBOOST + xgb.cv() + GRID SEARCH
# =============================================================================
cat("\n━━━ TASK 5: MÔ HÌNH 3 — XGBOOST + GRID SEARCH ━━━\n")
cat("========== MODEL 3: XGBOOST ==========\n")

# Tạo DMatrix
dtrain <- xgb.DMatrix(data = as.matrix(train_X), label = train_y)
dtest  <- xgb.DMatrix(data = as.matrix(test_X),  label = test_y)

# --- Grid Search: thử nhiều tổ hợp hyperparameters ---
param_grid <- expand.grid(
  max_depth = c(4, 6, 8),
  eta       = c(0.05, 0.1, 0.2)
)

cat("[Đức Thắng] Grid Search:", nrow(param_grid), "tổ hợp hyperparameters\n")

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

  # Lấy best iteration
  best_iter_i <- cv_i$best_iteration
  if (is.null(best_iter_i) || length(best_iter_i) == 0 || best_iter_i <= 0) {
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

  # Lấy CV RMSE tại best iteration
  eval_log_i <- cv_i$evaluation_log
  rmse_col_i <- grep("test.*rmse.*mean", names(eval_log_i), value = TRUE)
  if (length(rmse_col_i) > 0) {
    cv_rmse_i <- eval_log_i[[rmse_col_i[1]]][best_iter_i]
  } else {
    cv_rmse_i <- Inf
  }

  cat("[Đức Thắng]   max_depth =", param_grid$max_depth[i],
      "| eta =", param_grid$eta[i],
      "| nrounds =", best_iter_i,
      "| CV RMSE:", round(cv_rmse_i, 2), "\n")

  if (cv_rmse_i < best_cv_rmse) {
    best_cv_rmse <- cv_rmse_i
    best_params  <- params_i
    best_nrounds_final <- best_iter_i
  }
}

cat("\n[Đức Thắng] ✅ Best XGBoost Params:\n")
cat("  max_depth:", best_params$max_depth, "\n")
cat("  eta:", best_params$eta, "\n")
cat("  subsample:", best_params$subsample, "\n")
cat("  colsample_bytree:", best_params$colsample_bytree, "\n")
cat("  min_child_weight:", best_params$min_child_weight, "\n")
cat("  Best nrounds (CV):", best_nrounds_final, "\n")
cat("  Best CV RMSE:", round(best_cv_rmse, 2), "\n")

# Train final model với best params
cat("\n[Đức Thắng] --- Training Final XGBoost Model ---\n")
model_xgb <- xgb.train(
  params        = best_params,
  data          = dtrain,
  nrounds       = best_nrounds_final,
  evals         = list(train = dtrain, val = dtest),
  print_every_n = 50,
  verbose       = 1
)

# =============================================================================
# TASK 6: predict() trên validation set (3 models)
# =============================================================================
cat("\n━━━ TASK 6: PREDICTIONS TRÊN VALIDATION SET ━━━\n")

# XGBoost predictions
pred_xgb <- predict(model_xgb, newdata = dtest)
pred_xgb <- pmax(pred_xgb, 0)

cat("[Đức Thắng] ✅ XGBoost predictions — range:", round(range(pred_xgb), 2), "\n")

# Feature Importance (XGBoost)
xgb_importance <- xgb.importance(model = model_xgb)
cat("[Đức Thắng] --- Top 5 features (XGBoost) ---\n")
print(head(xgb_importance, 5))

# Tổng kết predictions
cat("\n[Đức Thắng] ═══ TỔNG KẾT PREDICTIONS ═══\n")
cat("[Đức Thắng] Actual range:      ", round(range(test_y), 2), "\n")
cat("[Đức Thắng] LR predictions:    ", round(range(pred_lm), 2), "\n")
cat("[Đức Thắng] RF predictions:    ", round(range(pred_rf), 2), "\n")
cat("[Đức Thắng] XGBoost predictions:", round(range(pred_xgb), 2), "\n")

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

cat("\n[Đức Thắng] ═══ METRICS TRÊN VALIDATION SET ═══\n")
cat(sprintf("[Đức Thắng] %-20s RMSE: %10.2f | MAE: %10.2f | R²: %.4f | RMSPE: %.4f\n",
            "Linear Regression", rmse_lm, mae_lm, r2_lm, rmspe_lm))
cat(sprintf("[Đức Thắng] %-20s RMSE: %10.2f | MAE: %10.2f | R²: %.4f | RMSPE: %.4f\n",
            "Random Forest", rmse_rf, mae_rf, r2_rf, rmspe_rf))
cat(sprintf("[Đức Thắng] %-20s RMSE: %10.2f | MAE: %10.2f | R²: %.4f | RMSPE: %.4f\n",
            "XGBoost", rmse_xgb, mae_xgb, r2_xgb, rmspe_xgb))
cat("[Đức Thắng] 🏆 Best (RMSE):", c("LR", "RF", "XGB")[which.min(c(rmse_lm, rmse_rf, rmse_xgb))], "\n")
cat("[Đức Thắng] 🏆 Best (RMSPE):", c("LR", "RF", "XGB")[which.min(c(rmspe_lm, rmspe_rf, rmspe_xgb))], "\n")

# =============================================================================
# TASK 7: saveRDS() — models + predictions + feature importance
# =============================================================================
cat("\n━━━ TASK 7: LƯU KẾT QUẢ ━━━\n")

dir.create(here("output", "tables"), recursive = TRUE, showWarnings = FALSE)

# Lưu trained models
saveRDS(
  list(lm = model_lm, rf = model_rf, xgb = model_xgb, logit = model_logit),
  here("output", "tables", "models.rds")
)
cat("[Đức Thắng] ✅ Đã lưu: output/tables/models.rds (LM + RF + XGBoost + Logistic)\n")

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
cat("[Đức Thắng] ✅ Đã lưu: output/tables/predictions.rds (predictions + actual)\n")

# Lưu feature importance (cho Thành Tài vẽ biểu đồ)
saveRDS(
  list(rf = rf_importance, xgb = xgb_importance),
  here("output", "tables", "feature_importance.rds")
)
cat("[Đức Thắng] ✅ Đã lưu: output/tables/feature_importance.rds (RF + XGBoost)\n")

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
cat("[Đức Thắng] ✅ Đã lưu: output/tables/logit_results.rds (model_logit + metrics + confusion matrix + odds ratio)\n")

# =============================================================================
# TÓM TẮT
# =============================================================================
cat("\n╔══════════════════════════════════════════════════════════╗\n")
cat("║  📊 TÓM TẮT MODELING — ĐỨC THẮNG                      ║\n")
cat("╠══════════════════════════════════════════════════════════╣\n")
cat("║  Model 1: Linear Regression                             ║\n")
cat("║    → R²:", format(round(r2_lm, 4), width = 8),
    "| RMSE:", format(round(rmse_lm, 2), width = 10), "   ║\n")
cat("║  Model 1B: Logistic Regression (high_sales)             ║\n")
cat("║    → Accuracy:", format(round(logit_accuracy, 4), width = 6),
    "| F1:", format(round(logit_f1, 4), width = 6), "                    ║\n")
cat("║  Model 2: Random Forest (ranger, 500 trees, mtry =",
    format(best_mtry, width = 2), ") ║\n")
cat("║    → OOB R²:", format(round(model_rf$r.squared, 4), width = 6),
    "| RMSE:", format(round(rmse_rf, 2), width = 10), "   ║\n")
cat("║  Model 3: XGBoost (nrounds =", format(best_nrounds_final, width = 4), ")              ║\n")
cat("║    → CV Best  | RMSE:", format(round(rmse_xgb, 2), width = 10), "           ║\n")
cat("║                                                          ║\n")
cat("║  🏆 Best Model:", format(c("Linear Regression", "Random Forest", "XGBoost")[
    which.min(c(rmse_lm, rmse_rf, rmse_xgb))], width = 20), "             ║\n")
cat("║  Features:", format(ncol(train_X), width = 3), "biến (sales_per_customer loại bỏ) ║\n")
cat("║  Train:", format(nrow(train_X), big.mark = ",", width = 8),
    "| Val:", format(nrow(test_X), big.mark = ",", width = 8), "        ║\n")
cat("║  Tuning: RF mtry grid + XGB grid search (9 combos)      ║\n")
cat("╠══════════════════════════════════════════════════════════╣\n")
cat("║  Output files:                                           ║\n")
cat("║    ✅ output/tables/models.rds                           ║\n")
cat("║    ✅ output/tables/predictions.rds → Thành Tài          ║\n")
cat("║    ✅ output/tables/feature_importance.rds → Thành Tài   ║\n")
cat("║    ✅ output/tables/logit_results.rds                    ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n")
cat("[Đức Thắng] ✅ MODELING HOÀN TẤT!\n")
