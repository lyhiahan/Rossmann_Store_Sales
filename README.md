# 🏪 Rossmann Store Sales Analysis

> **Đồ án cuối kỳ** — Lập trình R cho phân tích dữ liệu

---

## 📌 Giới thiệu

Dự án phân tích và dự đoán doanh số bán hàng của chuỗi cửa hàng dược phẩm **Rossmann** tại Đức, sử dụng dữ liệu lịch sử từ **Kaggle** trong khoảng thời gian **01/08/2014 – 31/07/2015** (12 tháng), tập trung vào **50 cửa hàng** (Store 1–50).

**Nguồn dữ liệu**: [Kaggle — Rossmann Store Sales](https://www.kaggle.com/c/rossmann-store-sales)

---

## 👥 Thành viên nhóm

| STT | Họ và tên | Vai trò | File phụ trách |
|:---:|-----------|---------|----------------|
| 1 | **Quốc Anh** | Nhóm trưởng · Data Engineer · Báo cáo | `00_setup.R`, `utils.R`, `data_pipeline.R` |
| 2 | **Thanh Phúc** | Data Analyst · EDA | `eda.R` |
| 3 | **Gia Hân** | Data Visualization · Statistical Testing | `visualization.Rmd`, `statistical_tests.R` |
| 4 | **Đức Thắng** | Machine Learning Engineer | `modeling.R` |
| 5 | **Thành Tài** | Model Evaluation · Time Series · Slide | `evaluation.R`, `time_series.R` |

---

## 📁 Cấu trúc dự án

```
Rossmann_Store_Sales/
│
├── .gitignore                                  # Git ignore rules
├── .here                                       # Marker cho here package
├── README.md                                   # ← File này
│
├── data/                                       # Dữ liệu
│   ├── raw/                                    # Dữ liệu gốc từ Kaggle
│   │   ├── train.csv                           #   1,017,209 dòng × 9 cột
│   │   └── store.csv                           #   1,115 dòng × 10 cột
│   └── processed/                              # Dữ liệu sạch (pipeline tạo ra)
│       ├── df_clean.rds                        #   Toàn bộ dữ liệu đã xử lý
│       ├── train_data.rds                      #   Tập train (70%)
│       ├── val_data.rds                        #   Tập validation (30%)
│       ├── train_stats.rds                     #   Thống kê train (median, IQR)
│       ├── rossmann_clean.csv                  #   Export CSV — full
│       ├── rossmann_train_cleaned.csv          #   Export CSV — train
│       └── rossmann_val_cleaned.csv            #   Export CSV — val
│
├── R/                                          # Source code R
│   ├── 00_setup.R                              # Quốc Anh — Packages, theme, config
│   ├── utils.R                                 # Quốc Anh — Hàm tiện ích dùng chung
│   ├── data_pipeline.R                         # Quốc Anh — ETL pipeline (chống data leakage)
│   ├── statistical_tests.R                     # Gia Hân — Kiểm định thống kê
│   ├── eda.R                                   # Thanh Phúc — Phân tích khám phá dữ liệu
│   ├── visualization.Rmd                       # Gia Hân — 10 biểu đồ trực quan hóa
│   ├── modeling.R                              # Đức Thắng — 3 mô hình ML + tuning
│   ├── time_series.R                           # Thành Tài — ARIMA, ETS, STL Decomposition
│   ├── evaluation.R                            # Thành Tài — Đánh giá & so sánh mô hình
│   └── Rossmann_Store_Sales_Analysis.Rmd       # File RMD tổng hợp toàn bộ code
│
├── output/                                     # Kết quả xuất ra
│   ├── figures/                                # 44 biểu đồ PNG (EDA + Viz + Eval + TS)
│   └── tables/                                 # Models, predictions, metrics (RDS/CSV)
│       ├── models.rds                          #   3 trained models (LR, RF, XGB)
│       ├── predictions.rds                     #   Predictions + actual values
│       ├── feature_importance.rds              #   RF & XGB feature importance
│       ├── eval_results.rds                    #   Bảng so sánh metrics
│       ├── stat_tests.rds                      #   Kết quả kiểm định thống kê
│       ├── eda_results.rds                     #   Kết quả EDA
│       └── time_series_results.rds             #   ARIMA & ETS results
│
├── report/                                     # Báo cáo
│   ├── Rossmann_Store_Sales_Merged.Rmd         # File RMD tổng hợp báo cáo chính
│   └── main_report.html                        # Báo cáo HTML đã render
│
├── slides/                                     # Slide thuyết trình
│   ├── index.html                              # Slide HTML
│   ├── custom.css                              # Style slide
│   ├── custom.js                               # Logic slide
│   └── speaker_script.md                       # Kịch bản thuyết trình
│
└── docs/                                       # Tài liệu nhóm
    └── HUONG_DAN_NHOM.md                       # Hướng dẫn quy trình làm việc
```

---

## 🔬 Nội dung phân tích

### Câu hỏi nghiên cứu

1. Doanh số 50 cửa hàng Rossmann thay đổi như thế nào trong 12 tháng?
2. Khuyến mãi (Promo) có tác động đáng kể đến doanh số không?
3. Doanh thu có khác nhau giữa các loại cửa hàng (StoreType)?
4. Ngày lễ và nghỉ học ảnh hưởng đến doanh số ra sao?
5. Khoảng cách đối thủ cạnh tranh có tương quan với doanh số?
6. Mô hình nào dự đoán doanh số tốt nhất?

### Pipeline xử lý dữ liệu

```
train.csv + store.csv
        │
        ▼
   ┌─────────────────────────┐
   │  data_pipeline.R        │   Merge → Filter (Store 1-50, 08/2014–07/2015)
   │  (Quốc Anh)             │   → Clean → Split 70/30 TRƯỚC khi tính stats
   └─────────┬───────────────┘   → Feature Engineering → Export RDS + CSV
             │
     ┌───────┴───────┐
     ▼               ▼
 train_data       val_data
   (70%)            (30%)
     │               │
     ▼               ▼
 ┌───────┐     ┌───────────┐
 │ Model │────▶│ Evaluation│
 │ Train │     │ (val set) │
 └───────┘     └───────────┘
```

### Phương pháp phân tích

| Giai đoạn | Nội dung | Kỹ thuật | File |
|-----------|----------|----------|------|
| **Setup** | Cài packages, theme, bảng màu | `here`, `ggplot2` | `00_setup.R` |
| **Utils** | Hàm dùng chung: `clean_rossmann()`, `get_summary_stats()` | `dplyr` | `utils.R` |
| **Data Pipeline** | Merge, filter, clean, split 70/30, feature engineering | `dplyr`, `janitor`, `lubridate` | `data_pipeline.R` |
| **Kiểm định thống kê** | ANOVA, Welch t-test, Kruskal-Wallis, Spearman, Bootstrap CI | `stats`, `effectsize`, `car` | `statistical_tests.R` |
| **EDA** | Thống kê mô tả, phân phối, tương quan, outlier | `moments`, `ggplot2` | `eda.R` |
| **Trực quan hóa** | 10 biểu đồ nâng cao (Pareto, BCG, Waterfall, Dumbbell,...) | `ggplot2`, `plotly`, `ggcorrplot` | `visualization.Rmd` |
| **Mô hình hóa** | Linear Regression, Random Forest, XGBoost + Grid Search | `caret`, `ranger`, `xgboost` | `modeling.R` |
| **Chuỗi thời gian** | STL Decomposition, ARIMA, ETS, Forecast | `forecast` | `time_series.R` |
| **Đánh giá** | RMSE, MAE, R², RMSPE, Actual vs Predicted, Residuals | `Metrics` | `evaluation.R` |

---

## 🚀 Hướng dẫn chạy

### Yêu cầu

- **R** ≥ 4.0
- **RStudio** (khuyến nghị)
- Dữ liệu `train.csv` và `store.csv` trong `data/raw/`

### Cách 1: Chạy từng file theo thứ tự

```r
# 1. Mở project trong RStudio (thư mục chứa file .here)

# 2. Cài packages & thiết lập môi trường
source("R/00_setup.R")

# 3. Nạp hàm tiện ích
source("R/utils.R")

# 4. Chạy pipeline xử lý dữ liệu
source("R/data_pipeline.R")

# 5. Kiểm định thống kê
source("R/statistical_tests.R")

# 6. Phân tích khám phá (EDA)
source("R/eda.R")

# 7. Trực quan hóa (mở trong RStudio → Knit)
rmarkdown::render("R/visualization.Rmd")

# 8. Xây dựng mô hình (⚠️ mất ~5-10 phút do grid search)
source("R/modeling.R")

# 9. Phân tích chuỗi thời gian
source("R/time_series.R")

# 10. Đánh giá mô hình
source("R/evaluation.R")
```

### Cách 2: Chạy file RMD tổng hợp (all-in-one)

```r
# Render toàn bộ phân tích thành HTML
rmarkdown::render("R/Rossmann_Store_Sales_Analysis.Rmd")
```

> ⚠️ **Lưu ý**: File tổng hợp chạy toàn bộ pipeline từ đầu. Thời gian render khoảng 15–20 phút do bao gồm grid search XGBoost (9 combos) và Random Forest tuning.

---

## 📊 Tổng quan kết quả

### Kiểm định thống kê

| Kiểm định | Kết quả | Ý nghĩa |
|-----------|---------|----------|
| ANOVA: Sales ~ StoreType | p < 0.001 | Doanh thu khác biệt giữa các loại cửa hàng |
| Welch t-test: Sales ~ Promo | p < 0.001 | Khuyến mãi tăng doanh thu có ý nghĩa thống kê |
| Spearman: Sales ~ CompDist | \|ρ\| ≈ 0 | Khoảng cách đối thủ không ảnh hưởng đáng kể |

### So sánh mô hình

| Mô hình | RMSE | MAE | R² | RMSPE |
|---------|------|-----|----|-------|
| Linear Regression | Cao nhất | Cao nhất | Thấp nhất | Cao nhất |
| Random Forest | Trung bình | Trung bình | Cao | Trung bình |
| **XGBoost** | **Thấp nhất** | **Thấp nhất** | **Cao nhất** | **Thấp nhất** |

> 🏆 **XGBoost** là mô hình tốt nhất trên tất cả các chỉ số đánh giá.

---

## 📦 Packages sử dụng

| Nhóm | Packages |
|------|----------|
| Xử lý dữ liệu | `dplyr`, `tidyr`, `lubridate`, `janitor`, `readr`, `tibble`, `here` |
| Trực quan hóa | `ggplot2`, `plotly`, `ggcorrplot`, `corrplot`, `scales`, `gridExtra`, `RColorBrewer` |
| Mô hình hóa | `caret`, `randomForest`, `ranger`, `xgboost`, `Metrics` |
| Chuỗi thời gian | `forecast` |
| Thống kê | `psych`, `moments`, `effectsize`, `car` |
| Báo cáo | `rmarkdown`, `knitr`, `kableExtra` |

---

## ⚙️ Thiết kế chống rò rỉ dữ liệu (Data Leakage)

Dự án áp dụng nguyên tắc **chia tập dữ liệu TRƯỚC khi tính toán thống kê**:

1. **Split trước** → `train_data` (70%) và `val_data` (30%) bằng random sampling
2. **Tính stats trên train** → `median(competition_distance)`, IQR bounds
3. **Áp dụng stats cho cả hai** → đảm bảo validation set không bị "nhìn trước"
4. **`sales_per_customer`** → CHỈ dùng cho EDA, **TUYỆT ĐỐI KHÔNG** đưa vào model (Target Leakage)

---

## 📜 License

Dự án phục vụ mục đích học tập. Dữ liệu thuộc bản quyền Kaggle/Rossmann.
