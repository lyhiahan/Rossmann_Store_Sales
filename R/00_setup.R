# =============================================================================
# 00_setup.R — Shared Setup (Libraries + Theme)
# Dùng chung cả nhóm — KHÔNG AI CHỈNH SỬA trừ TV1
# =============================================================================

# --- Packages cần thiết ---
required_packages <- c(
  # Data manipulation
  "dplyr", "tidyr", "lubridate", "janitor", "readr", "tibble",
  # Visualization
  "ggplot2", "plotly", "corrplot", "ggcorrplot", "scales", "gridExtra", "RColorBrewer",
  # Modeling
  "caret", "randomForest", "ranger", "xgboost", "Metrics",
  # EDA
  "psych", "moments",
  # Reporting
  "knitr", "kableExtra", "rmarkdown",
  # Path management
  "here"
)

# Cài đặt packages thiếu
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
}
invisible(lapply(required_packages, install_if_missing))

# Load packages chính
library(dplyr)
library(tidyr)
library(lubridate)
library(janitor)
library(ggplot2)
library(plotly)
library(scales)
library(knitr)
library(kableExtra)
library(here)

# --- Cấu hình chung ---
options(scipen = 999)  # Tắt ký hiệu khoa học
set.seed(42)           # Reproducibility

cat("[SETUP] ✅ Tất cả packages đã sẵn sàng!\n")
cat("[SETUP] Project root:", here(), "\n")
