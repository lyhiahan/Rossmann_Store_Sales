# THÀNH TÀI — TIME SERIES ANALYSIS
# Người phụ trách: Thành Tài
# Mô tả: Phân tích chuỗi thời gian — STL Decomposition, ARIMA, ETS, Forecast
# Input : readRDS(here("data", "processed", "df_clean.rds"))
# Output: output/tables/time_series_results.rds
#         output/figures/p_ts_decomposition.png
#         output/figures/p_ts_arima_forecast.png
#         output/figures/p_ts_ets_forecast.png
#         output/figures/p_ts_comparison.png

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
library(forecast)
library(here)

#  Nạp thiết lập chung (theme_rossmann, COLORS, packages) từ Quốc Anh
source(here("R", "00_setup.R"))

#  Đọc dữ liệu sạch từ pipeline của Quốc Anh
df <- readRDS(here("data", "processed", "df_clean.rds"))

# 1. CHUẨN BỊ DỮ LIỆU CHUỖI THỜI GIAN
cat(" 1. CHUẨN BỊ DỮ LIỆU \n")

# Gộp nhóm (aggregate) doanh số trung bình theo ngày trên toàn bộ 50 cửa hàng.
# Mỗi dòng = 1 ngày duy nhất, với avg_sales là trung bình doanh số của tất cả
# cửa hàng mở cửa trong ngày đó.
daily_sales <- df %>%
  group_by(date) %>%
  summarise(
    avg_sales   = mean(sales),
    total_sales = sum(sales),
    n_stores    = n(),
    .groups     = "drop"
  ) %>%
  arrange(date)

cat("Chuỗi thời gian:", nrow(daily_sales), "ngày\n")
cat("Từ:", as.character(min(daily_sales$date)),
    "đến:", as.character(max(daily_sales$date)), "\n")
cat("Trung bình doanh số/ngày:",
    round(mean(daily_sales$avg_sales), 0), "EUR\n")

# Chuyển đổi sang đối tượng ts (time series) của R.
# frequency = 7 vì dữ liệu hàng ngày với chu kỳ mùa vụ tuần (7 ngày).
ts_daily <- ts(daily_sales$avg_sales, frequency = 7)

cat("ts object: length =", length(ts_daily),
    "| frequency =", frequency(ts_daily), "(weekly cycle)\n")

# 2. TIME SERIES DECOMPOSITION (STL)
cat("\n 2. STL DECOMPOSITION \n")

# STL (Seasonal and Trend decomposition using Loess) phân tách chuỗi thành:
#   - Trend:     xu hướng dài hạn (tăng/giảm tổng thể)
#   - Seasonal:  biến động tuần hoàn (chu kỳ 7 ngày)
#   - Remainder: phần dư/nhiễu (sự kiện bất thường như Giáng sinh)
decomp <- stl(ts_daily, s.window = "periodic")

cat("STL Decomposition hoàn tất\n")
cat("  - Trend:     xu hướng dài hạn\n")
cat("  - Seasonal:  chu kỳ tuần (7 ngày)\n")
cat("  - Remainder: phần dư (noise)\n")

# Biểu đồ phân tách STL — sử dụng theme_rossmann() của nhóm
p_decomp <- autoplot(decomp) +
  labs(title    = "STL Decomposition — Doanh số trung bình theo ngày",
       subtitle = "Store 1–50 | 08/2014 – 07/2015") +
  theme_rossmann()

print(p_decomp)
ggsave(here("output", "figures", "p_ts_decomposition.png"), p_decomp,
       width = 10, height = 8, dpi = 150)
cat("Đã lưu: output/figures/p_ts_decomposition.png\n")

# 3. CHIA TẬP TRAIN / TEST THEO TRỤC THỜI GIAN
cat("\n 3. CHIA TẬP DỮ LIỆU (CHRONOLOGICAL SPLIT) \n")

# QUAN TRỌNG: Đối với chuỗi thời gian, PHẢI chia theo thứ tự thời gian
# (80% đầu = Train, 20% cuối = Test), KHÔNG chia ngẫu nhiên.
# Sử dụng time(ts_daily)[index] thay vì c(1, n_train) để tránh lỗi
# "subscript out of bounds" khi frequency ≠ 1 hoặc 12.
n_ts    <- length(ts_daily)
n_train <- floor(0.8 * n_ts)

ts_train <- window(ts_daily, end   = time(ts_daily)[n_train])
ts_test  <- window(ts_daily, start = time(ts_daily)[n_train + 1])

cat("TS Train:", length(ts_train), "ngày (",
    round(length(ts_train) / n_ts * 100, 1), "%)\n")
cat("TS Test :", length(ts_test), "ngày (",
    round(length(ts_test)  / n_ts * 100, 1), "%)\n")

# 4. MÔ HÌNH ARIMA — auto.arima()
cat("\n 4. MÔ HÌNH ARIMA \n")

# auto.arima() tự động tìm bộ tham số (p, d, q)(P, D, Q)[m] tối ưu
# dựa trên tiêu chí AICc (Akaike Information Criterion corrected).
fit_arima <- auto.arima(ts_train)

cat("\nARIMA Model Summary\n")
cat("  Mô hình:", arimaorder(fit_arima)[1], ",",
    arimaorder(fit_arima)[2], ",", arimaorder(fit_arima)[3], "\n")
cat("  AICc   :", round(fit_arima$aicc, 2), "\n")
print(summary(fit_arima))

# Dự báo trên horizon = số ngày của tập Test
fc_arima <- forecast(fit_arima, h = length(ts_test))

# Biểu đồ ARIMA Forecast vs Actual
p_arima <- autoplot(fc_arima) +
  autolayer(ts_test, series = "Actual", color = COLORS$danger) +
  labs(title    = paste("ARIMA Forecast —", fit_arima),
       subtitle = paste("Horizon:", length(ts_test), "ngày"),
       x = "Thời gian", y = "Doanh số TB (EUR)") +
  scale_color_manual(values = c("Actual" = COLORS$danger)) +
  theme_rossmann() +
  theme(legend.position = "bottom")

print(p_arima)
ggsave(here("output", "figures", "p_ts_arima_forecast.png"), p_arima,
       width = 10, height = 5, dpi = 150)
cat("Đã lưu: output/figures/p_ts_arima_forecast.png\n")

# 5. MÔ HÌNH ETS — ets()
cat("\n 5. MÔ HÌNH ETS \n")

# ets() tự động chọn tổ hợp tối ưu cho 3 thành phần:
#   E (Error):    Additive (A) hoặc Multiplicative (M)
#   T (Trend):    None (N), Additive (A), hoặc Damped (Ad)
#   S (Seasonal): None (N), Additive (A), hoặc Multiplicative (M)
fit_ets <- ets(ts_train)

cat("\nETS Model Summary\n")
cat("  Phương pháp:", fit_ets$method, "\n")
cat("  AICc       :", round(fit_ets$aicc, 2), "\n")
print(summary(fit_ets))

# Dự báo
fc_ets <- forecast(fit_ets, h = length(ts_test))

# Biểu đồ ETS Forecast vs Actual
p_ets <- autoplot(fc_ets) +
  autolayer(ts_test, series = "Actual", color = COLORS$danger) +
  labs(title    = paste("ETS Forecast —", fit_ets$method),
       subtitle = paste("Horizon:", length(ts_test), "ngày"),
       x = "Thời gian", y = "Doanh số TB (EUR)") +
  scale_color_manual(values = c("Actual" = COLORS$danger)) +
  theme_rossmann() +
  theme(legend.position = "bottom")

print(p_ets)
ggsave(here("output", "figures", "p_ts_ets_forecast.png"), p_ets,
       width = 10, height = 5, dpi = 150)
cat("Đã lưu: output/figures/p_ts_ets_forecast.png\n")

# 6. ĐÁNH GIÁ & SO SÁNH ARIMA vs ETS
cat("\n 6. ĐÁNH GIÁ MÔ HÌNH TIME SERIES \n")

actual_ts    <- as.numeric(ts_test)
pred_arima   <- as.numeric(fc_arima$mean)
pred_ets     <- as.numeric(fc_ets$mean)

# Tính 3 chỉ số đánh giá trên tập Test
ts_results <- tibble(
  Model = c("ARIMA", "ETS"),
  RMSE  = c(
    sqrt(mean((actual_ts - pred_arima)^2)),
    sqrt(mean((actual_ts - pred_ets)^2))
  ),
  MAE = c(
    mean(abs(actual_ts - pred_arima)),
    mean(abs(actual_ts - pred_ets))
  ),
  MAPE = c(
    mean(abs((actual_ts - pred_arima) / actual_ts)) * 100,
    mean(abs((actual_ts - pred_ets)   / actual_ts)) * 100
  )
)

cat("\n Bảng so sánh metrics \n")
print(ts_results)

best_ts <- ts_results %>% slice_min(RMSE, n = 1)
cat("\n→ Mô hình Time Series tốt nhất:", best_ts$Model,
    "với RMSE =", round(best_ts$RMSE, 2),
    "| MAE =", round(best_ts$MAE, 2),
    "| MAPE =", round(best_ts$MAPE, 2), "%\n")

#  Biểu đồ so sánh Actual vs Forecast (cả 2 mô hình trên cùng 1 đồ thị)
comparison_ts <- tibble(
  Index  = seq_along(actual_ts),
  Actual = actual_ts,
  ARIMA  = pred_arima,
  ETS    = pred_ets
) %>%
  pivot_longer(
    cols      = c(ARIMA, ETS),
    names_to  = "Model",
    values_to = "Forecast"
  )

p_ts_compare <- ggplot(comparison_ts, aes(x = Index)) +
  geom_line(aes(y = Actual), color = "black", linewidth = 0.9, alpha = 0.9) +
  geom_line(aes(y = Forecast, color = Model), linewidth = 0.6, alpha = 0.8) +
  labs(
    title    = "Actual vs Forecast — ARIMA vs ETS",
    subtitle = paste("Test set:", length(ts_test), "ngày |",
                     "Best:", best_ts$Model, "(RMSE =", round(best_ts$RMSE, 2), ")"),
    x = "Ngày (test set)",
    y = "Doanh số TB (EUR)",
    color = "Mô hình"
  ) +
  scale_color_manual(values = c("ARIMA" = COLORS$models[["ARIMA"]],
                                "ETS"   = COLORS$models[["ETS"]])) +
  theme_rossmann() +
  theme(legend.position = "bottom")

print(p_ts_compare)
ggsave(here("output", "figures", "p_ts_comparison.png"), p_ts_compare,
       width = 10, height = 5, dpi = 150)
cat("Đã lưu: output/figures/p_ts_comparison.png\n")

# 7. LƯU KẾT QUẢ
cat("\n 7. LƯU KẾT QUẢ \n")

saveRDS(list(
  arima_model    = fit_arima,
  ets_model      = fit_ets,
  arima_forecast = fc_arima,
  ets_forecast   = fc_ets,
  ts_results     = ts_results,
  decomposition  = decomp,
  daily_sales    = daily_sales,
  best_model     = best_ts$Model
), here("output", "tables", "time_series_results.rds"))

cat("✅ Time Series Analysis hoàn tất!\n")
cat("✅ Đã lưu: output/tables/time_series_results.rds\n")
cat("✅ Biểu đồ đã xuất:\n")
cat("   • p_ts_decomposition.png  — STL Decomposition\n")
cat("   • p_ts_arima_forecast.png — ARIMA Forecast vs Actual\n")
cat("   • p_ts_ets_forecast.png   — ETS Forecast vs Actual\n")
cat("   • p_ts_comparison.png     — So sánh ARIMA vs ETS\n")


