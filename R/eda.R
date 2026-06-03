# =============================================================================
# THANH PHÚC — EXPLORATORY DATA ANALYSIS (EDA)
# File: R/eda.R
# Người phụ trách: Thanh Phúc
# Mô tả: Thống kê mô tả, phân tích phân phối, phân tích nhóm
# =============================================================================
# CHÚ Ý: Chỉ Thanh Phúc được chỉnh sửa file này!
# Input: readRDS(here("data", "processed", "df_clean.rds"))
# Sử dụng: get_summary_stats() từ R/utils.R
# =============================================================================

library(dplyr)
library(tidyr)
library(knitr)
library(kableExtra)
library(here)

# --- Đọc dữ liệu ---
df <- readRDS(here("data", "processed", "df_clean.rds"))

# --- 1. Summary Statistics tổng quan ---
cat("\n========== SUMMARY STATISTICS ==========\n")
summary(df)

# Thống kê chi tiết cho biến số
numeric_vars <- df %>% select(sales, customers, competition_distance, sales_per_customer)

summary_table <- numeric_vars %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Value") %>%
  group_by(Variable) %>%
  summarise(
    N      = n(),
    Mean   = round(mean(Value, na.rm = TRUE), 2),
    Median = round(median(Value, na.rm = TRUE), 2),
    SD     = round(sd(Value, na.rm = TRUE), 2),
    Min    = min(Value, na.rm = TRUE),
    Max    = max(Value, na.rm = TRUE),
    .groups = "drop"
  )

kable(summary_table, caption = "Bảng thống kê mô tả các biến số") %>%
  kable_styling(bootstrap_options = c("striped", "hover"))

# --- 2. Phân tích phân phối Sales ---
cat("\n========== PHÂN PHỐI SALES ==========\n")
cat("Skewness (Sales):", round(moments::skewness(df$sales), 3), "\n")
cat("Kurtosis (Sales):", round(moments::kurtosis(df$sales), 3), "\n")

# Shapiro test trên sample (giới hạn 5000)
if (nrow(df) > 5000) {
  shapiro_result <- shapiro.test(sample(df$sales, 5000))
} else {
  shapiro_result <- shapiro.test(df$sales)
}
cat("Shapiro-Wilk p-value:", shapiro_result$p.value, "\n")

# --- 3. Phân tích theo nhóm (dùng hàm TV1) ---
cat("\n========== PHÂN TÍCH THEO NHÓM ==========\n")

# Theo StoreType
cat("--- Sales theo StoreType ---\n")
stats_storetype <- get_summary_stats(df, store_type)
kable(stats_storetype, caption = "Thống kê Sales theo Store Type") %>%
  kable_styling()

# Theo Promo
cat("--- Sales theo Promo ---\n")
stats_promo <- get_summary_stats(df, promo)
kable(stats_promo, caption = "Thống kê Sales theo Promo") %>%
  kable_styling()

# Theo Assortment
cat("--- Sales theo Assortment ---\n")
stats_assort <- get_summary_stats(df, assortment)
kable(stats_assort, caption = "Thống kê Sales theo Assortment") %>%
  kable_styling()

# Theo DayOfWeek
cat("--- Sales theo Day of Week ---\n")
stats_dow <- get_summary_stats(df, day_of_week)
kable(stats_dow, caption = "Thống kê Sales theo Ngày trong tuần") %>%
  kable_styling()

# --- 4. Phân tích ảnh hưởng ngày lễ ---
cat("\n========== ẢNH HƯỞNG NGÀY LỄ ==========\n")
stats_holiday <- df %>%
  group_by(state_holiday) %>%
  summarise(
    n         = n(),
    mean_sales = round(mean(sales), 0),
    mean_cust  = round(mean(customers), 0),
    .groups   = "drop"
  )
kable(stats_holiday, caption = "Doanh số theo State Holiday") %>%
  kable_styling()

stats_school <- df %>%
  group_by(school_holiday) %>%
  summarise(
    n         = n(),
    mean_sales = round(mean(sales), 0),
    mean_cust  = round(mean(customers), 0),
    .groups   = "drop"
  )
kable(stats_school, caption = "Doanh số theo School Holiday") %>%
  kable_styling()

# --- 5. Phân tích CompetitionDistance ---
cat("\n========== COMPETITION DISTANCE ==========\n")
df %>%
  mutate(distance_group = cut(competition_distance,
                               breaks = c(0, 1000, 5000, 10000, Inf),
                               labels = c("<1km", "1-5km", "5-10km", ">10km"))) %>%
  group_by(distance_group) %>%
  summarise(
    n          = n(),
    mean_sales = round(mean(sales), 0),
    .groups    = "drop"
  ) %>%
  kable(caption = "Doanh số theo khoảng cách đối thủ") %>%
  kable_styling()

# --- 6. Correlation Matrix ---
cat("\n========== CORRELATION MATRIX ==========\n")
numeric_df <- df %>%
  select(sales, customers, competition_distance, sales_per_customer,
         month, week_of_year, is_weekend) %>%
  mutate(across(everything(), as.numeric))

cor_matrix <- cor(numeric_df, use = "complete.obs")
print(round(cor_matrix, 3))

# Lưu kết quả EDA
saveRDS(list(
  summary_table = summary_table,
  cor_matrix    = cor_matrix,
  stats_storetype = stats_storetype,
  stats_promo     = stats_promo
), here("output", "tables", "eda_results.rds"))

cat("\n[Thanh Phúc] ✅ EDA hoàn tất! Đã lưu: output/tables/eda_results.rds\n")
