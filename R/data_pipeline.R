# Đường ống dữ liệu (Data Pipeline) — Doanh thu cửa hàng Rossmann
# Tác giả: Quốc Anh 
# Mô tả  : Đường ống không rò rỉ: chia TRƯỚC → tính toán thống kê trên tập train → áp dụng cho cả hai

#  Thiết lập thư mục làm việc & đặt lại thư mục gốc của dự án cho gói 'here'
get_sourced_file <- function() {
  for (i in seq_len(sys.nframe())) {
    ofile <- sys.frame(i)$ofile
    if (!is.null(ofile)) return(ofile)
  }
  return(NULL)
}
sourced_file <- get_sourced_file()
if (!is.null(sourced_file)) {
  setwd(dirname(dirname(sourced_file)))
}
if ("package:here" %in% search()) detach("package:here", unload = TRUE)
if (isNamespaceLoaded("here")) unloadNamespace("here")
library(here)

library(dplyr)
library(readr)
library(lubridate)
library(janitor)

step <- function(n, msg) cat(sprintf("\n Bước %d: %s \n", n, msg))
log_pipeline  <- function(msg)    cat(sprintf("   %s\n", msg))


#  Bước 1: Đọc dữ liệu (Ingest)
step(1, "Đọc dữ liệu thô")

train_raw <- read_csv(here("data", "raw", "train.csv"), show_col_types = FALSE)
store_raw <- read_csv(here("data", "raw", "store.csv"), show_col_types = FALSE)

log_pipeline(sprintf("train_raw: %s dòng × %d cột", format(nrow(train_raw), big.mark=","), ncol(train_raw)))
log_pipeline(sprintf("store_raw: %s dòng × %d cột", format(nrow(store_raw), big.mark=","), ncol(store_raw)))

na_pct <- colMeans(is.na(store_raw)) * 100
if (any(na_pct > 0)) { cat("   Tỷ lệ NA (%) trong store_raw:\n"); print(round(na_pct[na_pct > 0], 2)) }


#  Bước 2: Tích hợp & Lọc dữ liệu (Merge & Filter)
step(2, "Tích hợp & Lọc")

df_base <- train_raw %>%
  left_join(store_raw, by = "Store") %>%
  mutate(Date = as.Date(Date)) %>%
  filter(Store >= 1, Store <= 50,
         Date  >= as.Date("2014-08-01"),
         Date  <= as.Date("2015-07-31"))

log_pipeline(sprintf("Sau khi tích hợp + lọc: %s dòng", format(nrow(df_base), big.mark=",")))


#  Bước 3: Làm sạch & Đồng bộ kiểu dữ liệu (Clean & Type-Cast)
step(3, "Làm sạch & Đồng bộ kiểu dữ liệu")

n_before <- nrow(df_base)

df_base <- df_base %>%
  clean_names() %>%
  filter(open == 1, sales > 0) %>%
  mutate(
    state_holiday = case_when(
      state_holiday %in% c("0", 0) ~ "none",
      state_holiday == "a"         ~ "public",
      state_holiday == "b"         ~ "easter",
      state_holiday == "c"         ~ "christmas",
      TRUE                         ~ as.character(state_holiday)
    ),
    across(c(state_holiday, store_type, assortment,
             day_of_week, school_holiday, promo), as.factor),
    has_competition              = ifelse(!is.na(competition_open_since_year), 1, 0),
    competition_open_since_month = ifelse(is.na(competition_open_since_month), 0,
                                          competition_open_since_month),
    competition_open_since_year  = ifelse(is.na(competition_open_since_year),  0,
                                          competition_open_since_year),
    promo2since_week             = ifelse(is.na(promo2since_week), 0, promo2since_week),
    promo2since_year             = ifelse(is.na(promo2since_year), 0, promo2since_year),
    promo_interval               = ifelse(is.na(promo_interval) | promo_interval == "",
                                          "None", promo_interval)
  )

log_pipeline(sprintf("Đã loại bỏ %d dòng nhiễu (đóng cửa / doanh thu = 0); còn lại: %s",
            n_before - nrow(df_base), format(nrow(df_base), big.mark=",")))


#  Bước 4: Chia tập Train / Validation
step(4, "Chia tập TRƯỚC khi tính toán thống kê [chống rò rỉ dữ liệu]")

set.seed(42)
n_total     <- nrow(df_base)
train_idx   <- sample(n_total, size = floor(0.7 * n_total))
train_raw_split <- df_base[ train_idx, ]
val_raw_split   <- df_base[-train_idx, ]

log_pipeline(sprintf("Train: %s dòng (%.1f%%)", format(nrow(train_raw_split), big.mark=","),
            nrow(train_raw_split) / n_total * 100))
log_pipeline(sprintf("Val  : %s dòng (%.1f%%)", format(nrow(val_raw_split),   big.mark=","),
            nrow(val_raw_split)   / n_total * 100))


#  Bước 5: Kỹ nghệ đặc trưng (Sử dụng thống kê trên tập train)
step(5, "Xử lý dữ liệu thiếu & Tạo đặc trưng [thống kê trên tập train]")

median_comp_dist <- median(train_raw_split$competition_distance, na.rm = TRUE)
log_pipeline(sprintf("Trung vị competition_distance (chỉ tính trên tập train): %.1f", median_comp_dist))

iqr_stats <- train_raw_split %>%
  group_by(store) %>%
  summarise(
    q1    = quantile(sales, 0.25, na.rm = TRUE),
    q3    = quantile(sales, 0.75, na.rm = TRUE),
    iqr   = q3 - q1,
    lower = q1 - 1.5 * iqr,
    upper = q3 + 1.5 * iqr,
    .groups = "drop"
  )

apply_features <- function(df, med_cd, iqr_ref) {
  df %>%
    mutate(
      competition_distance = ifelse(is.na(competition_distance), med_cd,
                                    competition_distance),
      year                 = year(date),
      month                = month(date),
      day                  = day(date),
      week_of_year         = isoweek(date),
      is_weekend           = ifelse(day_of_week %in% c(6, 7), 1, 0),
      # Chỉ dùng cho phân tích khám phá dữ liệu (EDA) — KHÔNG đưa vào mô hình
      sales_per_customer   = ifelse(customers > 0, round(sales / customers, 2), 0),
      # -1 = không có đối thủ cạnh tranh (phân biệt với 0 = "vừa mới mở")
      competition_open_months = ifelse(
        has_competition == 1 & competition_open_since_year > 0,
        pmax((year(date) - competition_open_since_year) * 12 +
               (month(date) - competition_open_since_month), 0),
        -1
      )
    ) %>%
    left_join(iqr_ref, by = "store") %>%
    mutate(is_outlier = sales < lower | sales > upper) %>%
    select(-q1, -q3, -iqr, -lower, -upper)
}

train_data <- apply_features(train_raw_split, median_comp_dist, iqr_stats)
val_data   <- apply_features(val_raw_split,   median_comp_dist, iqr_stats)
df_clean   <- bind_rows(train_data, val_data) %>% arrange(date, store)

log_pipeline(sprintf("Giá trị ngoại lệ (Outliers) — train: %d | val: %d",
            sum(train_data$is_outlier, na.rm=TRUE),
            sum(val_data$is_outlier,   na.rm=TRUE)))
log_pipeline(sprintf("Số giá trị NA còn lại — train: %d | val: %d",
            sum(is.na(train_data)), sum(is.na(val_data))))


#  Bước 6: Xuất dữ liệu (Export)
step(6, "Xuất dữ liệu")

saveRDS(df_clean,   here("data", "processed", "df_clean.rds"))
saveRDS(train_data, here("data", "processed", "train_data.rds"))
saveRDS(val_data,   here("data", "processed", "val_data.rds"))
saveRDS(list(median_competition_distance = median_comp_dist,
             iqr_bounds_by_store         = iqr_stats),
        here("data", "processed", "train_stats.rds"))

write_csv(df_clean,   here("data", "processed", "rossmann_clean.csv"))
write_csv(train_data, here("data", "processed", "rossmann_train_cleaned.csv"))
write_csv(val_data,   here("data", "processed", "rossmann_val_cleaned.csv"))

log_pipeline("Đã lưu: df_clean / train_data / val_data (.rds + .csv)")
log_pipeline("Đã lưu: train_stats.rds  (trung vị & IQR chỉ tính từ tập train)")


#  Tóm tắt
cat(sprintf("
┌─────────────────────────────────────────────┐
│   Tóm tắt đường ống dữ liệu                 │
├──────────────────────────┬──────────────────┤
│ Số dòng dữ liệu thô      │ %16s             │
│ Sau khi lọc & làm sạch   │ %16s             │
│ Đã loại bỏ dòng nhiễu    │ %16s             │
│ Số đặc trưng (cột)       │ %16d             │
│ Tập Train (70%%)         │ %16s             │
│ Tập Val   (30%%)         │ %16s             │
│ Ngoại lệ — tập train     │ %16d             │
│ Ngoại lệ — tập val       │ %16d             │
│ Trung vị CompDist(train) │ %16.1f           │
│ Số lượng cửa hàng        │ %16s             │
│ Khoảng thời gian         │ 2014-08 → 2015-07│
└──────────────────────────┴──────────────────┘
",
  format(nrow(train_raw),  big.mark=","),
  format(nrow(df_base),    big.mark=","),
  format(n_before - nrow(df_base), big.mark=","),
  ncol(df_clean),
  format(nrow(train_data), big.mark=","),
  format(nrow(val_data),   big.mark=","),
  sum(train_data$is_outlier, na.rm=TRUE),
  sum(val_data$is_outlier,   na.rm=TRUE),
  median_comp_dist,
  "1 – 50"
))

cat("HOÀN TẤT — Rò rỉ dữ liệu = 0 (ZERO)\n")
