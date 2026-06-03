# 📋 HƯỚNG DẪN LÀM VIỆC NHÓM — Rossmann Store Sales Analysis

> **⚠️ QUY TẮC VÀNG: Mỗi người CHỈ chỉnh sửa file của mình. KHÔNG sửa file của người khác.**

---

## 📁 Cấu Trúc Thư Mục

```
rossman-sale-store/
│
├── .gitignore                        # Bỏ qua file tạm, output
├── .here                             # Marker cho here package
├── HUONG_DAN_NHOM.md                 # ← File này
│
├── train.csv                         # Dữ liệu gốc (KHÔNG CHỈNH SỬA)
├── store.csv                         # Dữ liệu gốc (KHÔNG CHỈNH SỬA)
│
├── R/                                # ⭐ THƯ MỤC CODE CHÍNH
│   ├── 00_setup.R                    # Shared: packages + config (TV1 quản lý)
│   ├── tv1_data_pipeline.R           # 🔒 TV1 ONLY
│   ├── tv1_utils.R                   # 🔒 TV1 ONLY (cả nhóm GỌI, không SỬA)
│   ├── tv1_statistical_tests.R       # 🔒 TV1 ONLY
│   ├── tv2_eda.R                     # 🔒 TV2 ONLY
│   ├── tv3_visualization.R           # 🔒 TV3 ONLY
│   ├── tv4_modeling.R                # 🔒 TV4 ONLY
│   └── tv5_evaluation.R             # 🔒 TV5 ONLY
│
├── rossman_analysis.Rmd              # File Rmd chính — source() tất cả R/
│
├── output/
│   ├── data/                         # RDS files (tái tạo từ code)
│   │   ├── df_clean.rds              # TV1 tạo → cả nhóm đọc
│   │   ├── train_data.rds            # TV1 tạo → TV4 đọc
│   │   ├── test_data.rds             # TV1 tạo → TV4 đọc
│   │   ├── stat_tests.rds            # TV1 tạo
│   │   ├── eda_results.rds           # TV2 tạo
│   │   ├── models.rds                # TV4 tạo → TV5 đọc
│   │   ├── predictions.rds           # TV4 tạo → TV5 đọc
│   │   ├── feature_importance.rds    # TV4 tạo → TV5 đọc
│   │   └── eval_results.rds          # TV5 tạo
│   └── figures/                      # Biểu đồ PNG (TV3, TV5 tạo)
│
└── report/
    ├── reference_template.docx       # Template Word (TV5 tạo)
    ├── rossman_report.docx           # Báo cáo Word (knit từ Rmd)
    └── rossman_presentation.pptx     # PowerPoint (TV5 tạo)
```

---

## 🔗 Luồng Dữ Liệu Giữa Các Thành Viên

```
TV1: train.csv + store.csv
 ↓ clean_rossmann() + saveRDS()
 ├── df_clean.rds ─────→ TV2 (EDA), TV3 (Viz)
 ├── train_data.rds ───→ TV4 (Modeling)
 └── test_data.rds ────→ TV4 (Modeling)
                              ↓ saveRDS()
                              ├── models.rds ──────→ TV5 (Evaluation)
                              ├── predictions.rds ─→ TV5 (Evaluation)
                              └── feature_importance.rds → TV5
```

**Thứ tự chạy code:**
1. `R/00_setup.R` → cài packages
2. `R/tv1_utils.R` → load hàm dùng chung
3. `R/tv1_data_pipeline.R` → tạo RDS files
4. `R/tv1_statistical_tests.R` → kiểm định thống kê
5. `R/tv2_eda.R` → EDA (cần `df_clean.rds`)
6. `R/tv3_visualization.R` → biểu đồ (cần `df_clean.rds`)
7. `R/tv4_modeling.R` → mô hình (cần `train_data.rds`, `test_data.rds`)
8. `R/tv5_evaluation.R` → đánh giá (cần `predictions.rds`, `feature_importance.rds`)

---

## 📏 QUY ƯỚC CODE

### Đường dẫn file
```r
# ✅ ĐÚNG — Luôn dùng here()
df <- readRDS(here("output", "data", "df_clean.rds"))
ggsave(here("output", "figures", "p1_trend.png"), p1)

# ❌ SAI — Không dùng đường dẫn cứng
df <- readRDS("D:/uni/.../output/data/df_clean.rds")
df <- readRDS("../output/data/df_clean.rds")
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
saveRDS(object, here("output", "data", "tên_file.rds"))
ggsave(here("output", "figures", "tên_plot.png"), plot, width=10, height=5, dpi=150)
```

---

## 🔒 PHÂN QUYỀN CHI TIẾT

### Bảng quyền truy cập

| File | TV1 | TV2 | TV3 | TV4 | TV5 |
|------|:---:|:---:|:---:|:---:|:---:|
| `00_setup.R` | ✏️ Sửa | ❌ | ❌ | ❌ | ❌ |
| `tv1_data_pipeline.R` | ✏️ Sửa | ❌ | ❌ | ❌ | ❌ |
| `tv1_utils.R` | ✏️ Sửa | 📖 Gọi | 📖 Gọi | 📖 Gọi | 📖 Gọi |
| `tv1_statistical_tests.R` | ✏️ Sửa | ❌ | ❌ | ❌ | ❌ |
| `tv2_eda.R` | ❌ | ✏️ Sửa | ❌ | ❌ | ❌ |
| `tv3_visualization.R` | ❌ | ❌ | ✏️ Sửa | ❌ | ❌ |
| `tv4_modeling.R` | ❌ | ❌ | ❌ | ✏️ Sửa | ❌ |
| `tv5_evaluation.R` | ❌ | ❌ | ❌ | ❌ | ✏️ Sửa |
| `rossman_analysis.Rmd` | ✏️ Sửa | ❌ | ❌ | ❌ | ✏️ YAML |
| `train.csv` / `store.csv` | ❌ | ❌ | ❌ | ❌ | ❌ |

> ✏️ = Được chỉnh sửa | 📖 = Chỉ đọc / gọi hàm | ❌ = Không chạm vào

---

## 👤 HƯỚNG DẪN CHI TIẾT TỪNG THÀNH VIÊN

---

### 🟦 TV1 — Nhóm Trưởng · Data Engineer · Báo Cáo

**Files của bạn:**
- `R/00_setup.R`
- `R/tv1_data_pipeline.R`
- `R/tv1_utils.R`
- `R/tv1_statistical_tests.R`

**Output bạn tạo:**
- `output/data/df_clean.rds` — data sạch, cả nhóm dùng
- `output/data/train_data.rds` — training set cho TV4
- `output/data/test_data.rds` — test set cho TV4
- `output/data/stat_tests.rds` — kết quả kiểm định

**Coding tasks (13 tasks):**

| # | Task | File |
|---|------|------|
| 1 | Đọc & merge `train.csv` + `store.csv` | `tv1_data_pipeline.R` |
| 2 | Lọc Store 1–50, Date range, Open==1 | `tv1_data_pipeline.R` |
| 3 | `clean_names()`, xử lý NA, convert types | `tv1_data_pipeline.R` |
| 4 | Feature engineering: Month, WeekOfYear, IsWeekend, SalesPerCustomer | `tv1_data_pipeline.R` |
| 5 | Phát hiện outlier IQR → flag `is_outlier`, KHÔNG xóa | `tv1_data_pipeline.R` |
| 6 | Train/test split theo thời gian (KHÔNG random) | `tv1_data_pipeline.R` |
| 7 | `saveRDS()` toàn bộ output | `tv1_data_pipeline.R` |
| 8 | Viết hàm `clean_rossmann()` | `tv1_utils.R` |
| 9 | Viết hàm `get_summary_stats(df, group_var)` | `tv1_utils.R` |
| 10 | Viết hàm `mock_data()` | `tv1_utils.R` |
| 11 | ANOVA: `sales ~ store_type` + Tukey post-hoc | `tv1_statistical_tests.R` |
| 12 | Welch t-test: `sales ~ promo` + Cohen's d | `tv1_statistical_tests.R` |
| 13 | Correlation: `cor.test(sales, competition_distance)` | `tv1_statistical_tests.R` |

**Viết báo cáo:**
- Sections 1–2 (Abstract, Introduction) trong Rmd
- Section 3.1–3.4 (Data description)
- Section 7 (Kết luận)
- Review & tổng hợp Rmd cuối cùng

**Khi nào chạy:** Chạy ĐẦU TIÊN, trước tất cả thành viên khác.

**Lệnh chạy test:**
```r
source(here::here("R", "00_setup.R"))
source(here::here("R", "tv1_utils.R"))
source(here::here("R", "tv1_data_pipeline.R"))
source(here::here("R", "tv1_statistical_tests.R"))
# Kiểm tra output
file.exists(here("output", "data", "df_clean.rds"))     # TRUE
file.exists(here("output", "data", "train_data.rds"))    # TRUE
file.exists(here("output", "data", "test_data.rds"))     # TRUE
```

---

### 🟩 TV2 — Data Analyst · EDA

**Files của bạn:**
- `R/tv2_eda.R`

**Input bạn cần:**
- `output/data/df_clean.rds` (TV1 tạo)
- Hàm `get_summary_stats()` từ `R/tv1_utils.R`

**Output bạn tạo:**
- `output/data/eda_results.rds`

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
# Dùng mock data từ TV1 để dev
source(here::here("R", "tv1_utils.R"))
df <- mock_data(n = 2000)
```

**Lệnh chạy test:**
```r
source(here::here("R", "00_setup.R"))
source(here::here("R", "tv1_utils.R"))
source(here::here("R", "tv2_eda.R"))
file.exists(here("output", "data", "eda_results.rds"))   # TRUE
```

---

### 🟧 TV3 — Data Visualization

**Files của bạn:**
- `R/tv3_visualization.R`

**Input bạn cần:**
- `output/data/df_clean.rds` (TV1 tạo)

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
source(here::here("R", "tv3_visualization.R"))
length(list.files(here("output", "figures"), pattern = "\\.png$"))  # >= 9
```

---

### 🟥 TV4 — ML Engineer

**Files của bạn:**
- `R/tv4_modeling.R`

**Input bạn cần:**
- `output/data/train_data.rds` (TV1 tạo)
- `output/data/test_data.rds` (TV1 tạo)

**Output bạn tạo:**
- `output/data/models.rds` — 3 trained models
- `output/data/predictions.rds` — predictions + actual (TV5 cần)
- `output/data/feature_importance.rds` — RF + XGBoost importance (TV5 cần)

**Coding tasks (7 tasks):**

| # | Task | Package |
|---|------|---------|
| 1 | `prepare_features()` — encode categorical, chọn features | `dplyr` |
| 2 | Đọc train/test từ TV1 RDS | `readRDS()` |
| 3 | Model 1: Linear Regression + `summary()` | `stats::lm()` |
| 4 | Model 2: Random Forest + importance | `ranger` |
| 5 | Model 3: XGBoost + `xgb.cv()` + tuning | `xgboost` |
| 6 | `predict()` trên test set (3 models) | `predict()` |
| 7 | `saveRDS()` models + predictions + feature importance | `saveRDS()` |

**Lệnh chạy test:**
```r
source(here::here("R", "00_setup.R"))
source(here::here("R", "tv4_modeling.R"))
file.exists(here("output", "data", "models.rds"))              # TRUE
file.exists(here("output", "data", "predictions.rds"))          # TRUE
file.exists(here("output", "data", "feature_importance.rds"))   # TRUE
```

---

### 🟪 TV5 — Report Manager · Model Evaluation · Slide

**Files của bạn:**
- `R/tv5_evaluation.R`

**Input bạn cần:**
- `output/data/predictions.rds` (TV4 tạo)
- `output/data/feature_importance.rds` (TV4 tạo)

**Output bạn tạo:**
- `output/data/eval_results.rds`
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
source(here::here("R", "tv5_evaluation.R"))
file.exists(here("output", "data", "eval_results.rds"))   # TRUE
```

---

## ⏰ QUY TRÌNH LÀM VIỆC

### Khi bắt đầu

1. Clone/copy project về máy
2. Mở RStudio, set working directory = thư mục `rossman-sale-store/`
3. Chạy `source(here::here("R", "00_setup.R"))` để cài packages
4. Chạy file code của bạn

### Trước khi nộp

TV1 chạy toàn bộ pipeline từ đầu:
```r
source(here::here("R", "00_setup.R"))
source(here::here("R", "tv1_utils.R"))
source(here::here("R", "tv1_data_pipeline.R"))
source(here::here("R", "tv1_statistical_tests.R"))
source(here::here("R", "tv2_eda.R"))
source(here::here("R", "tv3_visualization.R"))
source(here::here("R", "tv4_modeling.R"))
source(here::here("R", "tv5_evaluation.R"))

# Knit Rmd
rmarkdown::render(here::here("rossman_analysis.Rmd"))
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

*Tạo ngày: 2026-06-03 | Cập nhật bởi TV1 (Nhóm trưởng)*
