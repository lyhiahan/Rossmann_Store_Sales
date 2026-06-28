# 00_setup.R — Thiết lập dùng chung (Thư viện + Theme + Thư mục)
# Tác giả: Quốc Anh  
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

#  1. Thư viện
required_packages <- c(
  # Xử lý dữ liệu
  "dplyr", "tidyr", "lubridate", "janitor", "readr", "tibble",
  # Trực quan hóa
  "ggplot2", "plotly", "corrplot", "ggcorrplot", "scales", "gridExtra", "RColorBrewer",
  # Mô hình hóa 
  "caret", "randomForest", "ranger", "xgboost", "Metrics",
  # Chuỗi thời gian
  "forecast",
  # Thống kê & Phân tích khám phá dữ liệu (EDA)
  "psych", "moments", "effectsize",
  # Báo cáo
  "knitr", "kableExtra", "rmarkdown",
  # Tiện ích
  "here"
)

load_or_install <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cran.r-project.org", dependencies = TRUE)
  tryCatch(
    suppressPackageStartupMessages(library(pkg, character.only = TRUE)),
    error = function(e) cat(sprintf("[CẢNH BÁO] Không thể tải thư viện '%s': %s\n", pkg, e$message))
  )
}
invisible(lapply(required_packages, load_or_install))


#  2. Khung thư mục dự án
dirs_needed <- here(c(
  "data/raw", "data/processed",
  "output/figures", "output/tables",
  "report", "slides", "docs"
))
invisible(lapply(dirs_needed, dir.create, recursive = TRUE, showWarnings = FALSE))


#  3. Tùy chọn toàn cục
options(scipen = 999)
set.seed(42)


#  4. Bảng màu dùng chung
COLORS <- list(
  store_type = c("a" = "#1E88E5", "b" = "#E53935", "c" = "#43A047", "d" = "#FB8C00"),
  promo      = c("0" = "#78909C", "1" = "#E53935"),
  models     = c("Linear Regression" = "#1E88E5",
                 "Random Forest"     = "#43A047",
                 "XGBoost"           = "#FB8C00",
                 "ARIMA"             = "#8E24AA",
                 "ETS"               = "#00ACC1"),
  gradient   = c("#E3F2FD", "#1E88E5", "#0D47A1"),
  primary    = "#1E88E5",
  danger     = "#E53935",
  success    = "#43A047",
  warning    = "#FB8C00"
)


#  5. Theme ggplot2 dùng chung
theme_rossmann <- function(base_size = 12) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      plot.title       = element_text(face = "bold", size = base_size + 2,
                                      hjust = 0.5, margin = ggplot2::margin(b = 8)),
      plot.subtitle    = element_text(size = base_size - 1, hjust = 0.5,
                                      color = "grey40", margin = ggplot2::margin(b = 10)),
      plot.caption     = element_text(size = base_size - 3, color = "grey50", hjust = 1),
      axis.title       = element_text(size = base_size - 1, color = "grey30"),
      axis.text        = element_text(size = base_size - 2, color = "grey40"),
      axis.line        = element_line(color = "grey70", linewidth = 0.3),
      legend.position  = "bottom",
      legend.title     = element_text(face = "bold", size = base_size - 2),
      legend.text      = element_text(size = base_size - 2),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.2),
      panel.grid.minor = element_blank(),
      plot.margin      = ggplot2::margin(10, 15, 10, 10)
    )
}

theme_set(theme_rossmann())


#  Hoàn tất
cat(sprintf(
  "[THIẾT LẬP] Đã tải %d thư viện | theme_rossmann() đang hoạt động | thư mục gốc: %s\n",
  length(required_packages), here()
))
