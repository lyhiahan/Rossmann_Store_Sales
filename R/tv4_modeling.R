# =============================================================================
# TV4 — DATA MODELING
# File: R/tv4_modeling.R
# Người phụ trách: Thành viên 4
# Mô tả: 3 mô hình dự đoán: Linear Regression, Random Forest, XGBoost
# =============================================================================
# CHÚ Ý: Chỉ TV4 được chỉnh sửa file này!
# Input: readRDS(here("output", "data", "train_data.rds"))
#        readRDS(here("output", "data", "test_data.rds"))
# Output: saveRDS() models + predictions cho TV5
# =============================================================================

library(dplyr)
library(caret)
library(randomForest)
library(xgboost)
library(here)

# --- Đọc dữ liệu train/test (TV1 đã split) ---
train_data <- readRDS(here("output", "data", "train_data.rds"))
test_data  <- readRDS(here("output", "data", "test_data.rds"))

cat("[TV4] Train:", nrow(train_data), "dòng | Test:", nrow(test_data), "dòng\n")

# --- Chuẩn bị features ---
# Chọn features cho modeling (bỏ date, store, is_outlier, các cột không cần)
feature_cols <- c("customers", "day_of_week", "promo", "state_holiday",
                  "school_holiday", "store_type", "assortment",
                  "competition_distance", "promo2", "month",
                  "week_of_year", "is_weekend")

# Encode factors thành numeric cho XGBoost
prepare_features <- function(df, feature_cols) {
  df_features <- df %>% select(all_of(feature_cols))
  # Convert factors to numeric
  df_features <- df_features %>%
    mutate(across(where(is.factor), ~ as.numeric(as.factor(.))))
  return(as.data.frame(df_features))
}

train_X <- prepare_features(train_data, feature_cols)
train_y <- train_data$sales
test_X  <- prepare_features(test_data, feature_cols)
test_y  <- test_data$sales

# =============================================================================
# MÔ HÌNH 1: LINEAR REGRESSION
# =============================================================================
cat("\n========== MODEL 1: LINEAR REGRESSION ==========\n")

model_lm <- lm(sales ~ customers + day_of_week + promo + state_holiday +
                school_holiday + store_type + assortment +
                competition_distance + month + is_weekend,
                data = train_data)

cat("--- Summary ---\n")
print(summary(model_lm))

# Predictions
pred_lm <- predict(model_lm, newdata = test_data)
pred_lm <- pmax(pred_lm, 0)  # Sales không thể âm

cat("[TV4] LR predictions range:", range(pred_lm), "\n")

# =============================================================================
# MÔ HÌNH 2: RANDOM FOREST
# =============================================================================
cat("\n========== MODEL 2: RANDOM FOREST ==========\n")

# Sử dụng ranger cho tốc độ
library(ranger)

model_rf <- ranger(
  sales ~ .,
  data       = cbind(train_X, sales = train_y),
  num.trees  = 500,
  mtry       = floor(sqrt(ncol(train_X))),
  importance = "impurity",
  seed       = 42
)

cat("--- OOB R²:", model_rf$r.squared, "---\n")

# Predictions
pred_rf <- predict(model_rf, data = test_X)$predictions
pred_rf <- pmax(pred_rf, 0)

# Feature Importance
rf_importance <- data.frame(
  Feature    = names(model_rf$variable.importance),
  Importance = model_rf$variable.importance
) %>% arrange(desc(Importance))

cat("--- Top 5 features (RF) ---\n")
print(head(rf_importance, 5))

# =============================================================================
# MÔ HÌNH 3: XGBOOST
# =============================================================================
cat("\n========== MODEL 3: XGBOOST ==========\n")

# DMatrix
dtrain <- xgb.DMatrix(data = as.matrix(train_X), label = train_y)
dtest  <- xgb.DMatrix(data = as.matrix(test_X),  label = test_y)

# Parameters
params <- list(
  objective  = "reg:squarederror",
  max_depth  = 6,
  eta        = 0.1,
  subsample  = 0.8,
  colsample_bytree = 0.8,
  min_child_weight = 5
)

# Cross-validation để chọn nrounds tối ưu
cat("--- Cross-validation ---\n")
cv_result <- xgb.cv(
  params  = params,
  data    = dtrain,
  nrounds = 500,
  nfold   = 5,
  early_stopping_rounds = 20,
  print_every_n = 50,
  verbose = 1
)

best_nrounds <- cv_result$best_iteration
cat("Best nrounds:", best_nrounds, "\n")

# Train final model
model_xgb <- xgb.train(
  params  = params,
  data    = dtrain,
  nrounds = best_nrounds,
  watchlist = list(train = dtrain, test = dtest),
  print_every_n = 50
)

# Predictions
pred_xgb <- predict(model_xgb, newdata = dtest)
pred_xgb <- pmax(pred_xgb, 0)

# Feature Importance
xgb_importance <- xgb.importance(model = model_xgb)
cat("--- Top 5 features (XGBoost) ---\n")
print(head(xgb_importance, 5))

# =============================================================================
# LƯU KẾT QUẢ
# =============================================================================
saveRDS(list(lm = model_lm, rf = model_rf, xgb = model_xgb),
        here("output", "data", "models.rds"))

saveRDS(list(lm = pred_lm, rf = pred_rf, xgb = pred_xgb, actual = test_y),
        here("output", "data", "predictions.rds"))

saveRDS(list(rf = rf_importance, xgb = xgb_importance),
        here("output", "data", "feature_importance.rds"))

cat("\n[TV4] ✅ Modeling hoàn tất! Đã lưu: models.rds, predictions.rds, feature_importance.rds\n")
