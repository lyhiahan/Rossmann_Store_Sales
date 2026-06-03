# =============================================================================
# TV3 — DATA VISUALIZATION
# File: R/tv3_visualization.R
# Người phụ trách: Thành viên 3
# Mô tả: 10 biểu đồ trực quan hóa dữ liệu bằng ggplot2 + plotly
# =============================================================================
# CHÚ Ý: Chỉ TV3 được chỉnh sửa file này!
# Input: readRDS(here("output", "data", "df_clean.rds"))
# =============================================================================

library(dplyr)
library(ggplot2)
library(ggcorrplot)
library(plotly)
library(scales)
library(gridExtra)
library(here)

# --- Đọc dữ liệu ---
df <- readRDS(here("output", "data", "df_clean.rds"))

# --- Theme chung cho tất cả biểu đồ ---
theme_rossman <- theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey40"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

# Bảng màu
colors_store <- c("a" = "#2196F3", "b" = "#E53935", "c" = "#4CAF50", "d" = "#FF9800")
colors_promo <- c("0" = "#90A4AE", "1" = "#E53935")

# =============================================================================
# PLOT 1: Line chart — Doanh số trung bình theo ngày (trend)
# =============================================================================
daily_avg <- df %>%
  group_by(date) %>%
  summarise(avg_sales = mean(sales), .groups = "drop")

p1 <- ggplot(daily_avg, aes(x = date, y = avg_sales)) +
  geom_line(color = "#2196F3", alpha = 0.5, linewidth = 0.3) +
  geom_smooth(method = "loess", color = "#E53935", se = TRUE, alpha = 0.2) +
  labs(
    title    = "Xu hướng doanh số trung bình theo ngày",
    subtitle = "Store 1–50 | 08/2014 – 07/2015",
    x = "Ngày", y = "Doanh số trung bình (EUR)"
  ) +
  scale_x_date(date_labels = "%b %Y", date_breaks = "2 months") +
  theme_rossman

print(p1)
ggsave(here("output", "figures", "p1_line_trend.png"), p1, width = 10, height = 5, dpi = 150)

# =============================================================================
# PLOT 2: Bar chart — Doanh số TB theo ngày trong tuần
# =============================================================================
dow_avg <- df %>%
  group_by(day_of_week) %>%
  summarise(avg_sales = mean(sales), .groups = "drop")

p2 <- ggplot(dow_avg, aes(x = day_of_week, y = avg_sales, fill = day_of_week)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = comma(round(avg_sales))), vjust = -0.5, size = 3) +
  labs(
    title = "Doanh số trung bình theo ngày trong tuần",
    x = "Ngày trong tuần (1=Thứ 2, 7=Chủ nhật)", y = "Doanh số TB (EUR)"
  ) +
  scale_fill_brewer(palette = "Set2") +
  theme_rossman

print(p2)
ggsave(here("output", "figures", "p2_bar_dayofweek.png"), p2, width = 8, height = 5, dpi = 150)

# =============================================================================
# PLOT 3: Box plot — Sales theo StoreType
# =============================================================================
p3 <- ggplot(df, aes(x = store_type, y = sales, fill = store_type)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.1) +
  labs(
    title = "Phân phối doanh số theo loại cửa hàng",
    x = "Store Type", y = "Sales (EUR)"
  ) +
  scale_fill_manual(values = colors_store) +
  theme_rossman

print(p3)
ggsave(here("output", "figures", "p3_boxplot_storetype.png"), p3, width = 8, height = 5, dpi = 150)

# =============================================================================
# PLOT 4: Histogram + Density — Phân phối Sales
# =============================================================================
p4 <- ggplot(df, aes(x = sales)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50,
                 fill = "#2196F3", alpha = 0.6, color = "white") +
  geom_density(color = "#E53935", linewidth = 1) +
  labs(
    title = "Phân phối doanh số (Histogram + Density)",
    x = "Sales (EUR)", y = "Mật độ"
  ) +
  theme_rossman

print(p4)
ggsave(here("output", "figures", "p4_histogram_density.png"), p4, width = 8, height = 5, dpi = 150)

# =============================================================================
# PLOT 5: Heatmap — Correlation Matrix
# =============================================================================
numeric_df <- df %>%
  select(sales, customers, competition_distance, sales_per_customer,
         month, week_of_year, is_weekend) %>%
  mutate(across(everything(), as.numeric))

cor_mat <- cor(numeric_df, use = "complete.obs")

p5 <- ggcorrplot(cor_mat,
                  type   = "lower",
                  lab    = TRUE,
                  lab_size = 3,
                  colors = c("#E53935", "white", "#1E88E5"),
                  title  = "Ma trận tương quan") +
  theme_rossman

print(p5)
ggsave(here("output", "figures", "p5_heatmap_correlation.png"), p5, width = 8, height = 7, dpi = 150)

# =============================================================================
# PLOT 6: Scatter plot — Customers vs Sales
# =============================================================================
p6 <- ggplot(df, aes(x = customers, y = sales)) +
  geom_point(alpha = 0.15, color = "#2196F3", size = 0.8) +
  geom_smooth(method = "lm", color = "#E53935", se = TRUE) +
  labs(
    title = "Mối quan hệ Khách hàng – Doanh số",
    x = "Số khách hàng", y = "Sales (EUR)"
  ) +
  theme_rossman

print(p6)
ggsave(here("output", "figures", "p6_scatter_customers_sales.png"), p6, width = 8, height = 5, dpi = 150)

# =============================================================================
# PLOT 7: Violin plot — Sales theo Promo
# =============================================================================
p7 <- ggplot(df, aes(x = promo, y = sales, fill = promo)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.15, fill = "white", alpha = 0.8) +
  labs(
    title = "Tác động khuyến mãi lên doanh số",
    x = "Khuyến mãi (0 = Không, 1 = Có)", y = "Sales (EUR)"
  ) +
  scale_fill_manual(values = colors_promo) +
  theme_rossman

print(p7)
ggsave(here("output", "figures", "p7_violin_promo.png"), p7, width = 8, height = 5, dpi = 150)

# =============================================================================
# PLOT 8: Faceted plot — Doanh số theo tháng chia theo StoreType
# =============================================================================
monthly_type <- df %>%
  group_by(month, store_type) %>%
  summarise(avg_sales = mean(sales), .groups = "drop")

p8 <- ggplot(monthly_type, aes(x = factor(month), y = avg_sales, fill = store_type)) +
  geom_col(position = "dodge") +
  facet_wrap(~store_type, scales = "free_y") +
  labs(
    title = "Doanh số trung bình theo tháng — chia theo Store Type",
    x = "Tháng", y = "Doanh số TB (EUR)"
  ) +
  scale_fill_manual(values = colors_store) +
  theme_rossman +
  theme(legend.position = "none")

print(p8)
ggsave(here("output", "figures", "p8_faceted_monthly.png"), p8, width = 10, height = 6, dpi = 150)

# =============================================================================
# PLOT 9: Stacked Area chart — Tổng doanh số theo StoreType
# =============================================================================
monthly_total <- df %>%
  mutate(year_month = floor_date(date, "month")) %>%
  group_by(year_month, store_type) %>%
  summarise(total_sales = sum(sales), .groups = "drop")

p9 <- ggplot(monthly_total, aes(x = year_month, y = total_sales, fill = store_type)) +
  geom_area(alpha = 0.7) +
  labs(
    title = "Tổng doanh số theo tháng — Stacked Area theo Store Type",
    x = "Tháng", y = "Tổng doanh số (EUR)"
  ) +
  scale_fill_manual(values = colors_store) +
  scale_x_date(date_labels = "%b %Y", date_breaks = "2 months") +
  scale_y_continuous(labels = comma) +
  theme_rossman

print(p9)
ggsave(here("output", "figures", "p9_stacked_area.png"), p9, width = 10, height = 5, dpi = 150)

# =============================================================================
# PLOT 10: Interactive Plotly — Doanh số theo ngày
# =============================================================================
p10_gg <- ggplot(daily_avg, aes(
    x = date, y = avg_sales,
    text = paste0("Ngày: ", date, "\nDoanh số TB: ", comma(round(avg_sales)))
  )) +
  geom_line(color = "#2196F3") +
  labs(
    title = "Doanh số trung bình theo ngày (Interactive)",
    x = "Ngày", y = "Doanh số TB (EUR)"
  ) +
  theme_rossman

p10 <- ggplotly(p10_gg, tooltip = "text")
print(p10)

cat("\n[TV3] ✅ Visualization hoàn tất! 10 biểu đồ đã được lưu vào output/figures/\n")
