# 📋 HƯỚNG DẪN LÀM VIỆC NHÓM — Rossmann Store Sales Analysis

> **⚠️ QUY TẮC VÀNG: Mỗi người CHỈ chỉnh sửa file của mình. KHÔNG sửa file của người khác.**

---

## 📁 Cấu Trúc Thư Mục

```
rossman-sale-store/
│
├── .gitignore                        # Bỏ qua file tạm, output
├── .here                             # Marker cho here package
│
├── data/
│   ├── raw/                          # Dữ liệu gốc (KHÔNG CHỈNH SỬA)
│   │   ├── train.csv
│   │   └── store.csv
│   └── processed/                    # Dữ liệu đã xử lý (tái tạo từ code)
│       ├── df_clean.rds              # Quốc Anh tạo → cả nhóm đọc
│       ├── train_data.rds            # Quốc Anh tạo → Đức Thắng đọc
│       ├── val_data.rds              # Quốc Anh tạo → Đức Thắng đọc
│       ├── train_stats.rds           # Quốc Anh tạo (median + IQR từ TRAIN)
│       └── *.csv                     # Bản CSV tương ứng
│
├── R/                                # ⭐ THƯ MỤC CODE CHÍNH
│   ├── 00_setup.R                    # Shared: packages + config (Quốc Anh quản lý)
│   ├── data_pipeline.R               # 🔒 Quốc Anh ONLY
│   ├── utils.R                       # 🔒 Quốc Anh ONLY (cả nhóm GỌI, không SỬA)
│   ├── statistical_tests.R           # 🔒 Quốc Anh ONLY
│   ├── eda.R                         # 🔒 Thanh Phúc ONLY
│   ├── visualization.R               # 🔒 Gia Hân ONLY
│   ├── modeling.R                    # 🔒 Đức Thắng ONLY
│   ├── evaluation.R                  # 🔒 Thành Tài ONLY
│   └── time_series.R                 # 🔒 Thành Tài ONLY
│
├── output/
│   ├── figures/                      # Biểu đồ PNG (EDA, Viz, Evaluation)
│   └── tables/                       # Kết quả RDS (stat_tests, models, eval)
│       ├── stat_tests.rds            # Quốc Anh tạo
│       ├── eda_results.rds           # Thanh Phúc tạo
│       ├── models.rds                # Đức Thắng tạo → Thành Tài đọc
│       ├── predictions.rds           # Đức Thắng tạo → Thành Tài đọc
│       ├── feature_importance.rds    # Đức Thắng tạo → Thành Tài đọc
│       ├── eval_results.rds          # Thành Tài tạo
│       └── time_series_results.rds   # Thành Tài tạo
│
├── report/
│   └── main_report.Rmd              # File Rmd chính — source() tất cả R/
│
├── slides/                           # Slide trình bày (.pptx)
│
└── docs/
    └── HUONG_DAN_NHOM.md             # ← File này
```

---

## 🔗 Luồng Dữ Liệu Giữa Các Thành Viên

```
Quốc Anh: data/raw/train.csv + data/raw/store.csv
 ↓ data_pipeline.R + saveRDS()
 ├── data/processed/df_clean.rds ──→ Thanh Phúc (EDA), Gia Hân (Viz), Thành Tài (TS)
 ├── data/processed/train_data.rds → Đức Thắng (Modeling)
 ├── data/processed/val_data.rds ──→ Đức Thắng (Modeling)
 └── data/processed/train_stats.rds (median + IQR từ TRAIN ONLY)
                              ↓ saveRDS()
                              ├── output/tables/models.rds ──────→ Thành Tài
                              ├── output/tables/predictions.rds ─→ Thành Tài
                              └── output/tables/feature_importance.rds → Thành Tài
```

**Thứ tự chạy code:**
1. `R/00_setup.R` → cài packages
2. `R/utils.R` → load hàm dùng chung
3. `R/data_pipeline.R` → tạo RDS files
4. `R/statistical_tests.R` → kiểm định thống kê
5. `R/eda.R` → EDA (cần `df_clean.rds`)
6. `R/visualization.R` → biểu đồ (cần `df_clean.rds`)
7. `R/modeling.R` → mô hình (cần `train_data.rds`, `val_data.rds`)
8. `R/evaluation.R` → đánh giá (cần `predictions.rds`, `feature_importance.rds`)
9. `R/time_series.R` → phân tích chuỗi thời gian (cần `df_clean.rds`)

---

## 📏 QUY ƯỚC CODE

### Đường dẫn file
```r
# ✅ ĐÚNG — Luôn dùng here()
df <- readRDS(here("data", "processed", "df_clean.rds"))
ggsave(here("output", "figures", "p1_trend.png"), p1)
saveRDS(results, here("output", "tables", "eval_results.rds"))

# ❌ SAI — Không dùng đường dẫn cứng
df <- readRDS("D:/uni/.../data/processed/df_clean.rds")
df <- readRDS("../data/processed/df_clean.rds")
```

### Đặt tên biến
```r
# ✅ snake_case (sau clean_names())
sales_per_customer, store_type, day_of_week, competition_distance

# ❌ Không dùng camelCase hay PascalCase
salesPerCustomer, StoreType, DayOfWeek
```

### Header file
Mỗi file R phải có header:
```r
# =============================================================================
# TVx — TÊN MODULE
# File: R/tvx_tên_file.R
# Người phụ trách: Thành viên x
# Mô tả: [mô tả ngắn]
# =============================================================================
# CHÚ Ý: Chỉ TVx được chỉnh sửa file này!
# =============================================================================
```

### Ghi log
```r
cat("[TVx] ✅ Mô tả hành động hoàn tất\n")
cat("[TVx] Số dòng:", nrow(df), "\n")
```

### Lưu output
```r
# Data đã xử lý → data/processed/
saveRDS(object, here("data", "processed", "tên_file.rds"))
# Kết quả phân tích → output/tables/
saveRDS(object, here("output", "tables", "tên_file.rds"))
# Biểu đồ → output/figures/
ggsave(here("output", "figures", "tên_plot.png"), plot, width=10, height=5, dpi=150)
```

---

## 🔒 PHÂN QUYỀN CHI TIẾT

### Bảng quyền truy cập

| File | Quốc Anh | Thanh Phúc | Gia Hân | Đức Thắng | Thành Tài |
|------|:---:|:---:|:---:|:---:|:---:|
| `00_setup.R` | ✏️ Sửa | ❌ | ❌ | ❌ | ❌ |
| `data_pipeline.R` | ✏️ Sửa | ❌ | ❌ | ❌ | ❌ |
| `utils.R` | ✏️ Sửa | 📖 Gọi | 📖 Gọi | 📖 Gọi | 📖 Gọi |
| `statistical_tests.R` | ✏️ Sửa | ❌ | ❌ | ❌ | ❌ |
| `eda.R` | ❌ | ✏️ Sửa | ❌ | ❌ | ❌ |
| `visualization.R` | ❌ | ❌ | ✏️ Sửa | ❌ | ❌ |
| `modeling.R` | ❌ | ❌ | ❌ | ✏️ Sửa | ❌ |
| `evaluation.R` | ❌ | ❌ | ❌ | ❌ | ✏️ Sửa |
| `time_series.R` | ❌ | ❌ | ❌ | ❌ | ✏️ Sửa |
| `report/main_report.Rmd` | ✏️ Sửa | ❌ | ❌ | ❌ | ✏️ YAML |
| `train.csv` / `store.csv` | ❌ | ❌ | ❌ | ❌ | ❌ |

> ✏️ = Được chỉnh sửa | 📖 = Chỉ đọc / gọi hàm | ❌ = Không chạm vào

---

## 👤 HƯỚNG DẪN CHI TIẾT TỪNG THÀNH VIÊN

---

### 🟦 Quốc Anh — Nhóm Trưởng · Data Engineer · Báo Cáo

**Files của bạn:**
- `R/00_setup.R`
- `R/data_pipeline.R`
- `R/utils.R`
- `R/statistical_tests.R`

**Output bạn tạo:**
- `data/processed/df_clean.rds` — data sạch, cả nhóm dùng
- `data/processed/train_data.rds` — training set cho Đức Thắng
- `data/processed/val_data.rds` — validation set cho Đức Thắng
- `data/processed/train_stats.rds` — median + IQR từ TRAIN (chống leakage)
- `output/tables/stat_tests.rds` — kết quả kiểm định

**Coding tasks (13 tasks):**

| # | Task | File |
|---|------|------|
| 1 | Đọc & merge `train.csv` + `store.csv` | `data_pipeline.R` |
| 2 | Lọc Store 1–50, Date range, Open==1 | `data_pipeline.R` |
| 3 | `clean_names()`, xử lý NA, convert types | `data_pipeline.R` |
| 4 | Feature engineering: Month, WeekOfYear, IsWeekend, SalesPerCustomer | `data_pipeline.R` |
| 5 | Phát hiện outlier IQR → flag `is_outlier`, KHÔNG xóa | `data_pipeline.R` |
| 6 | Train/val split 70/30 với `set.seed(42)` | `data_pipeline.R` |
| 7 | `saveRDS()` toàn bộ output | `data_pipeline.R` |
| 8 | Viết hàm `clean_rossmann()` | `utils.R` |
| 9 | Viết hàm `get_summary_stats(df, group_var)` | `utils.R` |
| 10 | Viết hàm `mock_data()` | `utils.R` |
| 11 | ANOVA: `sales ~ store_type` + Tukey post-hoc | `statistical_tests.R` |
| 12 | Welch t-test: `sales ~ promo` + Cohen's d | `statistical_tests.R` |
| 13 | Correlation: `cor.test(sales, competition_distance)` | `statistical_tests.R` |

**Viết báo cáo:**
- Sections 1–2 (Abstract, Introduction) trong Rmd
- Section 3.1–3.4 (Data description)
- Section 7 (Kết luận)
- Review & tổng hợp Rmd cuối cùng

**Khi nào chạy:** Chạy ĐẦU TIÊN, trước tất cả thành viên khác.

**Lệnh chạy test:**
```r
source(here::here("R", "00_setup.R"))
source(here::here("R", "utils.R"))
source(here::here("R", "data_pipeline.R"))
source(here::here("R", "statistical_tests.R"))
# Kiểm tra output
file.exists(here("data", "processed", "df_clean.rds"))     # TRUE
file.exists(here("data", "processed", "train_data.rds"))    # TRUE
file.exists(here("data", "processed", "val_data.rds"))      # TRUE
```

---

### 🟩 Thanh Phúc — Data Analyst · EDA

**Files của bạn:**
- `R/eda.R`

**Input bạn cần:**
- `data/processed/df_clean.rds` (Quốc Anh tạo)
- Hàm `get_summary_stats()` từ `R/utils.R`

**Output bạn tạo:**
- `output/tables/eda_results.rds`

**Coding tasks (8 tasks):**

| # | Task | Chi tiết |
|---|------|---------|
| 1 | Summary statistics tất cả biến | `summary()`, `pivot_longer()` + `summarise()` |
| 2 | Phân phối Sales, Customers | `shapiro.test()`, skewness, kurtosis |
| 3 | Correlation matrix | `cor()` trên biến numeric |
| 4 | Phân tích theo nhóm: StoreType, Promo, Assortment, DayOfWeek | `get_summary_stats(df, store_type)` |
| 5 | Ảnh hưởng ngày lễ (StateHoliday, SchoolHoliday) | `group_by() %>% summarise()` |
| 6 | CompetitionDistance vs Sales | `cut()` theo khoảng cách + summarise |
| 7 | Bảng tổng hợp bằng `kableExtra` | `kable() %>% kable_styling()` |
| 8 | Viết phần EDA + Phụ lục | Sections 3.5, 8 |

**⚠️ Khi chưa có `df_clean.rds`:**
```r
# Dùng mock data từ Quốc Anh để dev
source(here::here("R", "utils.R"))
df <- mock_data(n = 2000)
```

**Lệnh chạy test:**
```r
source(here::here("R", "00_setup.R"))
source(here::here("R", "utils.R"))
source(here::here("R", "eda.R"))
file.exists(here("output", "tables", "eda_results.rds"))   # TRUE
```

---

### 🟧 Gia Hân — Data Visualization

**Files của bạn:**
- `R/visualization.R`

**Input bạn cần:**
- `data/processed/df_clean.rds` (Quốc Anh tạo)

**Output bạn tạo:**
- 10 file PNG trong `output/figures/`

**Coding tasks (10 tasks):**

| # | Task | Loại biểu đồ | File output |
|---|------|-------------|------------|
| 1 | Xu hướng doanh số theo ngày | `geom_line()` + `geom_smooth()` | `p1_line_trend.png` |
| 2 | Doanh số TB theo DayOfWeek | `geom_col()` | `p2_bar_dayofweek.png` |
| 3 | Phân phối Sales theo StoreType | `geom_boxplot()` | `p3_boxplot_storetype.png` |
| 4 | Phân phối Sales (histogram + density) | `geom_histogram()` + `geom_density()` | `p4_histogram_density.png` |
| 5 | Correlation heatmap | `ggcorrplot()` | `p5_heatmap_correlation.png` |
| 6 | Customers vs Sales | `geom_point()` + `geom_smooth(method="lm")` | `p6_scatter_customers_sales.png` |
| 7 | Sales theo Promo (violin) | `geom_violin()` + `geom_boxplot()` | `p7_violin_promo.png` |
| 8 | Monthly trends by StoreType | `facet_wrap()` | `p8_faceted_monthly.png` |
| 9 | Stacked area theo StoreType | `geom_area()` | `p9_stacked_area.png` |
| 10 | Interactive plotly | `ggplotly()` | (không lưu file, hiển thị trong Rmd) |

**Quy ước biểu đồ:**
- Theme chung: `theme_rossman` (định nghĩa trong file)
- Bảng màu StoreType: `a=#2196F3, b=#E53935, c=#4CAF50, d=#FF9800`
- Tất cả plot lưu bằng `ggsave()` vào `output/figures/`
- Kích thước mặc định: `width=10, height=5, dpi=150`

**Lệnh chạy test:**
```r
source(here::here("R", "00_setup.R"))
source(here::here("R", "visualization.R"))
length(list.files(here("output", "figures"), pattern = "\\.png$"))  # >= 9
```

---

### 🟥 Đức Thắng — ML Engineer

**Files của bạn:**
- `R/modeling.R`

**Input bạn cần:**
- `data/processed/train_data.rds` (Quốc Anh tạo)
- `data/processed/val_data.rds` (Quốc Anh tạo)

**Output bạn tạo:**
- `output/tables/models.rds` — 3 trained models
- `output/tables/predictions.rds` — predictions + actual (Thành Tài cần)
- `output/tables/feature_importance.rds` — RF + XGBoost importance (Thành Tài cần)

**Coding tasks (7 tasks):**

| # | Task | Package |
|---|------|---------|
| 1 | `prepare_features()` — encode categorical, chọn features | `dplyr` |
| 2 | Đọc train/test từ Quốc Anh RDS | `readRDS()` |
| 3 | Model 1: Linear Regression + `summary()` | `stats::lm()` |
| 4 | Model 2: Random Forest + importance | `ranger` |
| 5 | Model 3: XGBoost + `xgb.cv()` + tuning | `xgboost` |
| 6 | `predict()` trên test set (3 models) | `predict()` |
| 7 | `saveRDS()` models + predictions + feature importance | `saveRDS()` |

**Lệnh chạy test:**
```r
source(here::here("R", "00_setup.R"))
source(here::here("R", "modeling.R"))
file.exists(here("output", "tables", "models.rds"))              # TRUE
file.exists(here("output", "tables", "predictions.rds"))          # TRUE
file.exists(here("output", "tables", "feature_importance.rds"))   # TRUE
```

---

### 🟪 Thành Tài — Report Manager · Model Evaluation · Slide

**Files của bạn:**
- `R/evaluation.R`
- `R/time_series.R`

**Input bạn cần:**
- `output/tables/predictions.rds` (Đức Thắng tạo)
- `output/tables/feature_importance.rds` (Đức Thắng tạo)

**Output bạn tạo:**
- `output/tables/eval_results.rds`
- `output/figures/p_metrics_comparison.png`
- `output/figures/p_actual_vs_predicted.png`
- `output/figures/p_residuals.png`
- `output/figures/p_feature_importance.png`

**Coding tasks (7 tasks):**

| # | Task | Chi tiết |
|---|------|---------|
| 1 | Bảng so sánh RMSE, MAE, R², RMSPE | `tibble()` + `kable()` |
| 2 | Bar chart so sánh metrics | `geom_col()` + `facet_wrap()` |
| 3 | Actual vs Predicted (3 models) | `geom_point()` + `facet_wrap()` |
| 4 | Residual histogram (3 models) | `geom_histogram()` + `facet_wrap()` |
| 5 | Feature importance top 10 (RF + XGB) | `geom_col()` + `coord_flip()` |
| 6 | Cấu hình YAML knit Rmd → Word | `reference_docx`, `toc`, `fig_caption` |
| 7 | Script auto-extract key metrics cho slide | `cat()` key numbers |

**Viết & trình bày:**
- Tạo template Word + format 11 sections
- Thiết kế PowerPoint 15–20 slides
- Viết Contributions, References, Peer Assessment (Sections 9, 10, 11)
- Review & chỉnh sửa lần cuối

**Lệnh chạy test:**
```r
source(here::here("R", "00_setup.R"))
source(here::here("R", "evaluation.R"))
source(here::here("R", "time_series.R"))
file.exists(here("output", "tables", "eval_results.rds"))   # TRUE
```

---

## ⏰ QUY TRÌNH LÀM VIỆC

### Khi bắt đầu

1. Clone/copy project về máy
2. Mở RStudio, set working directory = thư mục `rossman-sale-store/`
3. Chạy `source(here::here("R", "00_setup.R"))` để cài packages
4. Chạy file code của bạn

### Trước khi nộp

Quốc Anh chạy toàn bộ pipeline từ đầu:
```r
source(here::here("R", "00_setup.R"))
source(here::here("R", "utils.R"))
source(here::here("R", "data_pipeline.R"))
source(here::here("R", "statistical_tests.R"))
source(here::here("R", "eda.R"))
source(here::here("R", "visualization.R"))
source(here::here("R", "modeling.R"))
source(here::here("R", "evaluation.R"))
source(here::here("R", "time_series.R"))

# Knit Rmd
rmarkdown::render(here::here("report", "main_report.Rmd"))
```

### Checklist nộp bài

- [ ] 1 file `.R` (hoặc `.Rmd` chứa code)
- [ ] 1 file `.docx` (báo cáo Word, knit từ Rmd)
- [ ] 1 file `.pptx` (PowerPoint tóm tắt)
- [ ] Đủ 11 sections theo cấu trúc đề bài
- [ ] ≥ 8 loại biểu đồ khác nhau
- [ ] ≥ 3 mô hình phân tích
- [ ] Peer Assessment có đánh giá từng thành viên

---

*Tạo ngày: 2026-06-03 | Cập nhật lần cuối: 2026-06-04 bởi Quốc Anh (Nhóm trưởng)*
