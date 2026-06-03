# =============================================================================
# TV1 — DATA PIPELINE
# File: R/tv1_data_pipeline.R
# Người phụ trách: Thành viên 1 (Nhóm trưởng)
# Mô tả: Đọc, merge, lọc, làm sạch dữ liệu Rossmann
# =============================================================================
# CHÚ Ý: Chỉ TV1 được chỉnh sửa file này!
# Các TV khác: dùng readRDS(here("output", "data", "df_clean.rds"))
# =============================================================================

library(dplyr)
library(lubridate)
library(janitor)
library(here)

# --- 1. Đọc dữ liệu gốc ---
train_raw <- read.csv(here("train.csv"), stringsAsFactors = FALSE)
store_raw <- read.csv(here("store.csv"), stringsAsFactors = FALSE)

cat("[TV1] train_raw:", nrow(train_raw), "dòng,", ncol(train_raw), "cột\n")
cat("[TV1] store_raw:", nrow(store_raw), "dòng,", ncol(store_raw), "cột\n")

# --- 2. Merge train + store ---
df_merged <- train_raw %>%
  left_join(store_raw, by = "Store")

cat("[TV1] Sau merge:", nrow(df_merged), "dòng\n")

# --- 3. Lọc dữ liệu ---
# Store 1-50, Date 2014-08-01 → 2015-07-31, Open == 1
df_filtered <- df_merged %>%
  mutate(Date = as.Date(Date)) %>%
  filter(
    Store >= 1 & Store <= 50,
    Date >= as.Date("2014-08-01") & Date <= as.Date("2015-07-31"),
    Open == 1
  )

cat("[TV1] Sau lọc (Store 1-50, date range, Open==1):", nrow(df_filtered), "dòng\n")

# --- 4. Chuẩn hóa tên cột ---
df_clean <- df_filtered %>%
  clean_names()

# --- 5. Chuyển đổi kiểu dữ liệu ---
df_clean <- df_clean %>%
  mutate(
    state_holiday  = as.factor(state_holiday),
    store_type     = as.factor(store_type),
    assortment     = as.factor(assortment),
    promo          = as.factor(promo),
    school_holiday = as.factor(school_holiday),
    day_of_week    = as.factor(day_of_week)
  )

# --- 6. Xử lý Missing Values ---
# CompetitionDistance: thay NA bằng median
df_clean <- df_clean %>%
  mutate(
    competition_distance = ifelse(
      is.na(competition_distance),
      median(competition_distance, na.rm = TRUE),
      competition_distance
    )
  )

# Promo2SinceWeek/Year: thay NA bằng 0 (store không tham gia Promo2)
df_clean <- df_clean %>%
  mutate(
    promo2_since_week = ifelse(is.na(promo2_since_week), 0, promo2_since_week),
    promo2_since_year = ifelse(is.na(promo2_since_year), 0, promo2_since_year)
  )

cat("[TV1] NA còn lại:", sum(is.na(df_clean)), "\n")

# --- 7. Feature Engineering ---
df_clean <- df_clean %>%
  mutate(
    month              = month(date),
    week_of_year       = isoweek(date),
    is_weekend         = ifelse(day_of_week %in% c(6, 7), 1, 0),
    sales_per_customer = ifelse(customers > 0, round(sales / customers, 2), 0)
  )

# --- 8. Phát hiện Outlier (IQR method) — KHÔNG xóa, chỉ đánh dấu ---
df_clean <- df_clean %>%
  group_by(store) %>%
  mutate(
    q1_sales   = quantile(sales, 0.25, na.rm = TRUE),
    q3_sales   = quantile(sales, 0.75, na.rm = TRUE),
    iqr_sales  = q3_sales - q1_sales,
    is_outlier = (sales < (q1_sales - 1.5 * iqr_sales)) |
                 (sales > (q3_sales + 1.5 * iqr_sales))
  ) %>%
  select(-q1_sales, -q3_sales, -iqr_sales) %>%
  ungroup()

cat("[TV1] Số outlier đánh dấu:", sum(df_clean$is_outlier), "\n")

# --- 9. Train/Test Split — theo thời gian, KHÔNG random ---
train_data <- df_clean %>% filter(date < as.Date("2015-06-01"))
test_data  <- df_clean %>% filter(date >= as.Date("2015-06-01"))

cat("[TV1] Train:", nrow(train_data), "dòng | Test:", nrow(test_data), "dòng\n")

# --- 10. Lưu output dùng chung ---
saveRDS(df_clean,   here("output", "data", "df_clean.rds"))
saveRDS(train_data, here("output", "data", "train_data.rds"))
saveRDS(test_data,  here("output", "data", "test_data.rds"))

cat("[TV1] ✅ Đã lưu: df_clean.rds, train_data.rds, test_data.rds\n")
cat("[TV1] ✅ Pipeline hoàn tất!\n")
