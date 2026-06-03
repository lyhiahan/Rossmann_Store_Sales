# =============================================================================
# TV1 — UTILITY FUNCTIONS (DÙng chung cả nhóm)
# File: R/tv1_utils.R
# Người phụ trách: Thành viên 1 (Nhóm trưởng)
# Mô tả: Các hàm tiện ích TV1 viết, TV2–TV5 gọi
# =============================================================================
# CHÚ Ý: Chỉ TV1 được chỉnh sửa file này!
# Các TV khác: chỉ GỌI các hàm, KHÔNG sửa.
# =============================================================================

library(dplyr)
library(here)

# --- Hàm 1: clean_rossmann() — đóng gói toàn bộ pipeline ---
clean_rossmann <- function(train_path = here("train.csv"),
                           store_path = here("store.csv"),
                           store_range = 1:50,
                           date_from = "2014-08-01",
                           date_to   = "2015-07-31") {

  train <- read.csv(train_path, stringsAsFactors = FALSE)
  store <- read.csv(store_path, stringsAsFactors = FALSE)

  df <- train %>%
    left_join(store, by = "Store") %>%
    filter(
      Store %in% store_range,
      Date >= date_from & Date <= date_to,
      Open == 1
    ) %>%
    janitor::clean_names() %>%
    mutate(
      date           = as.Date(date),
      state_holiday  = as.factor(state_holiday),
      store_type     = as.factor(store_type),
      assortment     = as.factor(assortment),
      promo          = as.factor(promo),
      school_holiday = as.factor(school_holiday),
      day_of_week    = as.factor(day_of_week),
      month          = lubridate::month(date),
      week_of_year   = lubridate::isoweek(date),
      is_weekend     = ifelse(day_of_week %in% c(6, 7), 1, 0),
      sales_per_customer = ifelse(customers > 0, round(sales / customers, 2), 0),
      competition_distance = ifelse(is.na(competition_distance),
                                     median(competition_distance, na.rm = TRUE),
                                     competition_distance)
    ) %>%
    group_by(store) %>%
    mutate(
      q1 = quantile(sales, 0.25, na.rm = TRUE),
      q3 = quantile(sales, 0.75, na.rm = TRUE),
      iqr_val = q3 - q1,
      is_outlier = (sales < (q1 - 1.5 * iqr_val)) | (sales > (q3 + 1.5 * iqr_val))
    ) %>%
    select(-q1, -q3, -iqr_val) %>%
    ungroup()

  return(df)
}

# --- Hàm 2: get_summary_stats() — thống kê mô tả theo nhóm ---
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
# Cách gọi: get_summary_stats(df, store_type)

# --- Hàm 3: mock_data() — dữ liệu giả để TV2–TV5 test khi chờ TV1 ---
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
    state_holiday      = factor(sample(c("0","a","b","c"), n, replace = TRUE,
                                        prob = c(0.9, 0.05, 0.03, 0.02))),
    school_holiday     = factor(sample(0:1, n, replace = TRUE, prob = c(0.6, 0.4))),
    competition_distance = round(abs(rnorm(n, 5000, 3000))),
    month              = sample(1:12, n, replace = TRUE),
    week_of_year       = sample(1:52, n, replace = TRUE),
    is_weekend         = sample(0:1, n, replace = TRUE, prob = c(5/7, 2/7)),
    sales_per_customer = round(abs(rnorm(n, 8.5, 2)), 2),
    is_outlier         = sample(c(TRUE, FALSE), n, replace = TRUE, prob = c(0.05, 0.95))
  )
}

cat("[TV1] ✅ Utils loaded: clean_rossmann(), get_summary_stats(), mock_data()\n")
