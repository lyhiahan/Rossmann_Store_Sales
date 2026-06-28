# Tài liệu Tổng hợp Thay đổi - Rossmann Store Sales Analysis
Tài liệu này tổng hợp toàn bộ các thay đổi cấu trúc, mã nguồn và nội dung đã được thực hiện trên file `R/Rossmann_Store_Sales_Analysis.Rmd` nhằm phục vụ việc làm báo cáo hoặc tài liệu thuyết trình sau này.

---

## 📌 1. Các File Bị Tác Động
- **File chính**: `R/Rossmann_Store_Sales_Analysis.Rmd` (Đã cơ cấu lại hoàn toàn).
- **Các file phụ trợ (thư mục `R/`)**: `00_setup.R`, `eda.R`, `statistical_tests.R`, `utils.R`, `visualization.R`, `visualization.Rmd` (Đã được làm sạch tên thành viên).

---

## 🔍 2. Chi Tiết Thay Đổi Theo Từng Phần

### Phần 3: Exploratory Data Analysis (EDA) (Hợp nhất vai trò của Thanh Phúc)
- **Thay đổi lớn**: Theo yêu cầu của giáo viên (phần EDA bao gồm cả xử lý dữ liệu và pipeline), vai trò xây dựng **Data Pipeline (Phần 3 cũ của Quốc Anh)** đã được chuyển giao và tích hợp chung với phần **Exploratory Data Analysis (Phần 5 cũ của Thanh Phúc)**.
- **Cấu trúc mới**:
  - `# 3. Exploratory Data Analysis (EDA)` (Đề mục lớn gộp chung).
  - `## 3.1 Quy trình xử lý dữ liệu (Data Pipeline)`: Chứa chunk `{r data-pipeline}` thực hiện đọc, làm sạch, lọc nhiễu, chia dữ liệu train/val và xuất file `df_clean.rds` không rò rỉ thông tin.
  - `## 3.2 Thống kê mô tả và phân tích phân phối sau xử lý (Exploratory Data Analysis)`: Chứa chunk `{r eda}` (đã tối giản chỉ tính toán số liệu và lưu file RDS, không trực quan hóa tại đây).

### Phần 4: Statistical Testing
- Giữ nguyên toàn bộ logic kiểm định ANOVA, t-test, Kruskal-Wallis, Wilcoxon, Spearman Correlation và Bootstrap CI. 
- Thứ tự chạy của phần này bây giờ diễn ra ngay sau bước Thống kê mô tả (EDA) của Phần 3, đảm bảo mạch logic phân tích tự nhiên.

### Phần 5: Data Visualization (Trước đây là Phần 6)
- **Đổi tên đề mục**: Đổi tên thành `# 5. Data Visualization`.
- **Hợp nhất và loại bỏ trùng lặp biểu đồ**:
  - Gộp tất cả các biểu đồ dưới một tiêu đề lớn duy nhất: `## 5.1 Biểu đồ nâng cao & Phân tích Chiến lược` (trước đây là 4.6).
  - Đánh số thứ tự lại tuần tự từ `### 5.1.1` đến `### 5.1.19` (19 biểu đồ).
  - Loại bỏ các biểu đồ trùng lặp của phần EDA cũ (như ma trận tương quan, biểu đồ dumbbell khuyến mãi, và biểu đồ bong bóng phân tích khoảng cách đối thủ). Giữ lại các phiên bản hoàn thiện tương ứng của Gia Hân.
  - Bổ sung đầy đủ lời giải thích ý nghĩa kinh tế và ứng dụng thực tế của từng hình vẽ.

### Các Phần Khác (Phần 6 đến 8)
Được đánh số thứ tự lại đề mục lớn cho phù hợp với cấu trúc mới:
- `# 6. Modeling & Hyperparameter Tuning` (Trước đây là Phần 7)
- `# 7. Time Series Analysis & Forecasting` (Trước đây là Phần 8)
- `# 8. Model Evaluation & Comparison` (Trước đây là Phần 9)

---

## 📊 3. Danh Sách 19 Biểu Đồ Sau Khi Hợp Nhất (Không Trùng Lặp)

### Nhóm 1: Biểu đồ từ EDA của bạn (Thanh Phúc)
| Số mục | Tên biểu đồ | Tên Chunk | Mô tả & Ứng dụng thực tế |
| :--- | :--- | :--- | :--- |
| **5.1.1** | Phân phối Doanh số và Khách hàng | `distribution-plots` | Phân phối lệch phải, phản ánh doanh thu duy trì ở trung vị thấp và tăng vọt vào ngày đặc biệt. |
| **5.1.2** | Kiểm định Phân phối chuẩn & Biến đổi Log-scale | `normality-check` | Chứng minh doanh số không chuẩn. Phép biến đổi Log giúp giảm Skewness để chạy hồi quy tốt hơn. |
| **5.1.3** | Xu hướng Doanh số theo Thời gian | `ts-trend` | Biến động doanh thu theo chu kỳ tháng/tuần, đỉnh điểm mua sắm dịp Giáng sinh tháng 12. |
| **5.1.4** | Biến động theo Tháng & Ngày trong tuần | `seasonal-day-month`, `interactive-static-plot` | Heatmap & Line chart chỉ ra doanh thu cao đầu tuần và thứ Bảy, Chủ Nhật đóng cửa. |
| **5.1.5** | Tác động của Ngày lễ Quốc gia & Kỳ nghỉ học | `holiday-impact` | Doanh thu ngày nghỉ học tăng cao. Ngày lễ quốc gia chỉ cao ở một số ít cửa hàng được mở cửa. |
| **5.1.6** | Phân phối doanh số theo Assortment | `assortment-boxplot` | Cơ cấu sản phẩm Extended (mở rộng - c) mang lại doanh số trung bình cao nhất. |
| **5.1.7** | Doanh thu TB trên mỗi khách theo Store Type | `violin-spc` | Cửa hàng Type B (Mall) đông khách nhưng giỏ hàng nhỏ. Type D (Flagship) ít khách nhưng giỏ hàng giá trị lớn. |
| **5.1.8** | Tác động Khuyến mãi đến Doanh số theo Store Type | `bar-promo-type` | Khuyến mãi thúc đẩy doanh số ở tất cả các loại cửa hàng, mạnh nhất ở nhóm Mall stores (Type B). |
| **5.1.9** | Tỷ lệ Giao dịch Ngoại lai theo từng Cửa hàng | `outlier-plot` | Các ngày có doanh số đột biến tập trung vào dịp Giáng sinh/khuyến mãi lớn. Giữ lại để huấn luyện mô hình ML. |

### Nhóm 2: Biểu đồ từ phân tích chiến lược của Gia Hân (Giữ nguyên gốc)
| Số mục | Tên biểu đồ | Tên Chunk | Ý nghĩa chiến lược |
| :--- | :--- | :--- | :--- |
| **5.1.10** | Ma trận Tương quan | `plot-1` | Tương quan mạnh nhất giữa số lượng Khách hàng và Doanh số. |
| **5.1.11** | Ảnh hưởng thời gian hoạt động của đối thủ cạnh tranh | `plot-2` | Đo lường mức độ ảnh hưởng của đối thủ mới mở theo thời gian. |
| **5.1.12** | Tỷ lệ Outlier theo Tháng | `plot-3` | Tỷ lệ ngoại lai tăng mạnh vào tháng 11, 12 do mùa mua sắm cao điểm. |
| **5.1.13** | Hiệu quả Khuyến mãi theo Ngày trong tuần | `plot-4` | Biểu đồ Dumbbell chỉ ra khuyến mãi có tác dụng mạnh nhất vào đầu tuần. |
| **5.1.14** | Cộng hưởng giữa Khuyến mãi Định kỳ và Dài hạn | `plot-5` | So sánh hiệu quả giữa Promo đơn lẻ và Promo kết hợp Promo2. |
| **5.1.15** | Phân tích Tăng trưởng Tháng-so-với-Tháng | `plot-6` | Waterfall Chart thể hiện sự tăng/giảm doanh số qua từng tháng. |
| **5.1.16** | Phân tích Pareto — Đóng góp Doanh số | `plot-7` | Xác định nhóm cửa hàng trọng điểm mang lại 80% doanh thu cho hệ thống. |
| **5.1.17** | Xếp hạng Hiệu suất 50 Cửa hàng | `plot-8` | Lollipop Chart xếp hạng chi tiết doanh thu trung bình của từng cửa hàng. |
| **5.1.18** | Toàn cảnh Hiệu suất 50 Cửa hàng (Bong bóng) | `plot-9` | Kết hợp doanh số, lượng khách và khoảng cách đối thủ trên biểu đồ 3 chiều. |
| **5.1.19** | Ma trận Chiến lược BCG — Phân loại Cửa hàng | `plot-10` | Phân nhóm cửa hàng thành Stars, Cash Cows, Question Marks, Dogs để định hướng đầu tư. |

---

## 🧹 4. Làm Sạch Tên Thành Viên (Sanitization)
Đã xóa toàn bộ tên thành viên nhóm khỏi phần chú thích code và đầu ra văn bản trong toàn bộ thư mục `R/` để đảm bảo bài nộp hoàn toàn khách quan.

---

## 🛠 5. Trạng Thái Biên Dịch & Chạy Thử
- **Công cụ kiểm tra**: Sử dụng `knitr::purl()` để chuyển đổi file Rmd thành script R độc lập và tiến hành chạy từ đầu đến cuối.
- **Kết quả**: Tất cả các khối code Rmd (bao gồm cả nạp dữ liệu, tiền xử lý, trực quan hóa, và huấn luyện mô hình ML) đều chạy thông suốt không lỗi, đầu ra mô hình và báo cáo khớp chính xác (`Exit code: 0`).
