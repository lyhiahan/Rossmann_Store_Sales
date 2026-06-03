# =============================================================================
# QUỐC ANH — UTILITY FUNCTIONS (Dùng chung cả nhóm)
# File: R/utils.R
# Người phụ trách: Quốc Anh (Nhóm trưởng)
# Mô tả: Các hàm tiện ích Quốc Anh viết, cả nhóm gọi
# =============================================================================
# CHÚ Ý: Chỉ Quốc Anh được chỉnh sửa file này!
# Các TV khác: chỉ GỌI các hàm, KHÔNG sửa.
# =============================================================================

library(dplyr)
library(lubridate)
library(janitor)
library(here)

# =============================================================================
# HÀM 1: clean_rossmann()
# Đóng gói pipeline — chạy được cho CẢ train.csv VÀ test.csv
# ⚠️ KHÔNG tính median/IQR bên trong (tránh Data Leakage)
#    → Truyền stats từ bên ngoài (train_stats) nếu cần
# =============================================================================
clean_rossmann <- function(data_path,
                           store_path = here("store.csv"),
                           store_range = 1:50,
                           date_from = "2014-08-01",
                           date_to   = "2015-07-31",
                           has_sales = TRUE,
                           train_stats = NULL) {

  data_raw <- readr::read_csv(data_path, show_col_types = FALSE)
  store    <- readr::read_csv(store_path, show_col_types = FALSE)

  df <- data_raw %>%
    left_join(store, by = "Store") %>%
    filter(Store %in% store_range) %>%
    janitor::clean_names() %>%
    mutate(date = as.Date(date))

  # Lọc theo date range (nếu có cột date)
  if (!is.null(date_from) & !is.null(date_to)) {
    df <- df %>% filter(date >= as.Date(date_from) & date <= as.Date(date_to))
  }

  # Lọc nhiễu logic — CHỈ khi có cột sales (train.csv)
  if (has_sales) {
    df <- df %>% filter(open == 1, sales > 0)
  }

  # Đồng bộ StateHoliday
  df <- df %>%
    mutate(
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
      has_competition = ifelse(!is.na(competition_open_since_year), 1, 0),
      competition_open_since_month = ifelse(is.na(competition_open_since_month), 0,
                                            competition_open_since_month),
      competition_open_since_year  = ifelse(is.na(competition_open_since_year), 0,
                                            competition_open_since_year),
      promo2since_week = ifelse(is.na(promo2since_week), 0, promo2since_week),
      promo2since_year = ifelse(is.na(promo2since_year), 0, promo2since_year),
      promo_interval   = ifelse(is.na(promo_interval) | promo_interval == "",
                                 "None", promo_interval)
    )

  # Ép factor cho promo (nếu có)
  if ("promo" %in% names(df)) {
    df <- df %>% mutate(promo = as.factor(promo))
  }

  # CompetitionDistance NA → dùng median từ train_stats (nếu có)
  if (!is.null(train_stats)) {
    median_cd <- train_stats$median_competition_distance
  } else {
    median_cd <- median(df$competition_distance, na.rm = TRUE)
  }
  df <- df %>%
    mutate(competition_distance = ifelse(is.na(competition_distance),
                                          median_cd, competition_distance))

  # Feature Engineering
  df <- df %>%
    mutate(
      year         = year(date),
      month        = month(date),
      day          = day(date),
      week_of_year = isoweek(date),
      is_weekend   = ifelse(day_of_week %in% c(6, 7), 1, 0),
      competition_open_months = ifelse(
        has_competition == 1 & competition_open_since_year > 0,
        pmax((year(date) - competition_open_since_year) * 12 +
               (month(date) - competition_open_since_month), 0),
        -1  # -1 = không có đối thủ (phân biệt với 0 = vừa mở)
      )
    )

  # sales_per_customer — CHỈ khi có cột sales
  # ⚠️ CHÚ Ý: Biến này CHỈ dùng cho trực quan hóa (Thanh Phúc/Gia Hân)
  #    TUYỆT ĐỐI KHÔNG đưa vào model (Target Leakage: sales/customers → dự đoán sales)
  if (has_sales) {
    df <- df %>%
      mutate(sales_per_customer = ifelse(customers > 0,
                                          round(sales / customers, 2), 0))
  }

  # Outlier flag — CHỈ khi có sales, dùng IQR từ train_stats nếu có
  if (has_sales) {
    if (!is.null(train_stats) & "iqr_bounds_by_store" %in% names(train_stats)) {
      df <- df %>%
        left_join(train_stats$iqr_bounds_by_store, by = "store") %>%
        mutate(is_outlier = (sales < lower_bound) | (sales > upper_bound)) %>%
        select(-q1_train, -q3_train, -iqr_train, -lower_bound, -upper_bound)
    } else {
      df <- df %>%
        group_by(store) %>%
        mutate(
          q1 = quantile(sales, 0.25, na.rm = TRUE),
          q3 = quantile(sales, 0.75, na.rm = TRUE),
          iqr_val = q3 - q1,
          is_outlier = (sales < (q1 - 1.5 * iqr_val)) | (sales > (q3 + 1.5 * iqr_val))
        ) %>%
        select(-q1, -q3, -iqr_val) %>%
        ungroup()
    }
  }

  return(df)
}

# =============================================================================
# HÀM 2: get_summary_stats() — thống kê mô tả theo nhóm
# =============================================================================
get_summary_stats <- function(df, group_var) {
  df %>%
    group_by({{ group_var }}) %>%
    summarise(
      n        = n(),
      mean_s   = round(mean(sales), 0),
      median_s = round(median(sales), 0),
      sd_s     = round(sd(sales), 0),
      min_s    = min(sales),
      max_s    = max(sales),
      .groups  = "drop"
    )
}

# =============================================================================
# HÀM 3: mock_data() — dữ liệu giả để test khi chờ pipeline
# =============================================================================
mock_data <- function(n = 1000, seed = 42) {
  set.seed(seed)
  tibble(
    store              = sample(1:50, n, replace = TRUE),
    date               = sample(seq(as.Date("2014-08-01"),
                                    as.Date("2015-07-31"), by = "day"),
                                n, replace = TRUE),
    sales              = round(abs(rnorm(n, 6000, 2000))),
    customers          = round(abs(rnorm(n, 700, 200))),
    promo              = factor(sample(0:1, n, replace = TRUE)),
    store_type         = factor(sample(c("a","b","c","d"), n, replace = TRUE)),
    assortment         = factor(sample(c("a","b","c"), n, replace = TRUE)),
    day_of_week        = factor(sample(1:7, n, replace = TRUE)),
    state_holiday      = factor(sample(c("none","public","easter","christmas"), n,
                                        replace = TRUE, prob = c(0.9, 0.05, 0.03, 0.02))),
    school_holiday     = factor(sample(0:1, n, replace = TRUE, prob = c(0.6, 0.4))),
    competition_distance = round(abs(rnorm(n, 5000, 3000))),
    month              = sample(1:12, n, replace = TRUE),
    week_of_year       = sample(1:52, n, replace = TRUE),
    is_weekend         = sample(0:1, n, replace = TRUE, prob = c(5/7, 2/7)),
    sales_per_customer = round(abs(rnorm(n, 8.5, 2)), 2),
    is_outlier         = sample(c(TRUE, FALSE), n, replace = TRUE, prob = c(0.05, 0.95)),
    competition_open_months = sample(c(-1, 0:120), n, replace = TRUE),
    has_competition    = sample(0:1, n, replace = TRUE, prob = c(0.1, 0.9))
  )
}

cat("[Quốc Anh] ✅ Utils loaded:\n")
cat("  • clean_rossmann(data_path, has_sales=TRUE/FALSE, train_stats=NULL)\n")
cat("  • get_summary_stats(df, group_var)\n")
cat("  • mock_data(n, seed)\n")
cat("  ⚠️ clean_rossmann() hỗ trợ cả train.csv (has_sales=TRUE) và test.csv (has_sales=FALSE)\n")
cat("  ⚠️ sales_per_customer: CHỈ cho EDA, KHÔNG dùng trong model\n")
