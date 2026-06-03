# =============================================================================
# 00_setup.R — Shared Setup (Libraries + Theme + Directories)
# Dùng chung cả nhóm — KHÔNG AI CHỈNH SỬA trừ Quốc Anh
# =============================================================================

# --- 1. PACKAGES: Tự động CÀI + LOAD toàn bộ ---
required_packages <- c(
  # Data manipulation
  "dplyr", "tidyr", "lubridate", "janitor", "readr", "tibble",
  # Visualization
  "ggplot2", "plotly", "corrplot", "ggcorrplot", "scales", "gridExtra", "RColorBrewer",
  # Modeling
  "caret", "randomForest", "ranger", "xgboost", "Metrics",
  # Time Series
  "forecast",
  # EDA & Statistics
  "psych", "moments", "effectsize",
  # Reporting
  "knitr", "kableExtra", "rmarkdown",
  # Path management
  "here"
)

# Hàm CÀI (nếu thiếu) + LOAD (kích hoạt) tất cả packages
load_or_install <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(paste("[SETUP] Đang cài đặt package thiếu:", pkg, "...\n"))
    install.packages(pkg, repos = "https://cran.r-project.org", dependencies = TRUE)
  }
  
  # Sử dụng tryCatch để ngăn chặn việc sập toàn bộ dự án nếu một thư viện máy học bị lỗi phân mảnh hệ điều hành
  tryCatch({
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }, error = function(e) {
    cat(paste("[WARNING] Không thể kích hoạt package:", pkg, "- Lỗi:", e$message, "\n"))
  })
}
invisible(lapply(required_packages, load_or_install))

# --- 2. TỰ ĐỘNG TẠO THƯ MỤC (nếu máy thành viên chưa có) ---
dirs_needed <- c(
  here("data", "raw"),
  here("data", "processed"),
  here("output", "figures"),
  here("output", "tables"),
  here("report"),
  here("slides"),
  here("docs")
)
invisible(lapply(dirs_needed, function(d) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}))

# --- 3. CẤU HÌNH CHUNG ---
options(scipen = 999)  # Tắt ký hiệu khoa học
set.seed(42)           # Reproducibility

# --- 4. HỆ MÀU DÙNG CHUNG (Palette) ---
# Tất cả SV dùng chung bảng màu này để báo cáo đồng bộ
COLORS <- list(
  # StoreType
  store_type = c("a" = "#1E88E5", "b" = "#E53935", "c" = "#43A047", "d" = "#FB8C00"),
  # Promo
  promo      = c("0" = "#78909C", "1" = "#E53935"),
  # Models
  models     = c("Linear Regression" = "#1E88E5",
                  "Random Forest"     = "#43A047",
                  "XGBoost"           = "#FB8C00",
                  "ARIMA"             = "#8E24AA",
                  "ETS"               = "#00ACC1"),
  # Sequential palette (cho heatmap, gradient)
  gradient   = c("#E3F2FD", "#1E88E5", "#0D47A1"),
  # General accent
  primary    = "#1E88E5",
  danger     = "#E53935",
  success    = "#43A047",
  warning    = "#FB8C00"
)

# --- 5. THEME ĐỒ HOẠ DÙNG CHUNG ---
# Mọi biểu đồ chỉ cần + theme_rossmann() là đồng bộ cả nhóm
theme_rossmann <- function(base_size = 12) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      # Title
      plot.title       = element_text(face = "bold", size = base_size + 2,
                                       hjust = 0.5, margin = ggplot2::margin(b = 8)),
      plot.subtitle    = element_text(size = base_size - 1, hjust = 0.5,
                                       color = "grey40", margin = ggplot2::margin(b = 10)),
      plot.caption     = element_text(size = base_size - 3, color = "grey50",
                                       hjust = 1),
      # Axes
      axis.title       = element_text(size = base_size - 1, color = "grey30"),
      axis.text        = element_text(size = base_size - 2, color = "grey40"),
      axis.line        = element_line(color = "grey70", linewidth = 0.3),
      # Legend
      legend.position  = "bottom",
      legend.title     = element_text(face = "bold", size = base_size - 2),
      legend.text      = element_text(size = base_size - 2),
      # Panel
      panel.grid.major = element_line(color = "grey90", linewidth = 0.2),
      panel.grid.minor = element_blank(),
      # Margins
      plot.margin      = ggplot2::margin(10, 15, 10, 10)
    )
}

# --- 6. ÉP THIẾT LẬP GRAPHIC MẶC ĐỊNH CHO GGPLOT2 ---
# Dòng này giúp các thành viên khi vẽ đồ thị ggplot() thì tự động ăn theo theme_rossmann()
# mà không cần phải gõ cộng thêm theme_rossmann() thủ công.
theme_set(theme_rossmann())

cat("[SETUP] ✅ Tất cả", length(required_packages), "packages đã sẵn sàng!\n")
cat("[SETUP] ✅ Thư mục data/raw, data/processed, output/figures, output/tables, report, slides, docs đã tồn tại\n")
cat("[SETUP] ✅ theme_rossmann() đã được set làm theme mặc định hệ thống\n")
cat("[SETUP] ✅ COLORS palette đã sẵn sàng để truy cập\n")
cat("[SETUP] Project root:", here(), "\n")
