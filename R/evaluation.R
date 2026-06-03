# =============================================================================
# THÀNH TÀI — MODEL EVALUATION & COMPARISON
# File: R/evaluation.R
# Người phụ trách: Thành Tài
# Mô tả: Đánh giá, so sánh 3 mô hình, biểu đồ kết quả
# =============================================================================
# CHÚ Ý: Chỉ Thành Tài được chỉnh sửa file này!
# Input: readRDS(here("output", "data", "predictions.rds"))
#        readRDS(here("output", "data", "feature_importance.rds"))
# =============================================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(knitr)
library(kableExtra)
library(Metrics)
library(here)

# --- Đọc predictions từ TV4 ---
preds <- readRDS(here("output", "data", "predictions.rds"))
fi    <- readRDS(here("output", "data", "feature_importance.rds"))

actual <- preds$actual

# =============================================================================
# 1. BẢNG SO SÁNH 3 MÔ HÌNH
# =============================================================================
cat("\n========== BẢNG SO SÁNH MÔ HÌNH ==========\n")

# Hàm tính RMSPE
calc_rmspe <- function(actual, predicted) {
  # Loại bỏ trường hợp actual = 0 để tránh chia cho 0
  mask <- actual > 0
  sqrt(mean(((actual[mask] - predicted[mask]) / actual[mask])^2))
}

# Hàm tính R²
calc_r2 <- function(actual, predicted) {
  1 - sum((actual - predicted)^2) / sum((actual - mean(actual))^2)
}

results <- tibble(
  Model = c("Linear Regression", "Random Forest", "XGBoost"),
  RMSE  = c(rmse(actual, preds$lm), rmse(actual, preds$rf), rmse(actual, preds$xgb)),
  MAE   = c(mae(actual, preds$lm),  mae(actual, preds$rf),  mae(actual, preds$xgb)),
  R2    = c(calc_r2(actual, preds$lm), calc_r2(actual, preds$rf), calc_r2(actual, preds$xgb)),
  RMSPE = c(calc_rmspe(actual, preds$lm), calc_rmspe(actual, preds$rf), calc_rmspe(actual, preds$xgb))
) %>%
  arrange(RMSE)

kable(results,
      caption = "Bảng so sánh hiệu suất 3 mô hình",
      digits  = 2) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"))

# =============================================================================
# 2. BAR CHART SO SÁNH METRICS
# =============================================================================
results_long <- results %>%
  pivot_longer(-Model, names_to = "Metric", values_to = "Value")

p_metrics <- ggplot(results_long, aes(x = Model, y = Value, fill = Model)) +
  geom_col(alpha = 0.85) +
  geom_text(aes(label = round(Value, 2)), vjust = -0.3, size = 3) +
  facet_wrap(~Metric, scales = "free_y") +
  labs(
    title = "So sánh hiệu suất 3 mô hình",
    x = NULL, y = "Giá trị"
  ) +
  scale_fill_manual(values = c("Linear Regression" = "#2196F3",
                                "Random Forest" = "#4CAF50",
                                "XGBoost" = "#FF9800")) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        legend.position = "none",
        axis.text.x = element_text(angle = 15, hjust = 1))

print(p_metrics)
ggsave(here("output", "figures", "p_metrics_comparison.png"), p_metrics,
       width = 10, height = 6, dpi = 150)

# =============================================================================
# 3. ACTUAL vs PREDICTED (facet_wrap)
# =============================================================================
comparison_df <- bind_rows(
  tibble(Actual = actual, Predicted = preds$lm,  Model = "Linear Regression"),
  tibble(Actual = actual, Predicted = preds$rf,  Model = "Random Forest"),
  tibble(Actual = actual, Predicted = preds$xgb, Model = "XGBoost")
)

p_pred <- ggplot(comparison_df, aes(x = Actual, y = Predicted, color = Model)) +
  geom_point(alpha = 0.2, size = 0.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black") +
  facet_wrap(~Model) +
  labs(
    title = "Actual vs Predicted — 3 mô hình",
    x = "Giá trị thực (EUR)", y = "Giá trị dự đoán (EUR)"
  ) +
  scale_color_manual(values = c("Linear Regression" = "#2196F3",
                                 "Random Forest" = "#4CAF50",
                                 "XGBoost" = "#FF9800")) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        legend.position = "none")

print(p_pred)
ggsave(here("output", "figures", "p_actual_vs_predicted.png"), p_pred,
       width = 12, height = 4, dpi = 150)

# =============================================================================
# 4. RESIDUAL HISTOGRAM
# =============================================================================
comparison_df <- comparison_df %>%
  mutate(Residual = Actual - Predicted)

p_resid <- ggplot(comparison_df, aes(x = Residual, fill = Model)) +
  geom_histogram(bins = 50, alpha = 0.7, color = "white") +
  facet_wrap(~Model, scales = "free_y") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
  labs(
    title = "Phân phối sai số (Residuals) — 3 mô hình",
    x = "Residual (Actual - Predicted)", y = "Tần suất"
  ) +
  scale_fill_manual(values = c("Linear Regression" = "#2196F3",
                                "Random Forest" = "#4CAF50",
                                "XGBoost" = "#FF9800")) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        legend.position = "none")

print(p_resid)
ggsave(here("output", "figures", "p_residuals.png"), p_resid,
       width = 12, height = 4, dpi = 150)

# =============================================================================
# 5. FEATURE IMPORTANCE — Top 10 (RF + XGBoost)
# =============================================================================
# RF importance
p_fi_rf <- ggplot(head(fi$rf, 10), aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_col(fill = "#4CAF50", alpha = 0.85) +
  coord_flip() +
  labs(
    title = "Top 10 Feature Importance — Random Forest",
    x = NULL, y = "Importance (Impurity)"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5))

# XGBoost importance
p_fi_xgb <- ggplot(head(fi$xgb, 10), aes(x = reorder(Feature, Gain), y = Gain)) +
  geom_col(fill = "#FF9800", alpha = 0.85) +
  coord_flip() +
  labs(
    title = "Top 10 Feature Importance — XGBoost",
    x = NULL, y = "Gain"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5))

p_fi_combined <- gridExtra::grid.arrange(p_fi_rf, p_fi_xgb, ncol = 2)
ggsave(here("output", "figures", "p_feature_importance.png"), p_fi_combined,
       width = 14, height = 5, dpi = 150)

# =============================================================================
# LƯU KẾT QUẢ ĐÁNH GIÁ
# =============================================================================
saveRDS(results, here("output", "data", "eval_results.rds"))

# --- Auto-extract key metrics cho slide ---
best_model <- results %>% slice(1)
cat("\n========== KEY METRICS CHO SLIDE ==========\n")
cat("Mô hình tốt nhất:", best_model$Model, "\n")
cat("RMSE:", round(best_model$RMSE, 2), "\n")
cat("MAE:",  round(best_model$MAE, 2), "\n")
cat("R²:",   round(best_model$R2, 4), "\n")
cat("RMSPE:", round(best_model$RMSPE, 4), "\n")

cat("\n[Thành Tài] ✅ Evaluation hoàn tất! Đã lưu: eval_results.rds\n")
