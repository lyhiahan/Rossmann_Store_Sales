# =============================================================================
# THÀNH TÀI — TIME SERIES ANALYSIS
# File: R/time_series.R
# Người phụ trách: Thành Tài
# Mô tả: Phân tích chuỗi thời gian — Decomposition, ARIMA, ETS, Forecast
# =============================================================================
# CHÚ Ý: Chỉ Thành Tài được chỉnh sửa file này!
# Input: readRDS(here("output", "data", "df_clean.rds"))
# =============================================================================

library(dplyr)
library(ggplot2)
library(forecast)
library(here)

# --- Đọc dữ liệu ---
df <- readRDS(here("output", "data", "df_clean.rds"))

cat("╔══════════════════════════════════════════════════════════╗\n")
cat("║  THÀNH TÀI — TIME SERIES ANALYSIS                      ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n\n")

# =============================================================================
# 1. CHUẨN BỊ DỮ LIỆU CHUỖI THỜI GIAN
# =============================================================================
cat("━━━ 1. CHUẨN BỊ DỮ LIỆU ━━━\n")

# Aggregate doanh số trung bình theo ngày (tất cả 50 stores)
daily_sales <- df %>%
  group_by(date) %>%
  summarise(
    avg_sales   = mean(sales),
    total_sales = sum(sales),
    n_stores    = n(),
    .groups     = "drop"
  ) %>%
  arrange(date)

cat("[Thành Tài] Chuỗi thời gian:", nrow(daily_sales), "ngày\n")
cat("[Thành Tài] Từ:", as.character(min(daily_sales$date)),
    "đến:", as.character(max(daily_sales$date)), "\n")

# Tạo time series object (frequency = 7 vì dữ liệu hàng ngày, chu kỳ tuần)
ts_daily <- ts(daily_sales$avg_sales, frequency = 7)

cat("[Thành Tài] ts object created: frequency = 7 (weekly cycle)\n")

# =============================================================================
# 2. TIME SERIES DECOMPOSITION (STL)
# =============================================================================
cat("\n━━━ 2. DECOMPOSITION ━━━\n")

# STL Decomposition: phân tách trend, seasonal, remainder
decomp <- stl(ts_daily, s.window = "periodic")

cat("[Thành Tài] STL Decomposition hoàn tất\n")
cat("  - Trend: xu hướng dài hạn\n")
cat("  - Seasonal: chu kỳ tuần (7 ngày)\n")
cat("  - Remainder: phần dư (noise)\n")

# Plot decomposition
p_decomp <- autoplot(decomp) +
  labs(title = "STL Decomposition — Doanh số trung bình theo ngày",
       subtitle = "Store 1–50 | 08/2014 – 07/2015") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5))

print(p_decomp)
ggsave(here("output", "figures", "p_ts_decomposition.png"), p_decomp,
       width = 10, height = 8, dpi = 150)

# =============================================================================
# 3. MÔ HÌNH ARIMA — auto.arima()
# =============================================================================
cat("\n━━━ 3. MÔ HÌNH ARIMA ━━━\n")

# Chia train/test cho time series (80% train, 20% test)
n_ts     <- length(ts_daily)
n_train  <- floor(0.8 * n_ts)
ts_train <- window(ts_daily, end = c(1, n_train))
ts_test  <- window(ts_daily, start = c(1, n_train + 1))

cat("[Thành Tài] TS Train:", length(ts_train), "ngày | TS Test:", length(ts_test), "ngày\n")

# Auto ARIMA
fit_arima <- auto.arima(ts_train)
cat("\n--- ARIMA Model ---\n")
print(summary(fit_arima))

# Forecast
fc_arima <- forecast(fit_arima, h = length(ts_test))

# Plot ARIMA forecast
p_arima <- autoplot(fc_arima) +
  autolayer(ts_test, series = "Actual", color = "red") +
  labs(title = paste("ARIMA Forecast —", fit_arima),
       x = "Thời gian", y = "Doanh số TB (EUR)") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5))

print(p_arima)
ggsave(here("output", "figures", "p_ts_arima_forecast.png"), p_arima,
       width = 10, height = 5, dpi = 150)

# =============================================================================
# 4. MÔ HÌNH ETS — ets()
# =============================================================================
cat("\n━━━ 4. MÔ HÌNH ETS ━━━\n")

fit_ets <- ets(ts_train)
cat("\n--- ETS Model ---\n")
print(summary(fit_ets))

# Forecast
fc_ets <- forecast(fit_ets, h = length(ts_test))

# Plot ETS forecast
p_ets <- autoplot(fc_ets) +
  autolayer(ts_test, series = "Actual", color = "red") +
  labs(title = paste("ETS Forecast —", fit_ets$method),
       x = "Thời gian", y = "Doanh số TB (EUR)") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5))

print(p_ets)
ggsave(here("output", "figures", "p_ts_ets_forecast.png"), p_ets,
       width = 10, height = 5, dpi = 150)

# =============================================================================
# 5. ĐÁNH GIÁ & SO SÁNH ARIMA vs ETS
# =============================================================================
cat("\n━━━ 5. ĐÁNH GIÁ MÔ HÌNH TIME SERIES ━━━\n")

actual_ts <- as.numeric(ts_test)

# Metrics
ts_results <- tibble(
  Model = c("ARIMA", "ETS"),
  RMSE  = c(
    sqrt(mean((actual_ts - as.numeric(fc_arima$mean))^2)),
    sqrt(mean((actual_ts - as.numeric(fc_ets$mean))^2))
  ),
  MAE = c(
    mean(abs(actual_ts - as.numeric(fc_arima$mean))),
    mean(abs(actual_ts - as.numeric(fc_ets$mean)))
  ),
  MAPE = c(
    mean(abs((actual_ts - as.numeric(fc_arima$mean)) / actual_ts)) * 100,
    mean(abs((actual_ts - as.numeric(fc_ets$mean)) / actual_ts)) * 100
  )
)

cat("\n")
print(ts_results)

best_ts <- ts_results %>% slice_min(RMSE, n = 1)
cat("\n→ Mô hình Time Series tốt nhất:", best_ts$Model,
    "với RMSE =", round(best_ts$RMSE, 2), "\n")

# Plot so sánh Actual vs Forecast
comparison_ts <- tibble(
  Index  = seq_along(actual_ts),
  Actual = actual_ts,
  ARIMA  = as.numeric(fc_arima$mean),
  ETS    = as.numeric(fc_ets$mean)
) %>%
  tidyr::pivot_longer(-c(Index, Actual), names_to = "Model", values_to = "Forecast")

p_ts_compare <- ggplot(comparison_ts, aes(x = Index)) +
  geom_line(aes(y = Actual), color = "black", linewidth = 0.8) +
  geom_line(aes(y = Forecast, color = Model), linewidth = 0.6, alpha = 0.8) +
  labs(
    title = "Actual vs Forecast — ARIMA vs ETS",
    x = "Ngày (test set)", y = "Doanh số TB (EUR)"
  ) +
  scale_color_manual(values = c("ARIMA" = "#2196F3", "ETS" = "#FF9800")) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        legend.position = "bottom")

print(p_ts_compare)
ggsave(here("output", "figures", "p_ts_comparison.png"), p_ts_compare,
       width = 10, height = 5, dpi = 150)

# =============================================================================
# LƯU KẾT QUẢ
# =============================================================================
saveRDS(list(
  arima_model    = fit_arima,
  ets_model      = fit_ets,
  arima_forecast = fc_arima,
  ets_forecast   = fc_ets,
  ts_results     = ts_results,
  decomposition  = decomp
), here("output", "data", "time_series_results.rds"))

cat("\n[Thành Tài] ✅ Time Series Analysis hoàn tất!\n")
cat("[Thành Tài] ✅ Đã lưu: time_series_results.rds\n")
cat("[Thành Tài] ✅ Biểu đồ: p_ts_decomposition, p_ts_arima_forecast,",
    "p_ts_ets_forecast, p_ts_comparison\n")
