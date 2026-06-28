# Tài liệu Tổng hợp Thay đổi - Rossmann Store Sales Analysis
Tài liệu này tổng hợp toàn bộ các thay đổi cấu trúc, mã nguồn và nội dung đã được thực hiện trên file `R/Rossmann_Store_Sales_Analysis.Rmd` nhằm phục vụ việc làm báo cáo hoặc tài liệu thuyết trình sau này.

---

## 📌 1. Các File Bị Tác Động
- **File chính**: `R/Rossmann_Store_Sales_Analysis.Rmd` (Đã cơ cấu lại hoàn toàn).
- **Các file phụ trợ (thư mục `R/`)**: `00_setup.R`, `eda.R`, `statistical_tests.R`, `utils.R`, `visualization.R`, `visualization.Rmd` (Đã được làm sạch tên thành viên).

---

## 🔍 2. Chi Tiết Thay Đổi Theo Từng Phần

### Phần 5: Exploratory Data Analysis (EDA)
- **Trước thay đổi**: Phần này chứa nhiều biểu đồ trực quan hóa dữ liệu (`ggplot2`) xen kẽ với tính toán số liệu và lưu hình ảnh ra file (`ggsave`).
- **Sau thay đổi**: 
  - Loại bỏ hoàn toàn mã vẽ biểu đồ và ggsave.
  - Loại bỏ các lời giải thích biểu đồ và ứng dụng thực tế của chúng.
  - **Giữ lại**: Chỉ giữ lại các bước tính toán thống kê mô tả, kiểm định phân phối chuẩn, phân tích tương quan và phân tích ngoại lai phục vụ lưu trữ file `output/tables/eda_results.rds`.
  - **Mục đích**: Chuyển giao toàn bộ vai trò trực quan hóa sang Phần 6.

### Phần 6: Data Visualization
- **Trước thay đổi**: Phần này chứa 10 biểu đồ chiến lược của Gia Hân (từ `Biểu đồ 1` đến `Biểu đồ 10`) xếp dưới các tiêu đề nhóm từ `## 4.1` đến `## 4.5`.
- **Sau thay đổi**:
  - Gộp tất cả các biểu đồ dưới một tiêu đề lớn duy nhất: `## 4.6 Biểu đồ nâng cao & Phân tích Chiến lược`.
  - Hợp nhất thành công 9 biểu đồ từ phần EDA cũ của bạn (Thanh Phúc) vào đây.
  - Đánh số thứ tự lại tuần tự từ `### 4.6.1` đến `### 4.6.19` (19 biểu đồ).
  - Bổ sung đầy đủ lời giải thích ý nghĩa kinh tế và ứng dụng thực tế của từng hình vẽ.

---

## 📊 3. Danh Sách 19 Biểu Đồ Sau Khi Hợp Nhất (Không Trùng Lặp)

### Nhóm 1: Biểu đồ từ EDA của bạn (Thanh Phúc)
| Số mục | Tên biểu đồ | Dòng | Tên Chunk | Mô tả & Ứng dụng thực tế |
| :--- | :--- | :--- | :--- | :--- |
| **4.6.1** | Phân phối Doanh số và Khách hàng | **1036** | `distribution-plots` | Phân phối lệch phải, phản ánh doanh thu duy trì ở trung vị thấp và tăng vọt vào ngày đặc biệt. |
| **4.6.2** | Kiểm định Phân phối chuẩn & Biến đổi Log-scale | **1078** | `normality-check` | Chứng minh doanh số không chuẩn. Phép biến đổi Log giúp giảm Skewness để chạy hồi quy tốt hơn. |
| **4.6.3** | Xu hướng Doanh số theo Thời gian | **1113** | `ts-trend` | Biến động doanh thu theo chu kỳ tháng/tuần, đỉnh điểm mua sắm dịp Giáng sinh tháng 12. |
| **4.6.4** | Biến động theo Tháng & Ngày trong tuần | **1138** | `seasonal-day-month`, `interactive-static-plot` | Heatmap & Line chart chỉ ra doanh thu cao đầu tuần và thứ Bảy, Chủ Nhật đóng cửa. |
| **4.6.5** | Tác động của Ngày lễ Quốc gia & Kỳ nghỉ học | **1186** | `holiday-impact` | Doanh thu ngày nghỉ học tăng cao. Ngày lễ quốc gia chỉ cao ở một số ít cửa hàng được mở cửa. |
| **4.6.6** | Phân phối doanh số theo Assortment | **1219** | `assortment-boxplot` | Cơ cấu sản phẩm Extended (mở rộng - c) mang lại doanh số trung bình cao nhất. |
| **4.6.7** | Doanh thu TB trên mỗi khách theo Store Type | **1238** | `violin-spc` | Cửa hàng Type B (Mall) đông khách nhưng giỏ hàng nhỏ. Type D (Flagship) ít khách nhưng giỏ hàng giá trị lớn. |
| **4.6.8** | Tác động Khuyến mãi đến Doanh số theo Store Type | **1258** | `bar-promo-type` | Khuyến mãi thúc đẩy doanh số ở tất cả các loại cửa hàng, mạnh nhất ở nhóm Mall stores (Type B). |
| **4.6.9** | Tỷ lệ Giao dịch Ngoại lai theo từng Cửa hàng | **1286** | `outlier-plot` | Các ngày có doanh số đột biến tập trung vào dịp Giáng sinh/khuyến mãi lớn. Giữ lại để huấn luyện mô hình ML. |

### Nhóm 2: Biểu đồ từ phân tích chiến lược của Gia Hân (Giữ nguyên gốc)
| Số mục | Tên biểu đồ | Dòng | Tên Chunk | Ý nghĩa chiến lược |
| :--- | :--- | :--- | :--- | :--- |
| **4.6.10** | Ma trận Tương quan | **1311** | `plot-1` | Tương quan mạnh nhất giữa số lượng Khách hàng và Doanh số. |
| **4.6.11** | Ảnh hưởng thời gian hoạt động của đối thủ cạnh tranh | **1365** | `plot-2` | Đo lường mức độ ảnh hưởng của đối thủ mới mở theo thời gian. |
| **4.6.12** | Tỷ lệ Outlier theo Tháng | **1433** | `plot-3` | Tỷ lệ ngoại lai tăng mạnh vào tháng 11, 12 do mùa mua sắm cao điểm. |
| **4.6.13** | Hiệu quả Khuyến mãi theo Ngày trong tuần | **1492** | `plot-4` | Biểu đồ Dumbbell chỉ ra khuyến mãi có tác dụng mạnh nhất vào đầu tuần. |
| **4.6.14** | Cộng hưởng giữa Khuyến mãi Định kỳ và Dài hạn | **1556** | `plot-5` | So sánh hiệu quả giữa Promo đơn lẻ và Promo kết hợp Promo2. |
| **4.6.15** | Phân tích Tăng trưởng Tháng-so-với-Tháng | **1636** | `plot-6` | Waterfall Chart thể hiện sự tăng/giảm doanh số qua từng tháng. |
| **4.6.16** | Phân tích Pareto — Đóng góp Doanh số | **1738** | `plot-7` | Xác định nhóm cửa hàng trọng điểm mang lại 80% doanh thu cho hệ thống. |
| **4.6.17** | Xếp hạng Hiệu suất 50 Cửa hàng | **1826** | `plot-8` | Lollipop Chart xếp hạng chi tiết doanh thu trung bình của từng cửa hàng. |
| **4.6.18** | Toàn cảnh Hiệu suất 50 Cửa hàng (Bong bóng) | **1879** | `plot-9` | Kết hợp doanh số, lượng khách và khoảng cách đối thủ trên biểu đồ 3 chiều. |
| **4.6.19** | Ma trận Chiến lược BCG — Phân loại Cửa hàng | **1953** | `plot-10` | Phân nhóm cửa hàng thành Stars, Cash Cows, Question Marks, Dogs để định hướng đầu tư. |

---

## 🚫 4. Các Biểu Đồ Trùng Lặp Đã Được Loại Bỏ
Nhằm tránh việc trùng lặp nội dung báo cáo, các biểu đồ sau đây của phần EDA đã bị xóa để ưu tiên giữ lại biểu đồ tương ứng của phần phân tích chiến lược:
1. **Ma trận tương quan**: Xóa biểu đồ tương quan của phần EDA, giữ lại `BieuDo1` (mục 4.6.10).
2. **Biểu đồ Dumbbell Khuyến mãi**: Xóa biểu đồ Dumbbell của phần EDA, giữ lại `BieuDo4` (mục 4.6.13).
3. **Biểu đồ Bong bóng / Pareto**: Xóa biểu đồ phân tích tương tự của phần EDA, giữ lại `BieuDo7` & `BieuDo9` (mục 4.6.16 & 4.6.18).

---

## 🧹 5. Làm Sạch Tên Thành Viên (Sanitization)
Đã xóa toàn bộ tên thành viên nhóm khỏi phần chú thích code và đầu ra văn bản trong toàn bộ thư mục `R/`:
- **Tên bị xóa**: *Thanh Phúc, Gia Hân, Đức Thắng, Quốc Anh, Thành Tài*.
- **Phạm vi làm sạch**: Tất cả comment, print/cat statement trong Rmd và các file script `.R`.

---

## 🛠 6. Trạng Thái Biên Dịch & Chạy Thử
- **Công cụ kiểm tra**: Sử dụng `knitr::purl()` để chuyển đổi file Rmd thành script R độc lập và tiến hành chạy từ đầu đến cuối.
- **Kết quả**: Tất cả các khối code Rmd (bao gồm cả nạp dữ liệu, tiền xử lý, trực quan hóa, và huấn luyện mô hình ML) đều chạy thông suốt không lỗi, đầu ra mô hình và báo cáo khớp chính xác (`Exit code: 0`).
