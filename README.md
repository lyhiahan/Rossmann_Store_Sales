# 🏪 Rossmann Store Sales Analysis

> **Đồ án cuối kỳ** — Lập trình R cho phân tích dữ liệu

---

## 📌 Giới thiệu

Dự án phân tích và dự đoán doanh số bán hàng của chuỗi cửa hàng dược phẩm **Rossmann** tại Đức, sử dụng dữ liệu lịch sử từ **Kaggle** trong khoảng thời gian **01/08/2014 – 31/07/2015** (12 tháng), tập trung vào **50 cửa hàng** (Store 1–50).

**Nguồn dữ liệu**: [Kaggle — Rossmann Store Sales](https://www.kaggle.com/c/rossmann-store-sales)

---

## 👥 Thành viên nhóm

| STT | Họ và tên | Vai trò | File phụ trách |
|:---:|-----------|---------|---------------|
| 1 | **Quốc Anh** | Nhóm trưởng · Data Engineer · Báo cáo | `data_pipeline.R`, `utils.R`, `statistical_tests.R` |
| 2 | **Thanh Phúc** | Data Analyst · EDA | `eda.R` |
| 3 | **Gia Hân** | Data Visualization | `visualization.R` |
| 4 | **Đức Thắng** | Machine Learning Engineer | `modeling.R` |
| 5 | **Thành Tài** | Report Manager · Model Evaluation · Slide | `evaluation.R`, `time_series.R` |

---

## 📁 Cấu trúc dự án

```
rossman-sale-store/
│
├── .gitignore
├── .here                             # Marker cho here package
├── README.md                         # ← File này
├── HUONG_DAN_NHOM.md                 # Hướng dẫn chi tiết phân công & quy ước
│
├── train.csv                         # Dữ liệu gốc — 1,017,210 dòng
├── store.csv                         # Thông tin 1,115 cửa hàng
│
├── R/                                # Code R — mỗi người 1 file riêng
│   ├── 00_setup.R                    # Cài packages & cấu hình chung
│   ├── data_pipeline.R               # Quốc Anh — Data pipeline
│   ├── utils.R                       # Quốc Anh — Hàm dùng chung
│   ├── statistical_tests.R           # Quốc Anh — Kiểm định thống kê
│   ├── eda.R                         # Thanh Phúc — EDA
│   ├── visualization.R               # Gia Hân — 10 biểu đồ
│   ├── modeling.R                    # Đức Thắng — 3 mô hình ML
│   ├── evaluation.R                  # Thành Tài — Đánh giá mô hình
│   └── time_series.R                 # Thành Tài — Phân tích chuỗi thời gian
│
├── rossman_analysis.Rmd              # File RMarkdown chính (source tất cả R/)
│
├── output/
│   ├── data/                         # RDS files (tạo khi chạy code)
│   └── figures/                      # Biểu đồ PNG
│
└── report/
    ├── rossman_report.docx           # Báo cáo Word
    └── rossman_presentation.pptx     # Slide trình bày
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

### Phương pháp

| Giai đoạn | Nội dung | Kỹ thuật |
|-----------|----------|----------|
| **Làm sạch dữ liệu** | Merge, lọc, xử lý NA, outlier flag | `dplyr`, `janitor`, `lubridate` |
| **Kiểm định thống kê** | ANOVA, Welch t-test, Spearman correlation | `stats` |
| **Trực quan hóa** | 10 loại biểu đồ khác nhau | `ggplot2`, `plotly`, `ggcorrplot` |
| **Mô hình hóa** | Linear Regression, Random Forest, XGBoost | `caret`, `ranger`, `xgboost` |
| **Đánh giá** | RMSE, MAE, R², RMSPE | `Metrics` |

---

## 🚀 Hướng dẫn chạy

### Yêu cầu

- **R** ≥ 4.0
- **RStudio** (khuyến nghị)

### Cách chạy

```r
# 1. Mở RStudio, set working directory = thư mục rossman-sale-store/

# 2. Cài packages (chạy lần đầu)
source("R/00_setup.R")

# 3. Chạy toàn bộ pipeline
source("R/utils.R")
source("R/data_pipeline.R")
source("R/statistical_tests.R")
source("R/eda.R")
source("R/visualization.R")
source("R/modeling.R")
source("R/evaluation.R")
source("R/time_series.R")

# 4. Knit báo cáo
rmarkdown::render("rossman_analysis.Rmd")
```

Hoặc mở `rossman_analysis.Rmd` trong RStudio và nhấn **Knit**.

---

## 📊 Cấu trúc báo cáo

1. Tóm tắt (Abstract)
2. Giới thiệu (Introduction)
3. Dữ liệu (Data)
4. Trực quan hóa dữ liệu (Data Visualization)
5. Mô hình hóa dữ liệu (Data Modeling)
6. Thực nghiệm, Kết quả & Thảo luận
7. Kết luận (Conclusions)
8. Phụ lục (Appendices)
9. Đóng góp (Contributions)
10. Tham khảo (References)
11. Peer Assessment

---

## 📦 Packages sử dụng

| Nhóm | Packages |
|------|----------|
| Data | `dplyr`, `tidyr`, `lubridate`, `janitor`, `readr`, `here` |
| Visualization | `ggplot2`, `plotly`, `ggcorrplot`, `corrplot`, `scales`, `gridExtra` |
| Modeling | `caret`, `randomForest`, `ranger`, `xgboost`, `Metrics` |
| Reporting | `rmarkdown`, `knitr`, `kableExtra` |

---

## 📜 License

Dự án phục vụ mục đích học tập. Dữ liệu thuộc bản quyền Kaggle/Rossmann.
