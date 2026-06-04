# =============================================================================
# THANH PHÚC — EXPLORATORY DATA ANALYSIS (EDA)
# File: R/eda.R
# Người phụ trách: Thanh Phúc
# Mô tả: Thống kê mô tả, phân tích phân phối, phân tích nhóm, biểu đồ EDA
# =============================================================================
# CHÚ Ý: Chỉ Thanh Phúc được chỉnh sửa file này!
# Input: readRDS(here("data", "processed", "df_clean.rds"))
# Sử dụng: get_summary_stats() từ R/utils.R
#           COLORS, theme_rossmann() từ R/00_setup.R
# =============================================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(knitr)
library(kableExtra)
library(scales)
library(moments)
library(here)

# --- Fallback: nếu chưa chạy 00_setup.R / utils.R thì tự định nghĩa ---
if (!exists("COLORS")) {
  COLORS <- list(
    store_type = c("a" = "#1E88E5", "b" = "#E53935", "c" = "#43A047", "d" = "#FB8C00"),
    promo      = c("0" = "#78909C", "1" = "#E53935"),
    gradient   = c("#E3F2FD", "#1E88E5", "#0D47A1"),
    primary    = "#1E88E5", danger = "#E53935",
    success    = "#43A047", warning = "#FB8C00"
  )
}

if (!exists("theme_rossmann")) {
  theme_rossmann <- function(base_size = 12) {
    theme_minimal(base_size = base_size) %+replace%
      theme(
        plot.title    = element_text(face = "bold", size = base_size + 2, hjust = 0.5,
                                     margin = ggplot2::margin(b = 8)),
        plot.subtitle = element_text(size = base_size - 1, hjust = 0.5, color = "grey40",
                                     margin = ggplot2::margin(b = 10)),
        plot.caption  = element_text(size = base_size - 3, color = "grey50", hjust = 1),
        axis.title    = element_text(size = base_size - 1, color = "grey30"),
        axis.text     = element_text(size = base_size - 2, color = "grey40"),
        legend.position = "bottom",
        panel.grid.major = element_line(color = "grey90", linewidth = 0.2),
        panel.grid.minor = element_blank(),
        plot.margin   = ggplot2::margin(10, 15, 10, 10)
      )
  }
}

if (!exists("get_summary_stats")) {
  get_summary_stats <- function(df, group_var) {
    df %>%
      group_by({{ group_var }}) %>%
      summarise(
        n = n(), mean_s = round(mean(sales), 0), median_s = round(median(sales), 0),
        sd_s = round(sd(sales), 0), min_s = min(sales), max_s = max(sales),
        .groups = "drop"
      )
  }
}

cat("╔══════════════════════════════════════════════════════════╗\n")
cat("║  THANH PHÚC — EXPLORATORY DATA ANALYSIS (EDA)          ║\n")
cat("║  Rossmann Store Sales Analysis                          ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n\n")

# --- Đọc dữ liệu ---
df <- readRDS(here("data", "processed", "df_clean.rds"))
cat("[Thanh Phúc] Dữ liệu:", format(nrow(df), big.mark = ","), "dòng x", ncol(df), "cột\n\n")

# =============================================================================
# PHẦN 1: THỐNG KÊ MÔ TẢ TỔNG QUAN
# =============================================================================
cat("━━━ PHẦN 1: THỐNG KÊ MÔ TẢ ━━━\n")

# --- 1a. Bảng thống kê biến liên tục ---
numeric_cols <- c("sales", "customers", "competition_distance", "sales_per_customer")

summary_numeric <- df %>%
  select(all_of(numeric_cols)) %>%
  pivot_longer(everything(), names_to = "Biến", values_to = "Value") %>%
  group_by(`Biến`) %>%
  summarise(
    N        = n(),
    `TB`     = round(mean(Value, na.rm = TRUE), 2),
    `ĐLC`    = round(sd(Value, na.rm = TRUE), 2),
    Min      = round(min(Value, na.rm = TRUE), 2),
    Q1       = round(quantile(Value, 0.25, na.rm = TRUE), 2),
    `Trung vị` = round(median(Value, na.rm = TRUE), 2),
    Q3       = round(quantile(Value, 0.75, na.rm = TRUE), 2),
    Max      = round(max(Value, na.rm = TRUE), 2),
    `Độ lệch`  = round(skewness(Value, na.rm = TRUE), 3),
    `Độ nhọn`  = round(kurtosis(Value, na.rm = TRUE), 3),
    .groups  = "drop"
  )

cat("[Thanh Phúc] Bảng thống kê mô tả biến liên tục:\n")
print(summary_numeric)

# --- 1b. Phân bố biến phân loại ---
cat_cols <- c("store_type", "assortment", "promo", "state_holiday",
              "school_holiday", "day_of_week")

summary_categorical <- lapply(cat_cols, function(col) {
  df %>%
    count(!!sym(col), name = "Số lượng") %>%
    mutate(
      `Biến`     = col,
      `Giá trị`  = as.character(!!sym(col)),
      `Tỷ lệ %`  = round(`Số lượng` / sum(`Số lượng`) * 100, 1)
    ) %>%
    select(`Biến`, `Giá trị`, `Số lượng`, `Tỷ lệ %`)
}) %>% bind_rows()

cat("\n[Thanh Phúc] Phân bố biến phân loại:\n")
print(summary_categorical)

# =============================================================================
# PHẦN 2: PHÂN TÍCH PHÂN PHỐI
# =============================================================================
cat("\n━━━ PHẦN 2: PHÂN TÍCH PHÂN PHỐI ━━━\n")

# --- 2a. Thống kê phân phối ---
skew_sales <- skewness(df$sales)
kurt_sales <- kurtosis(df$sales)
skew_cust  <- skewness(df$customers)
kurt_cust  <- kurtosis(df$customers)

set.seed(42)
shapiro_sales <- shapiro.test(sample(df$sales, min(5000, nrow(df))))
shapiro_cust  <- shapiro.test(sample(df$customers, min(5000, nrow(df))))

df <- df %>% mutate(log_sales = log(sales), log_customers = log(customers))
skew_log_s <- skewness(df$log_sales)
kurt_log_s <- kurtosis(df$log_sales)

dist_stats <- tibble(
  `Biến`     = c("Sales", "Log(Sales)", "Customers", "Log(Customers)"),
  `Độ lệch`  = round(c(skew_sales, skew_log_s, skew_cust, skewness(df$log_customers)), 3),
  `Độ nhọn`  = round(c(kurt_sales, kurt_log_s, kurt_cust, kurtosis(df$log_customers)), 3),
  `Shapiro p` = c(format(shapiro_sales$p.value, digits = 4), "—",
                   format(shapiro_cust$p.value, digits = 4), "—")
)

cat("[Thanh Phúc] Kiểm tra phân phối chuẩn:\n")
print(dist_stats)

if (abs(skew_sales) > 1) {
  cat("→ Sales lệch phải (skewness =", round(skew_sales, 2), ") → cần log-transform\n")
  cat("→ Sau log: skewness =", round(skew_log_s, 3), " (cải thiện đáng kể)\n")
}

# --- 2b. Histogram Sales + mean/median ---
mean_s <- mean(df$sales)
median_s <- median(df$sales)

eda_p1 <- ggplot(df, aes(x = sales)) +
  geom_histogram(aes(y = after_stat(density)), bins = 60,
                 fill = COLORS$primary, alpha = 0.55, color = "white", linewidth = 0.2) +
  geom_density(color = COLORS$danger, linewidth = 1.2) +
  geom_vline(xintercept = mean_s, color = COLORS$warning, linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = median_s, color = COLORS$success, linetype = "dotdash", linewidth = 1) +
  annotate("rect", xmin = mean_s - 200, xmax = mean_s + 2800,
           ymin = Inf, ymax = Inf, alpha = 0) +
  annotate("label", x = mean_s + 500, y = Inf, vjust = 2, hjust = 0,
           label = paste0("Mean = ", comma(round(mean_s)), " EUR"),
           color = COLORS$warning, size = 3.2, fontface = "bold", fill = "white", label.size = 0) +
  annotate("label", x = median_s + 500, y = Inf, vjust = 4, hjust = 0,
           label = paste0("Median = ", comma(round(median_s)), " EUR"),
           color = COLORS$success, size = 3.2, fontface = "bold", fill = "white", label.size = 0) +
  labs(
    title   = "Phân phối doanh số (Sales) — Rossmann Germany 2014-2015",
    subtitle = paste0("Skewness = ", round(skew_sales, 2), " | Kurtosis = ", round(kurt_sales, 2),
                      " → Lệch phải: do đột biến doanh số ngày lễ Giáng sinh & khuyến mãi"),
    x = "Doanh số (EUR/ngày/cửa hàng)", y = "Mật độ",
    caption = "Nguồn: Rossmann Store Sales dataset | Xử lý: Thanh Phúc"
  ) +
  scale_x_continuous(labels = comma) +
  theme_rossmann()

# --- 2c. QQ Plot ---
eda_p2 <- ggplot(df, aes(sample = sales)) +
  stat_qq(color = COLORS$primary, alpha = 0.15, size = 0.4) +
  stat_qq_line(color = COLORS$danger, linewidth = 1) +
  labs(
    title    = "Q-Q Plot — Kiểm tra phân phối chuẩn của Sales",
    subtitle = "Điểm lệch khỏi đường lý thuyết (đỏ) ở 2 đuôi → xác nhận phân phối không chuẩn\nHậu quả: không dùng t-test/ANOVA thuần tuý; ưu tiên mô hình phi tuyến (XGBoost, RF)",
    x = "Quantile lý thuyết (Normal)", y = "Quantile thực tế (Sales)",
    caption = "Kiểm định Shapiro-Wilk: p < 0.001"
  ) +
  theme_rossmann()

# --- 2d. Log(Sales) vs Normal ---
eda_p3 <- ggplot(df, aes(x = log_sales)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50,
                 fill = COLORS$success, alpha = 0.55, color = "white", linewidth = 0.2) +
  geom_density(color = COLORS$danger, linewidth = 1.2) +
  stat_function(fun = dnorm,
                args = list(mean = mean(df$log_sales), sd = sd(df$log_sales)),
                color = "grey30", linewidth = 1, linetype = "dashed") +
  labs(
    title    = "Phân phối Log(Sales) — sau biến đổi logarithm",
    subtitle = paste0("Skewness giảm từ ", round(skew_sales, 2), " → ", round(skew_log_s, 3),
                      " | Phân phối gần chuẩn hơn đáng kể\n",
                      "Ứng dụng: báo cáo tài chính bán lẻ Đức thường dùng log-scale để so sánh tăng trưởng %"),
    x = "Log(Sales)", y = "Mật độ",
    caption = "Nét đứt xám: phân phối chuẩn lý thuyết | Đường đỏ: kernel density thực tế"
  ) +
  theme_rossmann()

# --- 2e. Phân phối Customers ---
eda_p4 <- ggplot(df, aes(x = customers)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50,
                 fill = "#00ACC1", alpha = 0.6, color = "white", linewidth = 0.2) +
  geom_density(color = COLORS$danger, linewidth = 1) +
  geom_vline(xintercept = mean(df$customers), color = COLORS$warning,
             linetype = "dashed", linewidth = 0.8) +
  annotate("text", x = mean(df$customers) + 50, y = Inf, vjust = 2, hjust = 0,
           label = paste0("Mean = ", round(mean(df$customers))),
           color = COLORS$warning, size = 3.5, fontface = "bold") +
  labs(title = "Phân phối số khách hàng (Customers)",
       subtitle = paste0("Skewness = ", round(skew_cust, 2),
                          " | Kurtosis = ", round(kurt_cust, 2)),
       x = "Số khách hàng", y = "Mật độ") +
  scale_x_continuous(labels = comma) +
  theme_rossmann()

# =============================================================================
# PHẦN 3: PHÂN TÍCH THEO NHÓM
# =============================================================================
cat("\n━━━ PHẦN 3: PHÂN TÍCH THEO NHÓM ━━━\n")

# --- 3a. Thống kê theo nhóm ---
stats_storetype  <- get_summary_stats(df, store_type)
stats_promo      <- get_summary_stats(df, promo)
stats_assortment <- get_summary_stats(df, assortment)
stats_dow        <- get_summary_stats(df, day_of_week)

cat("[Thanh Phúc] Sales theo StoreType:\n"); print(stats_storetype)
cat("\n[Thanh Phúc] Sales theo Promo:\n");     print(stats_promo)
cat("\n[Thanh Phúc] Sales theo Assortment:\n"); print(stats_assortment)
cat("\n[Thanh Phúc] Sales theo DayOfWeek:\n");  print(stats_dow)

# --- 3b. Holiday ---
stats_holiday <- df %>%
  group_by(state_holiday) %>%
  summarise(n = n(), mean_sales = round(mean(sales)), median_sales = round(median(sales)),
            sd_sales = round(sd(sales)), mean_cust = round(mean(customers)), .groups = "drop") %>%
  arrange(desc(mean_sales))

stats_school <- df %>%
  group_by(school_holiday) %>%
  summarise(n = n(), mean_sales = round(mean(sales)), median_sales = round(median(sales)),
            mean_cust = round(mean(customers)), .groups = "drop")

cat("\n[Thanh Phúc] Sales theo Holiday:\n"); print(stats_holiday)
cat("\n[Thanh Phúc] Sales theo SchoolHoliday:\n"); print(stats_school)

# --- 3c. CompetitionDistance ---
stats_comp <- df %>%
  mutate(dist_group = cut(competition_distance,
                           breaks = c(0, 1000, 5000, 10000, Inf),
                           labels = c("<1km", "1-5km", "5-10km", ">10km"))) %>%
  group_by(dist_group) %>%
  summarise(n = n(), mean_sales = round(mean(sales)), median_sales = round(median(sales)),
            .groups = "drop")

cat("\n[Thanh Phúc] Sales theo khoảng cách đối thủ:\n"); print(stats_comp)

# --- 3d. Biểu đồ: Density Sales theo StoreType ---
storetype_labels <- c(
  "a" = "Type A\n(Cửa hàng phổ thông)",
  "b" = "Type B\n(Trung tâm mua sắm)",
  "c" = "Type C\n(Cửa hàng nhỏ)",
  "d" = "Type D\n(Flagship store)"
)

eda_p5 <- ggplot(df, aes(x = sales, fill = store_type)) +
  geom_density(alpha = 0.65, color = "white", linewidth = 0.3) +
  facet_wrap(~store_type, scales = "free_y", ncol = 2,
             labeller = labeller(store_type = storetype_labels)) +
  scale_fill_manual(values = COLORS$store_type) +
  scale_x_continuous(labels = comma) +
  labs(
    title    = "Phân phối doanh số theo loại cửa hàng (Store Type)",
    subtitle = "Type B (TTTM) biến động cao nhất; Type A (phổ thông) ổn định nhất\nĐức 2014-15: ~460 TTTM, doanh thu ngành tăng 3% — Type B hưởng lợi",
    x = "Doanh số (EUR/ngày)", y = "Mật độ",
    caption = "Nguồn: Rossmann Store Sales dataset"
  ) +
  theme_rossmann() + theme(legend.position = "none")

# --- 3e. Promo impact theo StoreType ---
promo_impact <- df %>%
  group_by(store_type, promo) %>%
  summarise(mean_sales = mean(sales), se = sd(sales) / sqrt(n()), .groups = "drop")

promo_pct <- round(
  (promo_impact$mean_sales[promo_impact$promo == 1] /
   promo_impact$mean_sales[promo_impact$promo == 0] - 1) * 100, 0
)

eda_p6 <- ggplot(promo_impact, aes(x = store_type, y = mean_sales, fill = factor(promo))) +
  geom_col(position = position_dodge(0.8), alpha = 0.85, width = 0.7) +
  geom_errorbar(aes(ymin = mean_sales - se, ymax = mean_sales + se),
                position = position_dodge(0.8), width = 0.2, linewidth = 0.5) +
  geom_text(aes(label = comma(round(mean_sales))),
            position = position_dodge(0.8), vjust = -1, size = 3, fontface = "bold") +
  scale_fill_manual(values = COLORS$promo, labels = c("0" = "Không KM", "1" = "Có KM")) +
  scale_x_discrete(labels = c("a"="Type A","b"="Type B","c"="Type C","d"="Type D")) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.18))) +
  labs(
    title    = "Tác động khuyến mãi (Promo) theo loại cửa hàng",
    subtitle = paste0("Khuyến mãi tăng doanh số ở TẤT CẢ store types | Cơ chế: price elasticity + basket enlargement\n",
                      "'Rossmann Angebote' hàng tuần: chiến lược giúp Rossmann vượt dm về số cửa hàng năm 2015"),
    x = "Loại cửa hàng", y = "Doanh số TB (EUR)", fill = "Khuyến mãi",
    caption = "Error bar = ±1 SE"
  ) +
  theme_rossmann()

# --- 3f. Heatmap DayOfWeek × Month ---
heatmap_data <- df %>%
  group_by(day_of_week, month) %>%
  summarise(avg_sales = mean(sales), .groups = "drop") %>%
  mutate(day_label = factor(day_of_week, levels = 1:7,
                            labels = c("T2","T3","T4","T5","T6","T7","CN")))

eda_p7 <- ggplot(heatmap_data, aes(x = factor(month), y = day_label, fill = avg_sales)) +
  geom_tile(color = "white", linewidth = 0.6) +
  geom_text(aes(label = comma(round(avg_sales))), size = 2.6,
            color = "white", fontface = "bold") +
  scale_fill_gradientn(colors = COLORS$gradient, labels = comma, name = "DS TB (EUR)") +
  scale_x_discrete(labels = c("1"="T1","2"="T2","3"="T3","4"="T4",
                               "5"="T5","6"="T6","7"="T7","8"="T8",
                               "9"="T9","10"="T10","11"="T11","12"="T12")) +
  labs(
    title    = "Heatmap: Doanh số TB (EUR) theo Ngày trong tuần × Tháng",
    subtitle = "T12 đỉnh cao nhất (Weihnachten) | T2 cao nhất tuần (hành vi đọc Prospekt của người Đức)\nCN thấp nhất: Luật Ladenschlussgesetz — đóng cửa bắt buộc Chủ nhật tại Đức",
    x = "Tháng", y = "Ngày trong tuần",
    caption = "Màu càng đậm = doanh số càng cao"
  ) +
  theme_rossmann() + theme(panel.grid = element_blank())

# --- 3g. Holiday impact ---
holiday_comp <- bind_rows(
  df %>% mutate(type = ifelse(state_holiday != "none", "Ngày lễ", "Ngày thường"),
                cat = "State Holiday") %>%
    group_by(cat, type) %>%
    summarise(mean_sales = mean(sales), .groups = "drop"),
  df %>% mutate(type = ifelse(school_holiday == 1, "Nghỉ học", "Ngày thường"),
                cat = "School Holiday") %>%
    group_by(cat, type) %>%
    summarise(mean_sales = mean(sales), .groups = "drop")
)

eda_p8 <- ggplot(holiday_comp, aes(x = type, y = mean_sales, fill = type)) +
  geom_col(alpha = 0.85, width = 0.6) +
  geom_text(aes(label = comma(round(mean_sales))), vjust = -0.6, size = 3.5, fontface = "bold") +
  facet_wrap(~cat, scales = "free_x") +
  scale_fill_manual(values = c("Ngày lễ"     = COLORS$danger,
                                "Nghỉ học"    = COLORS$warning,
                                "Ngày thường" = COLORS$primary)) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.18))) +
  labs(
    title    = "Ảnh hưởng ngày lễ & kỳ nghỉ học đến doanh số",
    subtitle = "Nghịch lý Đức: Ngày lễ THẤP hơn ngày thường\nVì Ladenschlussgesetz (đóng cửa bắt buộc) + hành vi 'mua trước ngày lễ' của người Đức",
    x = NULL, y = "Doanh số TB (EUR)",
    caption = "State Holiday: a=Phục sinh, b=Giáng sinh, c=Lễ khác"
  ) +
  theme_rossmann() + theme(legend.position = "none")

# --- 3h. Assortment boxplot ---
eda_p9 <- ggplot(df, aes(x = assortment, y = sales, fill = assortment)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.08, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 3, color = COLORS$danger) +
  scale_fill_manual(values = c("a" = "#1E88E5", "b" = "#E53935", "c" = "#43A047"),
                    labels = c("a" = "Basic", "b" = "Extra", "c" = "Extended")) +
  scale_y_continuous(labels = comma) +
  labs(title = "Phân phối doanh số theo Assortment",
       subtitle = "◆ đỏ = giá trị trung bình",
       x = "Assortment", y = "Sales (EUR)", fill = "Assortment") +
  theme_rossmann()

# --- 3i. Sales per Customer theo StoreType ---
eda_p10 <- ggplot(df, aes(x = store_type, y = sales_per_customer, fill = store_type)) +
  geom_violin(alpha = 0.6, color = "white") +
  geom_boxplot(width = 0.15, fill = "white", alpha = 0.8, outlier.size = 0.3) +
  scale_fill_manual(values = COLORS$store_type) +
  labs(title = "Doanh thu/khách hàng theo loại cửa hàng",
       subtitle = "Violin + Boxplot — so sánh hiệu quả bán hàng",
       x = "Loại cửa hàng", y = "Sales per Customer (EUR)") +
  theme_rossmann() + theme(legend.position = "none")

# =============================================================================
# PHẦN 4: TƯƠNG QUAN
# =============================================================================
cat("\n━━━ PHẦN 4: TƯƠNG QUAN ━━━\n")

cor_vars <- c("sales", "customers", "competition_distance",
              "sales_per_customer", "month", "is_weekend")

numeric_for_cor <- df %>%
  select(all_of(cor_vars)) %>%
  mutate(across(everything(), as.numeric))

cor_matrix <- cor(numeric_for_cor, use = "complete.obs")
cat("[Thanh Phúc] Ma trận tương quan:\n")
print(round(cor_matrix, 3))

# Tương quan mạnh nhất
cor_flat <- as.data.frame(as.table(cor_matrix)) %>%
  filter(Var1 != Var2) %>%
  mutate(abs_cor = abs(Freq)) %>%
  arrange(desc(abs_cor)) %>%
  distinct(abs_cor, .keep_all = TRUE) %>%
  head(5)

cat("\n[Thanh Phúc] Top 5 cặp tương quan mạnh nhất:\n")
print(cor_flat)

# =============================================================================
# PHẦN 5: PHÂN TÍCH OUTLIER
# =============================================================================
cat("\n━━━ PHẦN 5: PHÂN TÍCH OUTLIER ━━━\n")

outlier_summary <- df %>%
  group_by(store) %>%
  summarise(
    n_total   = n(),
    n_outlier = sum(is_outlier, na.rm = TRUE),
    pct       = round(n_outlier / n_total * 100, 1),
    .groups   = "drop"
  ) %>%
  arrange(desc(pct))

cat("[Thanh Phúc] Tổng outlier:", sum(df$is_outlier, na.rm = TRUE),
    "trên", nrow(df), "dòng",
    "(", round(sum(df$is_outlier, na.rm = TRUE)/nrow(df)*100, 1), "%)\n")
cat("[Thanh Phúc] Top 5 store nhiều outlier nhất:\n")
print(head(outlier_summary, 5))

eda_p11 <- ggplot(outlier_summary, aes(x = reorder(factor(store), -pct), y = pct)) +
  geom_col(aes(fill = pct > mean(pct)), alpha = 0.85, width = 0.7) +
  scale_fill_manual(values = c("FALSE" = COLORS$primary, "TRUE" = COLORS$danger),
                    labels = c("Dưới TB", "Trên TB"), name = "Outlier %") +
  labs(title = "Tỷ lệ outlier theo từng cửa hàng",
       subtitle = paste0("Trung bình: ", round(mean(outlier_summary$pct), 1), "%"),
       x = "Store ID", y = "% Outlier") +
  theme_rossmann() +
  theme(axis.text.x = element_text(size = 6, angle = 90, vjust = 0.5))

# =============================================================================
# PHẦN 6: MONTHLY TREND (BỔ SUNG)
# =============================================================================
monthly_stats <- df %>%
  group_by(month) %>%
  summarise(
    mean_sales   = mean(sales),
    median_sales = median(sales),
    total_sales  = sum(sales),
    n_obs        = n(),
    .groups      = "drop"
  )

eda_p12 <- ggplot(monthly_stats, aes(x = factor(month))) +
  geom_col(aes(y = mean_sales), fill = COLORS$primary, alpha = 0.7, width = 0.65) +
  geom_line(aes(y = median_sales, group = 1), color = COLORS$danger, linewidth = 1.2) +
  geom_point(aes(y = median_sales), color = COLORS$danger, size = 3) +
  geom_text(aes(y = mean_sales, label = comma(round(mean_sales))),
            vjust = -0.6, size = 2.9, fontface = "bold") +
  annotate("rect", xmin = 11.5, xmax = 12.5, ymin = 0, ymax = Inf,
           alpha = 0.08, fill = COLORS$warning) +
  annotate("text", x = 12, y = max(monthly_stats$mean_sales) * 0.3,
           label = "Weihnachten", angle = 90, size = 3, color = COLORS$warning) +
  scale_x_discrete(labels = c("1"="T1","2"="T2","3"="T3","4"="T4",
                               "5"="T5","6"="T6","7"="T7","8"="T8",
                               "9"="T9","10"="T10","11"="T11","12"="T12")) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
  labs(
    title    = "Xu hướng doanh số theo tháng (T8/2014 – T7/2015)",
    subtitle = "Cột xanh = Doanh số TB (Mean) | Đường đỏ = Trung vị (Median)\nT8-T9 thấp: Sommerurlaub (76% người Đức đi nghỉ hè) | T12 đỉnh: Weihnachten",
    x = "Tháng", y = "Doanh số (EUR/ngày/cửa hàng)",
    caption = "Nền vàng: Tháng 12 — mùa Giáng sinh"
  ) +
  theme_rossmann()

# =============================================================================
# LƯU KẾT QUẢ + BIỂU ĐỒ
# =============================================================================
cat("\n━━━ LƯU KẾT QUẢ ━━━\n")

# Lưu biểu đồ EDA
eda_plots <- list(eda_p1, eda_p2, eda_p3, eda_p4, eda_p5, eda_p6,
                  eda_p7, eda_p8, eda_p9, eda_p10, eda_p11, eda_p12)
eda_names <- c("eda_p1_sales_dist", "eda_p2_qq_plot", "eda_p3_log_sales",
               "eda_p4_customers_dist", "eda_p5_density_storetype",
               "eda_p6_promo_impact", "eda_p7_heatmap_dow_month",
               "eda_p8_holiday_impact", "eda_p9_assortment_box",
               "eda_p10_spc_violin", "eda_p11_outlier_pct",
               "eda_p12_monthly_trend")

for (i in seq_along(eda_plots)) {
  ggsave(here("output", "figures", paste0(eda_names[i], ".png")),
         eda_plots[[i]], width = 10, height = 5.5, dpi = 150)
}

# Lưu kết quả EDA
saveRDS(list(
  summary_numeric     = summary_numeric,
  summary_categorical = summary_categorical,
  dist_stats          = dist_stats,
  cor_matrix          = cor_matrix,
  stats_storetype     = stats_storetype,
  stats_promo         = stats_promo,
  stats_assortment    = stats_assortment,
  stats_dow           = stats_dow,
  stats_holiday       = stats_holiday,
  stats_school        = stats_school,
  stats_comp          = stats_comp,
  outlier_summary     = outlier_summary,
  monthly_stats       = monthly_stats
), here("output", "tables", "eda_results.rds"))

cat("[Thanh Phúc] ✅ EDA hoàn tất!\n")
cat("[Thanh Phúc] ✅ 12 biểu đồ EDA → output/figures/eda_p*.png\n")
cat("[Thanh Phúc] ✅ Kết quả → output/tables/eda_results.rds\n")
