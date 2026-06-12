# =============================================================================
# THÀNH TÀI — MODEL EVALUATION & COMPARISON
# File: R/evaluation.R
# Người phụ trách: Thành Tài
# Mô tả: Đánh giá, so sánh 3 mô hình hồi quy (LR, RF, XGBoost),
#         tạo bảng metrics, vẽ 4 biểu đồ trực quan hóa kết quả
# =============================================================================
# CHÚ Ý: Chỉ Thành Tài được chỉnh sửa file này!
# Input : output/tables/predictions.rds   (Đức Thắng tạo)
#         output/tables/feature_importance.rds (Đức Thắng tạo)
# Output: output/tables/eval_results.rds
#         output/figures/p_metrics_comparison.png
#         output/figures/p_actual_vs_predicted.png
#         output/figures/p_residuals.png
#         output/figures/p_feature_importance.png
# =============================================================================

# ── Thiết lập thư mục làm việc & đặt lại thư mục gốc của dự án cho gói 'here' ──
get_sourced_file <- function() {
  # 1. Kiểm tra nếu chạy bằng source()
  for (i in seq_len(sys.nframe())) {
    ofile <- sys.frame(i)$ofile
    if (!is.null(ofile)) return(ofile)
  }
  # 2. Kiểm tra nếu chạy trong RStudio line-by-line
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    path <- rstudioapi::getActiveDocumentContext()$path
    if (!is.null(path) && path != "") return(path)
  }
  return(NULL)
}
sourced_file <- get_sourced_file()
if (!is.null(sourced_file)) {
  setwd(dirname(dirname(sourced_file)))
}
if ("package:here" %in% search()) detach("package:here", unload = TRUE)
if (isNamespaceLoaded("here")) unloadNamespace("here")

library(dplyr)
library(tidyr)
library(tibble)
library(ggplot2)
library(gridExtra)
library(knitr)
library(kableExtra)
library(Metrics)
library(here)

# ── Nạp thiết lập chung (theme_rossmann, COLORS, packages) từ Quốc Anh ─────
source(here("R", "00_setup.R"))

cat("╔══════════════════════════════════════════════════════════╗\n")
cat("║  THÀNH TÀI — MODEL EVALUATION & COMPARISON             ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n\n")

# =============================================================================
# 1. ĐỌC KẾT QUẢ TỪ ĐỨC THẮNG (predictions & feature importance)
# =============================================================================
cat("━━━ 1. ĐỌC DỮ LIỆU ĐẦU VÀO ━━━\n")

preds <- readRDS(here("output", "tables", "predictions.rds"))
fi    <- readRDS(here("output", "tables", "feature_importance.rds"))

actual <- preds$actual

cat("[Thành Tài] Đã đọc predictions.rds:", length(actual), "quan sát\n")
cat("[Thành Tài] Đã đọc feature_importance.rds\n")
cat("  - RF features :", nrow(fi$rf), "biến\n")
cat("  - XGB features:", nrow(fi$xgb), "biến\n")

# =============================================================================
# 2. ĐỊNH NGHĨA HÀM ĐÁNH GIÁ (Metrics Functions)
# =============================================================================

# Hàm tính RMSPE (Root Mean Squared Percentage Error)
# Đây là thước đo chính thức của cuộc thi Kaggle Rossmann.
# Loại bỏ các quan sát có actual = 0 để tránh lỗi chia cho 0.
calc_rmspe <- function(actual, predicted) {
  mask <- actual > 0
  sqrt(mean(((actual[mask] - predicted[mask]) / actual[mask])^2))
}

# Hàm tính R² (Coefficient of Determination)
# Đo lường tỷ lệ phương sai của doanh số được giải thích bởi mô hình.
# R² = 1 là hoàn hảo, R² = 0 là mô hình không tốt hơn trung bình.
calc_r2 <- function(actual, predicted) {
  1 - sum((actual - predicted)^2) / sum((actual - mean(actual))^2)
}

# =============================================================================
# 3. BẢNG SO SÁNH 3 MÔ HÌNH (Metrics Comparison Table)
# =============================================================================
cat("\n━━━ 2. BẢNG SO SÁNH HIỆU SUẤT ━━━\n")

# Tính 4 chỉ số đánh giá cho mỗi mô hình:
#   - RMSE:  phạt nặng các sai số lớn
#   - MAE:   trung bình trị tuyệt đối sai số
#   - R²:    tỷ lệ phương sai giải thích được
#   - RMSPE: thước đo chính của Kaggle Rossmann
results <- tibble(
  Model = c("Linear Regression", "Random Forest", "XGBoost"),
  RMSE  = c(
    rmse(actual, preds$lm),
    rmse(actual, preds$rf),
    rmse(actual, preds$xgb)
  ),
  MAE = c(
    mae(actual, preds$lm),
    mae(actual, preds$rf),
    mae(actual, preds$xgb)
  ),
  R2 = c(
    calc_r2(actual, preds$lm),
    calc_r2(actual, preds$rf),
    calc_r2(actual, preds$xgb)
  ),
  RMSPE = c(
    calc_rmspe(actual, preds$lm),
    calc_rmspe(actual, preds$rf),
    calc_rmspe(actual, preds$xgb)
  )
) %>%
  arrange(RMSE)  # Sắp xếp theo RMSE tăng dần (mô hình tốt nhất lên đầu)

cat("\n── Bảng so sánh metrics ──\n")
print(
  kable(results,
        caption = "Bảng so sánh hiệu suất 3 mô hình",
        digits  = c(0, 2, 2, 4, 4)) %>%
    kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
)

# =============================================================================
# 4. BIỂU ĐỒ 1: Bar Chart So sánh Metrics (facet_wrap)
# =============================================================================
cat("\n━━━ 3. VẼ BIỂU ĐỒ SO SÁNH ━━━\n")

# Chuyển bảng results sang dạng dài (long format) để vẽ facet_wrap
results_long <- results %>%
  pivot_longer(
    cols      = c(RMSE, MAE, R2, RMSPE),
    names_to  = "Metric",
    values_to = "Value"
  ) %>%
  # Sắp xếp thứ tự hiển thị các metrics trên biểu đồ
  mutate(Metric = factor(Metric, levels = c("RMSE", "MAE", "R2", "RMSPE")))

p_metrics <- ggplot(results_long, aes(x = Model, y = Value, fill = Model)) +
  geom_col(alpha = 0.85, width = 0.7) +
  geom_text(aes(label = round(Value, 3)), vjust = -0.3, size = 3.2) +
  facet_wrap(~Metric, scales = "free_y") +
  labs(
    title    = "So sánh hiệu suất 3 mô hình hồi quy",
    subtitle = "RMSE & MAE: càng thấp càng tốt | R²: càng cao càng tốt | RMSPE: Kaggle metric",
    x = NULL, y = "Giá trị"
  ) +
  scale_fill_manual(values = COLORS$models) +
  theme_rossmann() +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 15, hjust = 1))

print(p_metrics)
ggsave(here("output", "figures", "p_metrics_comparison.png"), p_metrics,
       width = 10, height = 6, dpi = 150)
cat("[Thành Tài] Đã lưu: output/figures/p_metrics_comparison.png\n")

# =============================================================================
# 5. BIỂU ĐỒ 2: Actual vs Predicted — Scatter Plot (facet_wrap)
# =============================================================================

# Gom kết quả dự đoán của 3 mô hình vào 1 data frame duy nhất
comparison_df <- bind_rows(
  tibble(Actual = actual, Predicted = preds$lm,  Model = "Linear Regression"),
  tibble(Actual = actual, Predicted = preds$rf,  Model = "Random Forest"),
  tibble(Actual = actual, Predicted = preds$xgb, Model = "XGBoost")
) %>%
  mutate(Model = factor(Model, levels = c("Linear Regression", "Random Forest", "XGBoost")))

# Biểu đồ phân tán: mỗi điểm = 1 quan sát trong tập val
# Đường chéo 45° (dashed) = dự đoán hoàn hảo
# Điểm càng bám sát đường chéo → mô hình càng chính xác
p_pred <- ggplot(comparison_df, aes(x = Actual, y = Predicted, color = Model)) +
  geom_point(alpha = 0.2, size = 0.6) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              color = "black", linewidth = 0.5) +
  facet_wrap(~Model) +
  labs(
    title    = "Actual vs Predicted — 3 mô hình hồi quy",
    subtitle = "Đường chéo = dự đoán hoàn hảo | Điểm bám sát đường chéo = chính xác",
    x = "Giá trị thực (EUR)",
    y = "Giá trị dự đoán (EUR)"
  ) +
  scale_color_manual(values = COLORS$models) +
  theme_rossmann() +
  theme(legend.position = "none")

print(p_pred)
ggsave(here("output", "figures", "p_actual_vs_predicted.png"), p_pred,
       width = 12, height = 4, dpi = 150)
cat("[Thành Tài] Đã lưu: output/figures/p_actual_vs_predicted.png\n")

# =============================================================================
# 6. BIỂU ĐỒ 3: Residual Histogram — Phân phối sai số (facet_wrap)
# =============================================================================

# Tính residual (sai số) = Actual - Predicted
# Mô hình tốt: residual phân phối chuẩn, tập trung quanh 0
comparison_df <- comparison_df %>%
  mutate(Residual = Actual - Predicted)

p_resid <- ggplot(comparison_df, aes(x = Residual, fill = Model)) +
  geom_histogram(bins = 50, alpha = 0.75, color = "white", linewidth = 0.2) +
  facet_wrap(~Model, scales = "free_y") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 0.5) +
  labs(
    title    = "Phân phối sai số (Residuals) — 3 mô hình",
    subtitle = "Phân phối càng hẹp và tập trung quanh 0 → mô hình càng tốt",
    x = "Residual (Actual − Predicted)",
    y = "Tần suất"
  ) +
  scale_fill_manual(values = COLORS$models) +
  theme_rossmann() +
  theme(legend.position = "none")

print(p_resid)
ggsave(here("output", "figures", "p_residuals.png"), p_resid,
       width = 12, height = 4, dpi = 150)
cat("[Thành Tài] Đã lưu: output/figures/p_residuals.png\n")

# =============================================================================
# 7. BIỂU ĐỒ 4: Feature Importance — Top 10 (RF + XGBoost cạnh nhau)
# =============================================================================
cat("\n━━━ 4. FEATURE IMPORTANCE ━━━\n")

# Random Forest — sắp xếp theo Importance (Impurity) giảm dần
fi_rf_top10 <- head(fi$rf, 10)
p_fi_rf <- ggplot(fi_rf_top10,
                  aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_col(fill = COLORS$models[["Random Forest"]], alpha = 0.85) +
  coord_flip() +
  labs(
    title = "Top 10 Feature Importance",
    subtitle = "Random Forest (Impurity-based)",
    x = NULL, y = "Importance"
  ) +
  theme_rossmann()

# XGBoost — sắp xếp theo Gain giảm dần
fi_xgb_top10 <- head(fi$xgb, 10)
p_fi_xgb <- ggplot(fi_xgb_top10,
                   aes(x = reorder(Feature, Gain), y = Gain)) +
  geom_col(fill = COLORS$models[["XGBoost"]], alpha = 0.85) +
  coord_flip() +
  labs(
    title = "Top 10 Feature Importance",
    subtitle = "XGBoost (Gain-based)",
    x = NULL, y = "Gain"
  ) +
  theme_rossmann()

# Ghép 2 biểu đồ cạnh nhau bằng grid.arrange
p_fi_combined <- grid.arrange(p_fi_rf, p_fi_xgb, ncol = 2,
                               top = "So sánh Feature Importance — RF vs XGBoost")

ggsave(here("output", "figures", "p_feature_importance.png"), p_fi_combined,
       width = 14, height = 5, dpi = 150)
cat("[Thành Tài] Đã lưu: output/figures/p_feature_importance.png\n")

# In ra top 5 features chung giữa 2 mô hình
common_top5 <- intersect(
  head(fi$rf$Feature, 5),
  head(fi$xgb$Feature, 5)
)
cat("[Thành Tài] Top features chung (RF ∩ XGB):", paste(common_top5, collapse = ", "), "\n")

# =============================================================================
# 8. LƯU KẾT QUẢ ĐÁNH GIÁ
# =============================================================================
cat("\n━━━ 5. LƯU KẾT QUẢ ━━━\n")

saveRDS(list(
  results        = results,
  comparison_df  = comparison_df,
  fi_rf          = fi$rf,
  fi_xgb         = fi$xgb
), here("output", "tables", "eval_results.rds"))

cat("[Thành Tài] ✅ Đã lưu: output/tables/eval_results.rds\n")
cat("[Thành Tài] ✅ Biểu đồ đã xuất:\n")
cat("   • p_metrics_comparison.png    — So sánh 4 chỉ số (RMSE, MAE, R², RMSPE)\n")
cat("   • p_actual_vs_predicted.png   — Scatter Actual vs Predicted\n")
cat("   • p_residuals.png             — Phân phối sai số (Residuals)\n")
cat("   • p_feature_importance.png    — Top 10 Feature Importance (RF + XGB)\n")

# =============================================================================
# 9. TÓM TẮT KEY METRICS CHO SLIDE
# =============================================================================
best_model <- results %>% slice(1)

cat("\n╔══════════════════════════════════════════════════╗\n")
cat("║   KEY METRICS — MODEL EVALUATION (cho Slide)    ║\n")
cat("╠══════════════════════════════════════════════════╣\n")
cat(sprintf("║ Mô hình tốt nhất : %-29s║\n", best_model$Model))
cat(sprintf("║ RMSE              : %-29s║\n", round(best_model$RMSE, 2)))
cat(sprintf("║ MAE               : %-29s║\n", round(best_model$MAE, 2)))
cat(sprintf("║ R²                : %-29s║\n", round(best_model$R2, 4)))
cat(sprintf("║ RMSPE (Kaggle)    : %-29s║\n", round(best_model$RMSPE, 4)))
cat(sprintf("║ Số quan sát (val) : %-29s║\n", length(actual)))
cat("╠══════════════════════════════════════════════════╣\n")
cat(sprintf("║ Top features      : %-29s║\n",
            paste(head(common_top5, 3), collapse = ", ")))
cat("╚══════════════════════════════════════════════════╝\n")

cat("\n[Thành Tài] ✅ Model Evaluation hoàn tất!\n")
