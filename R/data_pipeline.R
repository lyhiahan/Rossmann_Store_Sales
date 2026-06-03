# =============================================================================
# QUỐC ANH — DATA PIPELINE (Đường ống dữ liệu)
# File: R/data_pipeline.R
# Người phụ trách: Quốc Anh (Nhóm trưởng · Data Engineer)
# Mô tả: Pipeline KHÔNG rò rỉ dữ liệu (No Data Leakage)
#         Chia Train/Val TRƯỚC → tính stats trên Train → áp dụng cho cả hai
# =============================================================================
# CHÚ Ý: Chỉ Quốc Anh được chỉnh sửa file này!
# Các thành viên khác: dùng readRDS(here("data","processed","df_clean.rds"))
# =============================================================================

library(dplyr)
library(readr)
library(lubridate)
library(janitor)
library(here)

cat("╔══════════════════════════════════════════════════════════╗\n")
cat("║  QUỐC ANH — DATA PIPELINE (No Data Leakage)            ║\n")
cat("║  Rossmann Store Sales Analysis                          ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n\n")

# =============================================================================
# 🛠️ BƯỚC 1: ĐỌC VÀ KIỂM TRA CẤU TRÚC (DATA INGESTION & AUDIT)
# =============================================================================
cat("━━━ BƯỚC 1: ĐỌC DỮ LIỆU ━━━\n")

train_raw <- read_csv(here("data", "raw", "train.csv"), show_col_types = FALSE)
store_raw <- read_csv(here("data", "raw", "store.csv"), show_col_types = FALSE)

cat("[Quốc Anh] train_raw:", format(nrow(train_raw), big.mark = ","), "dòng,",
    ncol(train_raw), "cột\n")
cat("[Quốc Anh] store_raw:", format(nrow(store_raw), big.mark = ","), "dòng,",
    ncol(store_raw), "cột\n")

# Kiểm tra tổng quan
cat("\n--- Cấu trúc train_raw ---\n")
str(train_raw)

# Tỷ lệ NA
cat("\n--- Tỷ lệ NA (%) trong store_raw ---\n")
na_pct <- colMeans(is.na(store_raw)) * 100
print(round(na_pct[na_pct > 0], 2))

# =============================================================================
# 🔗 BƯỚC 2: TÍCH HỢP DỮ LIỆU (DATA INTEGRATION)
# =============================================================================
cat("\n━━━ BƯỚC 2: MERGE DỮ LIỆU ━━━\n")

df_merged <- train_raw %>%
  left_join(store_raw, by = "Store")

cat("[Quốc Anh] Sau merge:", format(nrow(df_merged), big.mark = ","), "dòng\n")

# Lọc phạm vi: Store 1-50, Date range
df_filtered <- df_merged %>%
  mutate(Date = as.Date(Date)) %>%
  filter(
    Store >= 1 & Store <= 50,
    Date >= as.Date("2014-08-01") & Date <= as.Date("2015-07-31")
  )

cat("[Quốc Anh] Sau lọc Store 1-50 + date range:",
    format(nrow(df_filtered), big.mark = ","), "dòng\n")

# =============================================================================
# 🧹 BƯỚC 3: LÀM SẠCH CƠ BẢN (trước khi chia tập)
# =============================================================================
cat("\n━━━ BƯỚC 3: LÀM SẠCH CƠ BẢN ━━━\n")

# --- 3a. Chuẩn hóa tên cột ---
df_base <- df_filtered %>% clean_names()

# --- 3b. Lọc nhiễu logic ---
n_before <- nrow(df_base)
df_base <- df_base %>%
  filter(open == 1, sales > 0)
n_removed <- n_before - nrow(df_base)
cat("[Quốc Anh] Loại bỏ", n_removed, "dòng nhiễu (đóng cửa / sales=0)\n")

# --- 3c. Đồng bộ kiểu dữ liệu (KHÔNG tính stats thống kê ở đây) ---
df_base <- df_base %>%
  mutate(
    # StateHoliday: quy chuẩn
    state_holiday = case_when(
      state_holiday == "0" | state_holiday == 0 ~ "none",
      state_holiday == "a" ~ "public",
      state_holiday == "b" ~ "easter",
      state_holiday == "c" ~ "christmas",
      TRUE ~ as.character(state_holiday)
    ),
    state_holiday  = as.factor(state_holiday),
    store_type     = as.factor(store_type),
    assortment     = as.factor(assortment),
    day_of_week    = as.factor(day_of_week),
    school_holiday = as.factor(school_holiday),
    promo          = as.factor(promo),
    # Biến cờ hiệu đối thủ cạnh tranh
    has_competition = ifelse(!is.na(competition_open_since_year), 1, 0),
    # CompetitionOpenSince: điền NA = 0 (thông tin cấu trúc, không phải stats)
    competition_open_since_month = ifelse(is.na(competition_open_since_month), 0,
                                          competition_open_since_month),
    competition_open_since_year  = ifelse(is.na(competition_open_since_year), 0,
                                          competition_open_since_year),
    promo2since_week = ifelse(is.na(promo2since_week), 0, promo2since_week),
    promo2since_year = ifelse(is.na(promo2since_year), 0, promo2since_year),
    promo_interval   = ifelse(is.na(promo_interval) | promo_interval == "",
                               "None", promo_interval)
  )

cat("[Quốc Anh] Kiểu dữ liệu đã đồng bộ ✓\n")
cat("[Quốc Anh] Còn lại:", format(nrow(df_base), big.mark = ","), "dòng\n")

# =============================================================================
# ✂️ BƯỚC 4: CHIA TẬP TRƯỚC (CHỐNG RÒ RỈ DỮ LIỆU)
# =============================================================================
cat("\n━━━ BƯỚC 4: CHIA TẬP TRAIN/VAL (TRƯỚC KHI TÍNH STATS) ━━━\n")
cat("[Quốc Anh] ⚠️ QUAN TRỌNG: Chia tập TRƯỚC → tính stats trên TRAIN ONLY\n")

set.seed(42)
n_total     <- nrow(df_base)
train_index <- sample(seq_len(n_total), size = floor(0.7 * n_total))

train_raw_split <- df_base[train_index, ]
val_raw_split   <- df_base[-train_index, ]

cat("[Quốc Anh] Train (raw):", format(nrow(train_raw_split), big.mark = ","), "dòng",
    "(", round(nrow(train_raw_split)/n_total*100, 1), "%)\n")
cat("[Quốc Anh] Val (raw):  ", format(nrow(val_raw_split), big.mark = ","), "dòng",
    "(", round(nrow(val_raw_split)/n_total*100, 1), "%)\n")

# =============================================================================
# 📊 BƯỚC 5: TÍNH STATS TRÊN TRAIN ONLY → ÁP DỤNG CHO CẢ HAI
# =============================================================================
cat("\n━━━ BƯỚC 5: IMPUTE & FE (TRAIN-ONLY STATS) ━━━\n")

# --- 5a. CompetitionDistance: median từ TRAIN ---
median_comp_dist <- median(train_raw_split$competition_distance, na.rm = TRUE)
cat("[Quốc Anh] Median competition_distance (TRAIN ONLY):", median_comp_dist, "\n")

# --- 5b. IQR boundaries từ TRAIN (cho mỗi store) ---
iqr_stats <- train_raw_split %>%
  group_by(store) %>%
  summarise(
    q1_train  = quantile(sales, 0.25, na.rm = TRUE),
    q3_train  = quantile(sales, 0.75, na.rm = TRUE),
    iqr_train = q3_train - q1_train,
    lower_bound = q1_train - 1.5 * iqr_train,
    upper_bound = q3_train + 1.5 * iqr_train,
    .groups = "drop"
  )

# --- Hàm áp dụng Feature Engineering ĐỒNG NHẤT cho cả train & val ---
apply_features <- function(df, median_cd, iqr_ref) {
  df %>%
    mutate(
      # Điền NA CompetitionDistance bằng median từ TRAIN
      competition_distance = ifelse(is.na(competition_distance),
                                     median_cd,
                                     competition_distance),
      # Trích xuất thời gian
      year         = year(date),
      month        = month(date),
      day          = day(date),
      week_of_year = isoweek(date),
      is_weekend   = ifelse(day_of_week %in% c(6, 7), 1, 0),
      # Doanh thu trên mỗi khách hàng
      # ⚠️ CHỈ DÙNG CHO TRỰC QUAN HÓA (TV2/TV3), KHÔNG đưa vào model!
      sales_per_customer = ifelse(customers > 0, round(sales / customers, 2), 0),
      # Thâm niên cạnh tranh
      # Giá trị -1 cho store KHÔNG có đối thủ (tránh trùng với "vừa mở 0 tháng")
      competition_open_months = ifelse(
        has_competition == 1 & competition_open_since_year > 0,
        pmax((year(date) - competition_open_since_year) * 12 +
               (month(date) - competition_open_since_month), 0),
        -1  # Không có đối thủ → -1 (phân biệt rõ với 0 = "vừa mở")
      )
    ) %>%
    # Outlier flag dùng IQR từ TRAIN
    left_join(iqr_ref, by = "store") %>%
    mutate(
      is_outlier = (sales < lower_bound) | (sales > upper_bound)
    ) %>%
    select(-q1_train, -q3_train, -iqr_train, -lower_bound, -upper_bound)
}

# Áp dụng cho cả hai tập
train_data <- apply_features(train_raw_split, median_comp_dist, iqr_stats)
val_data   <- apply_features(val_raw_split,   median_comp_dist, iqr_stats)

# Gộp df_clean cho TV2/TV3 (toàn bộ data đã processed)
df_clean <- bind_rows(train_data, val_data) %>% arrange(date, store)

n_outlier_train <- sum(train_data$is_outlier, na.rm = TRUE)
n_outlier_val   <- sum(val_data$is_outlier, na.rm = TRUE)

cat("[Quốc Anh] ✅ Features applied: year, month, day, week_of_year, is_weekend,\n")
cat("           sales_per_customer, competition_open_months, has_competition, is_outlier\n")
cat("[Quốc Anh] Outlier (train):", n_outlier_train, "| Outlier (val):", n_outlier_val, "\n")
cat("[Quốc Anh] NA còn lại: train =", sum(is.na(train_data)), "| val =",
    sum(is.na(val_data)), "\n")

# =============================================================================
# 📦 BƯỚC 6: XUẤT FILE
# =============================================================================
cat("\n━━━ BƯỚC 6: XUẤT FILE ━━━\n")

n_features <- ncol(df_clean)

# --- RDS (nhanh, giữ nguyên kiểu) ---
saveRDS(df_clean,   here("data", "processed", "df_clean.rds"))
saveRDS(train_data, here("data", "processed", "train_data.rds"))
saveRDS(val_data,   here("data", "processed", "val_data.rds"))

# --- CSV (file trung gian, dễ kiểm tra) ---
write_csv(df_clean,   here("data", "processed", "rossmann_clean.csv"))
write_csv(train_data, here("data", "processed", "rossmann_train_cleaned.csv"))
write_csv(val_data,   here("data", "processed", "rossmann_val_cleaned.csv"))

# --- Lưu stats chuẩn từ TRAIN (cho utils.R reference) ---
train_stats <- list(
  median_competition_distance = median_comp_dist,
  iqr_bounds_by_store         = iqr_stats
)
saveRDS(train_stats, here("data", "processed", "train_stats.rds"))

cat("[Quốc Anh] ✅ Đã lưu: df_clean.rds, train_data.rds, val_data.rds\n")
cat("[Quốc Anh] ✅ Đã lưu: train_stats.rds (median & IQR từ TRAIN ONLY)\n")
cat("[Quốc Anh] ✅ Đã xuất CSV: data/processed/rossmann_clean.csv\n")

# =============================================================================
# 📊 TÓM TẮT
# =============================================================================
cat("\n╔══════════════════════════════════════════════════════════╗\n")
cat("║  📊 TÓM TẮT DATA PIPELINE (No Leakage)                 ║\n")
cat("╠══════════════════════════════════════════════════════════╣\n")
cat("║  Dữ liệu gốc:    ", format(nrow(train_raw), big.mark=",", width=10), " dòng  ║\n")
cat("║  Sau lọc & sạch:  ", format(nrow(df_base), big.mark=",", width=10), " dòng  ║\n")
cat("║  Loại bỏ nhiễu:   ", format(n_removed, big.mark=",", width=10), " dòng  ║\n")
cat("║  Số features:     ", format(n_features, width=10), " cột   ║\n")
cat("║  Train set (70%): ", format(nrow(train_data), big.mark=",", width=10), " dòng  ║\n")
cat("║  Val set (30%):   ", format(nrow(val_data), big.mark=",", width=10), " dòng  ║\n")
cat("║  Outlier (train):  ", format(n_outlier_train, width=9), " dòng  ║\n")
cat("║  Outlier (val):    ", format(n_outlier_val, width=9), " dòng  ║\n")
cat("║  Median CompDist: ", format(median_comp_dist, width=10), " (TRAIN) ║\n")
cat("║  Store range:            1 – 50          ║\n")
cat("║  Date range:     2014-08-01 → 2015-07-31 ║\n")
cat("║  ⚠️ sales_per_customer: CHỈ cho EDA      ║\n")
cat("║  ⚠️ competition_open_months: -1 = no comp ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n")
cat("[Quốc Anh] ✅ PIPELINE HOÀN TẤT! (Data Leakage = ZERO)\n")
