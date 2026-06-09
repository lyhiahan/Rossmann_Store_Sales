# KỊCH BẢN THUYẾT TRÌNH CHI TIẾT — CƠ SỞ LÝ THUYẾT THỐNG KÊ
## Đồ án Phân tích Dữ liệu Rossmann Store Sales
**Thực hiện bởi:** Nhóm đồ án Rossmann (Quốc Anh, Thanh Phúc, Gia Hân, Đức Thắng, Thành Tài)
*Tài liệu hướng dẫn thuyết trình chi tiết, tích hợp số liệu thực tế, mã lệnh R và giải thích học thuật sâu sắc.*

---

### Slide 1 — Trang bìa: Cơ sở Lý thuyết Thống kê trong Phân tích Rossmann
* **Nội dung hiển thị trên slide:** Tiêu đề đồ án cuối kỳ, thông tin tập dữ liệu Rossmann (chuỗi dược phẩm lớn nhất Đức, 3.000+ cửa hàng; nguồn từ cuộc thi Kaggle; gồm file `train.csv` và `store.csv`), phạm vi phân tích (50 cửa hàng, 12 tháng từ 08/2014 đến 07/2015, ~14.000 bản ghi dữ liệu sạch).
* **Kịch bản chi tiết:**
  > "Xin kính chào thầy/cô và các bạn. Hôm nay, nhóm chúng em xin trình bày phần **Cơ sở Lý thuyết Thống kê** được áp dụng xuyên suốt trong đồ án phân tích và dự báo doanh số của chuỗi cửa hàng dược phẩm **Rossmann** tại Đức. 
  > 
  > Như thầy cô đã biết, Rossmann là một trong những chuỗi discount drugstore lớn nhất nước Đức với hơn 3.700 cửa hàng tại thời điểm 2015. Trong đồ án này, để đảm bảo tính đại diện nhưng vẫn tối ưu hóa được hiệu năng tính toán, nhóm đã chọn phạm vi nghiên cứu gồm **50 cửa hàng** (từ Store 1 đến Store 50) trải dài trong **12 tháng** (từ ngày 01/08/2014 đến 31/07/2015), thu về một tập dữ liệu sạch khoảng hơn **14.000 bản ghi**. 
  > 
  > Toàn bộ pipeline xử lý dữ liệu của nhóm được thiết kế theo tiêu chuẩn **Zero Data Leakage (Không rò rỉ dữ liệu)**, nghĩa là nhóm chia tập Train (70%) và Validation (30%) trước khi tính toán bất kỳ đại lượng thống kê nào. Hôm nay, chúng em sẽ làm rõ nền tảng toán học đứng sau toàn bộ các phân tích của nhóm, bao gồm ba mảng chính: Thống kê mô tả, Thống kê suy diễn và mô hình Hồi quy Logistic."
* **Lưu ý cho người thuyết trình:**
  * *Nhấn mạnh cụm từ "Zero Data Leakage" vì đây là điểm cộng lớn về mặt phương pháp luận kỹ thuật.*
  * *Chỉ tay vào góc thông tin phạm vi phân tích (50 cửa hàng, 12 tháng).*

---

### Slide 2 — Tổng quan: Hai trụ cột chính của Thống kê học
* **Nội dung hiển thị trên slide:** Trụ cột 1: Thống kê Mô tả (Đại lượng trung tâm: Mean/Median/Mode; Độ phân tán: Variance/SD/IQR; Hình dạng: Skewness/Kurtosis; Trực quan: Histogram/Boxplot/Density). Trụ cột 2: Thống kê Suy diễn (Ước lượng tham số & Khoảng tin cậy; Kiểm định giả thuyết; Mô hình hóa hồi quy tuyến tính & Logistic; Ý nghĩa thực nghiệm qua p-value).
* **Kịch bản chi tiết:**
  > "Để tiếp cận dữ liệu một cách khoa học, nhóm đã chia cấu trúc phân tích thành hai trụ cột cốt lõi của thống kê học. 
  > 
  > Trụ cột thứ nhất là **Thống kê Mô tả (Descriptive Statistics)**. Trụ cột này trả lời cho câu hỏi: *'Dữ liệu hiện có trông như thế nào?'*. Nó giúp nhóm tóm tắt dữ liệu thông qua các đại lượng đo lường xu hướng trung tâm như Mean, Median; đo lường độ phân tán như Variance, Standard Deviation, và trực quan hóa phân phối qua các biểu đồ như Histogram hay Boxplot.
  > 
  > Tuy nhiên, mô tả là chưa đủ. Nhóm cần đi đến trụ cột thứ hai: **Thống kê Suy diễn (Inferential Statistics)** để trả lời câu hỏi: *'Dữ liệu mẫu này cho phép chúng ta rút ra kết luận rộng hơn nào cho toàn bộ hệ thống?'*. Đây chính là nơi nhóm áp dụng các kiểm định giả thuyết (Hypothesis Testing), phân tích tương quan và xây dựng các mô hình dự báo hồi quy để suy luận đặc tính của hơn 3.000 cửa hàng Rossmann dựa trên mẫu 50 cửa hàng đang quan sát."
* **Lưu ý cho người thuyết trình:**
  * *Trình bày mạch lạc, tạo cấu trúc logic rõ ràng để người nghe dễ theo dõi các slide chi tiết phía sau.*

---

### Slide 3 — Trung bình — Mean
* **Nội dung hiển thị trên slide:** Công thức toán học $\bar{x} = \frac{1}{n}\sum_{i=1}^{n} x_i$. Sử dụng toàn bộ giá trị dữ liệu, nhạy cảm với outlier, phù hợp khi phân phối đối xứng. Ví dụ thực tế: Doanh số trung bình $6.840$ EUR/ngày từ 14.216 ngày mở cửa của 50 cửa hàng. Code R: `mean(df_clean$sales)`. Hộp cảnh báo về ảnh hưởng của ngày lễ doanh số đột biến ($15.000 - 20.000$ EUR).
* **Kịch bản chi tiết:**
  > "Hãy bắt đầu với đại lượng đo lường xu hướng trung tâm quen thuộc nhất: **Số trung bình (Mean)**. Về mặt toán học, trung bình mẫu $\bar{x}$ đơn giản là tổng của tất cả các giá trị quan sát chia cho kích thước mẫu $n$. Trong đồ án Rossmann, doanh số trung bình thực tế của 50 cửa hàng vào những ngày mở cửa là **6.840 EUR/ngày**. 
  > 
  > Ưu điểm của Mean là nó tận dụng triệt để mọi điểm dữ liệu để đưa ra một con số đại diện duy nhất. Tuy nhiên, nhược điểm chí mạng của nó là **cực kỳ nhạy cảm với các giá trị ngoại lai (outliers)**. Trong bối cảnh bán lẻ Đức, vào những dịp mua sắm lớn như trước Giáng sinh hay các ngày chạy khuyến mãi bùng nổ, doanh số một số cửa hàng có thể vọt lên $15.000$ đến $20.000$ EUR. Những ngày đột biến này sẽ kéo trị trung bình Mean lên cao hơn đáng kể so với mức doanh số của một ngày hoạt động bình thường điển hình. Do đó, nếu chỉ dùng Mean để lập kế hoạch tồn kho, chúng ta rất dễ bị đánh giá sai lệch."
* **Lưu ý cho người thuyết trình:**
  * *Chỉ vào công thức toán học và giải thích ngắn gọn.*
  * *Nhấn mạnh giá trị số liệu thực tế của đồ án: **6.840 EUR/ngày**.*

---

### Slide 4 — Trung vị — Median và Hiện tượng Phân phối Lệch
* **Nội dung hiển thị trên slide:** Công thức Median cho mẫu chẵn/lẻ. Đặc tính robust (bền vững), không bị méo bởi outlier. Biểu đồ histogram phân phối doanh số (Sales) lệch phải với Mean = 6.840 EUR và Median = 6.450 EUR. Chênh lệch 390 EUR. Code R: `median(df_clean$sales)`.
* **Kịch bản chi tiết:**
  > "Để khắc phục hạn chế của Mean, chúng em sử dụng **Trung vị (Median)**. Median là giá trị nằm ở chính giữa tập dữ liệu sau khi đã được sắp xếp theo thứ tự tăng dần. Nếu số quan sát là chẵn, ta lấy trung bình của hai giá trị ở giữa. 
  > 
  > Đặc tính tuyệt vời của Median là tính **bền vững (robust)** — nó hoàn toàn không bị ảnh hưởng bởi các giá trị cực biên ở đuôi phân phối. Trong đồ án, chúng em đã tận dụng đặc tính này để điền khuyết (imputation) cho biến khoảng cách đối thủ cạnh tranh (`CompetitionDistance`) bằng giá trị Median của tập huấn luyện nhằm tránh rò rỉ dữ liệu.
  > 
  > Nhìn vào biểu đồ phân phối doanh số trên slide, thầy cô có thể thấy rõ hiện tượng phân phối lệch phải (right-skewed) điển hình của dữ liệu bán lẻ. Giá trị **Median doanh số là 6.450 EUR**, thấp hơn **Mean là 6.840 EUR** khoảng **390 EUR**. Khoảng chênh lệch này cùng hệ số Skewness dương ($0,94$) xác nhận đuôi phân phối bị kéo dài về phía bên phải do các ngày doanh thu đột biến cao. Điều này đòi hỏi nhóm phải áp dụng biến đổi Log-transform hoặc các mô hình phi tuyến tính như Random Forest hay XGBoost để dự đoán hiệu quả hơn."
* **Lưu ý cho người thuyết trình:**
  * *Chỉ vào biểu đồ phân phối trên slide, chỉ rõ vị trí của Mean (nằm bên phải) và Median (nằm bên trái).*
  * *Giải thích trực quan tại sao chênh lệch Mean và Median lại là chỉ báo của sự lệch phân phối.*

---

### Slide 5 — Phương sai — Variance & Hiệu chỉnh Bessel
* **Nội dung hiển thị trên slide:** Công thức phương sai tổng thể $\sigma^2$ (chia cho $N$) và phương sai mẫu $s^2$ (chia cho $n-1$). Phương sai doanh số mẫu trong đồ án: $6.925.176$ $\text{EUR}^2$. Giải thích Hiệu chỉnh Bessel giúp ước lượng không bị chệch. Hạn chế về đơn vị bình phương ($\text{EUR}^2$). Code R: `var(df_clean$sales)`.
* **Kịch bản chi tiết:**
  > "Bên cạnh xu hướng trung tâm, một khía cạnh cực kỳ quan trọng là độ phân tán của dữ liệu. Đại lượng toán học nền tảng đo lường điều này là **Phương sai (Variance)**. 
  > 
  > Xin thầy cô lưu ý sự khác biệt giữa hai công thức trên slide. Khi tính phương sai cho toàn bộ tổng thể, ta chia cho $N$. Nhưng khi tính phương sai mẫu từ dữ liệu thực nghiệm, ta phải chia cho $n-1$ thay vì $n$. Trong thống kê, đây được gọi là **Hiệu chỉnh Bessel (Bessel's Correction)**. Việc chia cho $n-1$ giúp bù đắp xu hướng đánh giá thấp độ phân tán của mẫu nhỏ, đảm bảo rằng phương sai mẫu $s^2$ là một ước lượng không chệch (unbiased estimator) của phương sai tổng thể $\sigma^2$.
  > 
  > Phương sai doanh số mẫu tính được trong đồ án của nhóm là một con số khổng lồ: **6.925.176 $\text{EUR}^2$**. Dù con số này là nền tảng cho nhiều thuật toán tối ưu hóa, nó lại có một nhược điểm lớn trong thực tế: đơn vị đo lường lúc này là **EUR bình phương ($\text{EUR}^2$)** — một đơn vị hoàn toàn vô nghĩa và cực kỳ khó giải thích cho các nhà quản lý doanh nghiệp."
* **Lưu ý cho người thuyết trình:**
  * *Nhấn mạnh vai trò của mẫu số $n-1$ (Hiệu chỉnh Bessel) để chứng minh sự hiểu biết sâu sắc về lý thuyết thống kê.*

---

### Slide 6 — Độ lệch chuẩn — Standard Deviation (SD)
* **Nội dung hiển thị trên slide:** Công thức SD ($s = \sqrt{s^2}$). Chỉ số thực tế của đồ án: SD = 2.632 EUR, Hệ số biến thiên (CV) = 38.47%. Minh họa quy tắc phân phối chuẩn 68-95-99.7% với các khoảng doanh số tương ứng: $\pm 1\sigma$ (4.208 – 9.472 EUR), $\pm 2\sigma$ (1.576 – 12.104 EUR). Code R: `sd(df_clean$sales)`.
* **Kịch bản chi tiết:**
  > "Để đưa độ đo phân tán về một đơn vị dễ hiểu, chúng ta chỉ cần lấy căn bậc hai của phương sai, thu được **Độ lệch chuẩn (Standard Deviation - SD)**. 
  > 
  > Độ lệch chuẩn doanh số trong đồ án của chúng em là **2.632 EUR**. Vì cùng đơn vị với dữ liệu gốc, chúng em có thể phát biểu một cách rất trực quan rằng: *'Doanh số bán hàng hàng ngày dao động trung bình khoảng $\pm 2.632$ EUR xung quanh mức trung bình 6.840 EUR'*. Nhóm cũng tính toán **Hệ số biến thiên (Coefficient of Variation - CV)** bằng tỷ số giữa SD và Mean, đạt **38,47%**. Con số CV cao này phản ánh mức độ biến động doanh số rất mạnh giữa các ngày trong tuần và các mùa trong năm.
  > 
  > Trên slide là hình vẽ minh họa quy luật thực nghiệm 68-95-99.7. Nếu doanh số tuân theo phân phối chuẩn hoàn hảo, khoảng 68% số ngày bán hàng sẽ nằm trong khoảng $\pm 1$ độ lệch chuẩn từ Mean, tương đương từ $4.208$ đến $9.472$ EUR. Khoảng 95% số ngày sẽ nằm trong khoảng $\pm 2$ độ lệch chuẩn, tức là từ $1.576$ đến $12.104$ EUR. Việc hiểu rõ các khoảng dao động này giúp Rossmann thiết lập các mức lưu kho an toàn tối ưu."
* **Lưu ý cho người thuyết trình:**
  * *Chỉ vào sơ đồ đường cong phân phối chuẩn trên slide khi giải thích quy tắc 68-95-99.7.*
  * *Giải thích ý nghĩa thực tế của CV = 38.47% đối với việc quản trị rủi ro.*

---

### Slide 7 — So sánh tổng hợp các đại lượng mô tả
* **Nội dung hiển thị trên slide:** Bảng so sánh 4 đại lượng: Mean, Median, Variance, SD về công thức, ưu điểm và hạn chế. Hộp thoại "Nguyên tắc vàng trong báo cáo": Luôn trình bày đồng thời cả Mean, Median và SD để có bức tranh toàn cảnh phân phối.
* **Kịch bản chi tiết:**
  > "Để tổng kết phần thống kê mô tả, nhóm đã thiết lập bảng so sánh trực quan này. Mỗi đại lượng đều có sứ mệnh riêng: Mean phản ánh kỳ vọng toán học tổng thể; Median bảo vệ chúng ta trước các điểm dữ liệu nhiễu cực đoan; Variance cung cấp nền tảng tính toán học thuật; và SD mang lại ý nghĩa thực tế để giao tiếp với doanh nghiệp.
  > 
  > **Bài học thực tiễn lớn nhất** mà nhóm rút ra là: *Trong bất kỳ báo cáo phân tích kinh doanh nào, không bao giờ được phép chỉ sử dụng một đại lượng duy nhất*. Sự chênh lệch lớn giữa Mean và Median là tín hiệu cảnh báo sớm giúp nhà phân tích biết rằng dữ liệu đang bị lệch chuẩn nghiêm trọng, từ đó định hướng cho việc làm sạch dữ liệu và lựa chọn mô hình học máy phù hợp."
* **Lưu ý cho người thuyết trình:**
  * *Đọc lướt nhanh qua các dòng của bảng để giữ nhịp thuyết trình nhanh, tập trung nhấn mạnh phần "Nguyên tắc vàng".*

---

### Slide 8 — Chuyển đổi tư duy: Từ mẫu → Tổng thể
* **Nội dung hiển thị trên slide:** Câu hỏi cốt lõi: Kết quả quan sát mẫu là hiệu ứng thực tế hay chỉ do dao động ngẫu nhiên? Bản so sánh định nghĩa và giá trị cụ thể trong đồ án của: Tổng thể (3.000+ cửa hàng), Mẫu (50 cửa hàng), Tham số (doanh số trung bình thực tế toàn hệ thống $\mu$), Thống kê (Mean mẫu = 6.840 EUR).
* **Kịch bản chi tiết:**
  > "Bây giờ, chúng ta sẽ thực hiện một **bước chuyển tư duy quan trọng**: từ mô tả mẫu sang suy luận tổng thể. 
  > 
  > Trong thực tế kinh doanh, chúng ta hầu như không bao giờ có được dữ liệu tức thời của toàn bộ tổng thể mọi lúc mọi nơi. Ở đồ án này, nhóm chỉ quan sát dữ liệu của **50 cửa hàng** trong **12 tháng**. Nhưng câu hỏi mà ban giám đốc Rossmann quan tâm là: *'Chương trình khuyến mãi có thực sự hiệu quả cho toàn bộ hơn 3.000 cửa hàng trên toàn quốc hay không?'*.
  > 
  > Nếu chỉ nhìn vào con số trung bình của 50 cửa hàng tăng lên, làm sao chúng ta chắc chắn đó là hiệu ứng thực tế chứ không phải do sai số chọn mẫu ngẫu nhiên? Để trả lời câu hỏi này một cách khoa học, thống kê suy diễn cung cấp công cụ **Kiểm định giả thuyết (Hypothesis Testing)**. Chúng ta sẽ dùng các đặc trưng tính toán được trên mẫu — gọi là các **Thống kê (Statistics)** như $\bar{x} = 6.840$ EUR để suy luận về các **Tham số (Parameters)** chưa biết của tổng thể như $\mu$ với một mức độ tin cậy toán học xác định."
* **Lưu ý cho người thuyết trình:**
  * *Nói với giọng truyền cảm, nhấn mạnh tính thực tế của bài toán doanh nghiệp để thu hút người nghe.*

---

### Slide 9 — Quy trình kiểm định giả thuyết thống kê (5 Bước)
* **Nội dung hiển thị trên slide:** Sơ đồ 5 bước kiểm định tuần tự: 1. Thiết lập giả thuyết ($H_0$ vs $H_1$). 2. Chọn mức ý nghĩa $\alpha$ (thường là 0.05). 3. Tính thống kê kiểm định. 4. Tính toán p-value. 5. Ra quyết định thống kê ($p < \alpha \Rightarrow$ Bác bỏ $H_0$).
* **Kịch bản chi tiết:**
  > "Để thực hiện một kiểm định giả thuyết chặt chẽ, nhóm tuân thủ nghiêm ngặt quy trình 5 bước kinh điển của thống kê học.
  > 
  > *   **Bước 1**: Nhóm thiết lập giả thuyết không $H_0$ — đại diện cho trạng thái 'không có sự khác biệt' hoặc 'không có hiệu ứng', và giả thuyết đối $H_1$ — khẳng định 'có sự khác biệt'.
  > *   **Bước 2**: Chọn mức ý nghĩa $\alpha$, thường là **0.05**. Đây là ngưỡng chấp nhận rủi ro tối đa cho sai lầm loại I — tức là bác bỏ nhầm giả thuyết $H_0$ trong khi nó thực sự đúng.
  > *   **Bước 3**: Tính toán thống kê kiểm định từ dữ liệu mẫu (như trị số $t$ cho so sánh trung bình, hay $F$ cho ANOVA).
  > *   **Bước 4**: Xác định giá trị **p-value**. Về mặt học thuật, p-value là xác suất tìm thấy một kết quả cực đoan bằng hoặc hơn kết quả thực tế, giả định rằng giả thuyết không $H_0$ hoàn toàn đúng.
  > *   **Bước 5**: Ra quyết định. Nếu p-value nhỏ hơn $\alpha$ (tức là $< 0.05$), ta có đủ bằng chứng bác bỏ $H_0$ để ủng hộ $H_1$. Nếu p-value $\ge 0.05$, ta kết luận chưa đủ cơ sở để bác bỏ $H_0$. Em xin nhấn mạnh: *Chưa bác bỏ H0 không có nghĩa là chúng ta đã chứng minh H0 đúng*, mà chỉ là dữ liệu mẫu hiện tại chưa đủ mạnh để bác bỏ nó."
* **Lưu ý cho người thuyết trình:**
  * *Giải thích kỹ định nghĩa của p-value và lưu ý ở Bước 5 vì đây là lỗi hiểu sai phổ biến trong nghiên cứu.*

---

### Slide 10 — Các kiểm định thống kê được sử dụng trong đồ án
* **Nội dung hiển thị trên slide:** Bảng so sánh các kiểm định được dùng trong đồ án: Doanh số theo Store Type (ANOVA vs Kruskal-Wallis, cả hai p < 2e-16); Hiệu quả Khuyến mãi (Welch t-test vs Wilcoxon, cả hai p < 2e-16); Doanh số vs Cạnh tranh (Pearson r=0.0002 vs Spearman rho=0.049). Biểu đồ so sánh doanh số ngày có khuyến mãi ($8.091$ EUR) vs không khuyến mãi ($5.739$ EUR). Thanh đo kích thước hiệu ứng (Effect Size) Cohen's d = 0.994 (Rất lớn).
* **Kịch bản chi tiết:**
  > "Trong đồ án này, nhóm trưởng Quốc Anh đã thiết lập một phương pháp kiểm định rất chặt chẽ gọi là **Kiểm định đôi (Dual Testing)**. Vì doanh số bán hàng không tuân theo phân phối chuẩn, nhóm chạy song song cả kiểm định tham số truyền thống lẫn kiểm định phi tham số đối chứng để đối chiếu chéo kết quả.
  > 
  > Đầu tiên, đối với giả thuyết về sự khác biệt doanh số giữa các loại cửa hàng (`StoreType`), cả kiểm định ANOVA và Kruskal-Wallis đều cho **p-value cực nhỏ ($< 2\times 10^{-16}$)**, khẳng định chắc chắn doanh thu trung bình giữa các loại cửa hàng là khác nhau đáng kể.
  > 
  > Thứ hai, về hiệu quả khuyến mãi (`Promo`), cả Welch t-test và Wilcoxon cũng cho **p-value $< 2\times 10^{-16}$**. Nhìn vào biểu đồ cột, doanh số trung bình ngày có khuyến mãi là **8.091 EUR/ngày**, cao hơn ngày thường không khuyến mãi là **5.739 EUR/ngày** (tăng tới **41,0%**). Để đo lường ý nghĩa thực tiễn, nhóm tính toán kích thước hiệu ứng **Cohen's d (Welch-corrected) đạt 0.994** — cho thấy tác động của khuyến mãi là cực kỳ lớn và thực chất, chứ không chỉ mang ý nghĩa lý thuyết.
  > 
  > Cuối cùng, về mối tương quan giữa doanh số và khoảng cách đối thủ (`CompetitionDistance`), hệ số tương quan Spearman đạt trị số cực kỳ yếu ($\rho \approx -0,016$). Mặc dù kiểm định cho p-value có ý nghĩa thống kê ($0.049 < 0.05$) do kích thước mẫu rất lớn, nhưng về mặt thực tiễn, khoảng cách đối thủ gần như không ảnh hưởng đến doanh thu của cửa hàng trong một thị trường đã bão hòa như ở Đức."
* **Lưu ý cho người thuyết trình:**
  * *Chỉ vào biểu đồ cột để minh họa cho sự chênh lệch doanh thu khi có khuyến mãi.*
  * *Giải thích sự khác biệt quan trọng giữa "Ý nghĩa thống kê" (statistical significance) và "Ý nghĩa thực tiễn" (practical significance) thông qua biến CompetitionDistance.*

---

### Slide 11 — Nền tảng Hồi quy tuyến tính đa biến (Linear Regression)
* **Nội dung hiển thị trên slide:** Phương trình hồi quy đa biến: $Y = \beta_0 + \beta_1X_1 + \beta_2X_2 + \cdots + \beta_pX_p + \varepsilon$. Giải thích phương pháp OLS (tối thiểu hóa RSS). 4 giả định kinh điển (Tuyến tính, Nhiễu chuẩn, Phương sai đồng nhất, Không tự tương quan). Kết quả mô hình: R² Validation = 86.78%, RMSE = 960.5 EUR. Hệ số tiêu biểu: Customers (+11.32 EUR), Promo (+976.5 EUR), StoreType C (+350.2 EUR), DayOfWeek 7 (-2.215 EUR). Code R: `lm(...)`.
* **Kịch bản chi tiết:**
  > "Đi xa hơn các kiểm định đơn lẻ, nhóm xây dựng mô hình hồi quy để lượng hóa đồng thời tác động của nhiều yếu tố. Mô hình nền tảng đầu tiên là **Hồi quy tuyến tính đa biến (Linear Regression)**.
  > 
  > Mô hình sử dụng phương pháp **Bình phương nhỏ nhất (OLS)** để tìm kiếm bộ hệ số $\beta$ sao cho tổng bình phương các sai số RSS là nhỏ nhất. Tuy nhiên, để các ước lượng OLS có độ tin cậy tốt nhất (BLUE), dữ liệu phải thỏa mãn 4 giả định kinh điển: tính tuyến tính, phân phối chuẩn của sai số, phương sai sai số đồng nhất và không có tự tương quan. Trên thực tế, dữ liệu Rossmann vi phạm giả định phương sai đồng nhất do biến động doanh số theo mùa, đòi hỏi chúng ta phải hết sức cẩn thận khi diễn giải khoảng tin cậy.
  > 
  > Kết quả thực nghiệm của mô hình đạt **R² = 86,78%** trên tập Validation — nghĩa là mô hình giải thích được gần 87% sự biến động của doanh số với sai số trung bình **RMSE là 960,5 EUR**. Điểm đắt giá của mô hình này nằm ở tính **diễn giải trực tiếp (interpretability)** thông qua các hệ số hồi quy:
  > *   Mỗi một khách hàng tăng thêm giúp doanh thu tăng **11,32 EUR**.
  > *   Việc chạy khuyến mãi (`Promo`) giúp tăng trung bình **976,5 EUR/ngày**.
  > *   Đặc biệt, ngày Chủ nhật (`DayOfWeek 7`) làm doanh số sụt giảm **2.215 EUR** do luật đóng cửa bắt buộc của Đức."
* **Lưu ý cho người thuyết trình:**
  * *Chỉ vào các hệ số cụ thể trên bảng hệ số tiêu biểu và liên hệ chúng trực tiếp với hành vi người tiêu dùng ở Đức.*

---

### Slide 12 — Giới hạn của Hồi quy tuyến tính với biến nhị phân
* **Nội dung hiển thị trên slide:** Tại sao OLS thất bại khi Y thuộc {0, 1}? Lỗi dự báo vô nghĩa (< 0 hoặc > 1), vi phạm giả định phương sai sai số (phụ thuộc vào X), mối quan hệ thực tế là phi tuyến (hình chữ S). Các ứng dụng phân loại nhị phân trong đồ án Rossmann: Doanh số vượt Median (Y ∈ {0,1}), Ngày có doanh số Outlier đột biến (Y ∈ {0,1}). Giới thiệu giải pháp Hồi quy Logistic dùng phép biến đổi Logit.
* **Kịch bản chi tiết:**
  > "Mặc dù hồi quy tuyến tính rất mạnh mẽ, nó hoàn toàn bất lực khi biến mục tiêu $Y$ là biến nhị phân chỉ nhận giá trị 0 hoặc 1. Trong đồ án, nhóm gặp bài toán này khi cần phân loại xem: *'Cửa hàng có đạt doanh số vượt mức median hay không?'* hoặc *'Ngày hôm đó doanh số có phải là outlier đột biến không?'*.
  > 
  > Nếu chúng ta cố tình sử dụng mô hình tuyến tính OLS (thường gọi là Mô hình xác suất tuyến tính - LPM) cho biến nhị phân, chúng ta sẽ đối mặt với ba thất bại nghiêm trọng:
  > 1.  **Dự báo vô nghĩa**: Mô hình có thể đưa ra xác suất dự báo nhỏ hơn 0 hoặc lớn hơn 1, điều này hoàn toàn bất khả thi về mặt toán học.
  > 2.  **Vi phạm giả định**: Phương sai sai số không bao giờ đồng nhất vì nó phụ thuộc trực tiếp vào giá trị của biến độc lập $X$.
  > 3.  **Sai lệch dạng hàm**: Mối quan hệ thực tế giữa các yếu tố với xác suất xảy ra biến cố thường là phi tuyến tính dạng hình chữ S chứ không phải một đường thẳng kéo dài vô tận.
  > 
  > Để giải quyết triệt để các giới hạn này, nhóm đã áp dụng mô hình **Hồi quy Logistic (Logistic Regression)** bằng cách sử dụng hàm liên kết **Logit** để ánh xạ dải xác suất giới hạn $(0, 1)$ sang dải số thực vô hạn $(-\infty, +\infty)$."
* **Lưu ý cho người thuyết trình:**
  * *Sử dụng giọng điệu mang tính lật mở vấn đề khi trình bày về sự thất bại của OLS.*

---

### Slide 13 — Mô hình toán học: Hàm Sigmoid & Hàm Logit
* **Nội dung hiển thị trên slide:** Công thức toán học hàm Sigmoid $P(Y=1|X) = \frac{1}{1 + e^{-z}}$ với $z$ là tổ hợp tuyến tính. Công thức hàm Logit $\text{logit}(p) = \ln(\frac{p}{1-p}) = z$. Biểu đồ đường cong Sigmoid hình chữ S trực quan. Các điểm neo: $z \to -\infty \Rightarrow P \to 0$; $z = 0 \Rightarrow P = 0.5$; $z \to +\infty \Rightarrow P \to 1$.
* **Kịch bản chi tiết:**
  > "Về mặt toán học, Hồi quy Logistic hoạt động dựa trên sự chuyển đổi nhịp nhàng giữa hai hàm số: **Sigmoid** và **Logit**.
  > 
  > Hàm **Sigmoid** (ở phía trên bên trái slide) đóng vai trò bộ lọc ánh xạ. Nó nhận đầu vào là một giá trị tuyến tính $z$ bất kỳ từ âm vô cùng đến dương vô cùng, rồi nén nó lại thành một giá trị nằm trong khoảng từ 0 đến 1, đại diện cho xác suất xảy ra sự kiện $P(Y=1)$.
  > 
  > Nhìn vào biểu đồ đường cong Sigmoid hình chữ S trên slide:
  > *   Khi điểm số tuyến tính $z$ tiến về âm vô cùng, xác suất xảy ra sự kiện tiến dần về **0**.
  > *   Khi $z$ bằng đúng **0**, xác suất đạt chính xác **0.5** — đây là điểm trung lập.
  > *   Khi $z$ tiến về dương vô cùng, xác suất tiệm cận về **1**.
  > 
  > Ở chiều ngược lại, hàm **Logit** lấy logarithm tự nhiên của tỷ lệ cược Odds, biến đổi xác suất phi tuyến $p$ trở lại thành giá trị tuyến tính $z$. Nhờ hàm liên kết Logit này, mối quan hệ giữa các biến độc lập $X$ và log-odds của biến mục tiêu trở thành mối quan hệ tuyến tính, cho phép chúng ta ước lượng mô hình một cách khoa học."
* **Lưu ý cho người thuyết trình:**
  * *Chỉ vào biểu đồ đường cong Sigmoid khi giải thích các điểm giới hạn (0, 0.5, 1).*

---

### Slide 14 — Phương pháp ước lượng MLE & Diễn giải Odds Ratio
* **Nội dung hiển thị trên slide:** Công thức toán học ước lượng hợp lý cực đại (MLE) cho $\hat{\beta}$. Liệt kê các chỉ số đánh giá mô hình phân loại (Confusion Matrix, Accuracy, Precision, Recall, F1, AUC-ROC). Định nghĩa và bảng diễn giải hệ số qua Odds Ratio ($e^{\beta_j}$). Ví dụ thực tế: $\beta_{promo} = 0.693 \Rightarrow OR = e^{0.693} \approx 2.0$ (Khuyến mãi làm tăng gấp đôi tỷ lệ cược đạt doanh số cao). Code R: `glm(..., family = binomial)`.
* **Kịch bản chi tiết:**
  > "Do tính phi tuyến tính của hàm Sigmoid, chúng ta không thể dùng phương pháp OLS để giải trực tiếp hệ số $\beta$. Thay vào đó, Hồi quy Logistic sử dụng phương pháp **Ước lượng Hợp lý Cực đại (Maximum Likelihood Estimation - MLE)**. MLE hoạt động theo nguyên lý lặp để tìm ra bộ hệ số $\beta$ sao cho xác suất xảy ra các điểm dữ liệu thực tế quan sát được là lớn nhất.
  > 
  > Để diễn giải ý nghĩa của các hệ số $\beta$ thu được, chúng ta sử dụng **Tỷ lệ cược (Odds Ratio - OR)** bằng cách lấy cơ số tự nhiên $e$ lũy thừa hệ số $\beta$.
  > *   Nếu hệ số $\beta$ dương, dẫn đến $OR > 1$: biến độc lập làm tăng khả năng xảy ra sự kiện.
  > *   Nếu $\beta = 0$, $OR = 1$: biến độc lập hoàn toàn không có ảnh hưởng.
  > *   Nếu $\beta$ âm, $OR < 1$: biến độc lập làm giảm khả năng xảy ra sự kiện.
  > 
  > Hãy xem một ví dụ thực tế cực kỳ sống động trong mô hình dự báo doanh số cao của nhóm: Hệ số $\beta$ của biến khuyến mãi `Promo` là **0.693**. Khi tính toán $OR = e^{0.693} \approx 2.0$. Con số này có ý nghĩa thực tiễn là: *'Khi cửa hàng chạy chương trình khuyến mãi, tỷ lệ cược (odds) để đạt mức doanh số cao vượt median sẽ tăng gấp 2 lần so với ngày thường không chạy khuyến mãi'*. Đây là thông tin cực kỳ đắt giá cho bộ phận marketing để hoạch định ngân sách promotion."
* **Lưu ý cho người thuyết trình:**
  * *Giải thích rõ sự khác biệt giữa "tỷ lệ cược" (odds) và "xác suất" (probability) để thể hiện sự chính xác về mặt học thuật.*

---

### Slide 15 — So sánh tổng hợp và tổng kết cơ sở lý thuyết
* **Nội dung hiển thị trên slide:** Bảng so sánh Hồi quy Tuyến tính vs Hồi quy Logistic (Biến Y, Đầu ra, Hàm liên kết, Phương pháp ước lượng, Hàm mất mát, Diễn giải hệ số). Sơ đồ cột so sánh hiệu suất các mô hình trong đồ án ($R^2$): XGBoost ($97.79\%$), Random Forest ($94.24\%$), Linear Regression ($86.78\%$), ARIMA ($31.2\%$), ETS ($28.7\%$). Kết luận chung.
* **Kịch bản chi tiết:**
  > "Để kết thúc buổi thuyết trình, nhóm xin tổng hợp toàn bộ bức tranh lý thuyết và thực nghiệm của đồ án.
  > 
  > Như thầy cô thấy trên bảng so sánh, cả Hồi quy tuyến tính và Hồi quy Logistic thực chất đều thuộc **Họ mô hình tuyến tính tổng quát (Generalized Linear Models - GLM)**. Chúng có cấu trúc tương đồng nhưng khác nhau ở hàm liên kết (Identity vs Logit) và phương pháp ước lượng (OLS vs MLE) để phù hợp với đặc tính của biến mục tiêu $Y$.
  > 
  > Nhìn vào biểu đồ hiệu suất mô hình thực tế của nhóm:
  > *   **XGBoost** đạt kết quả vượt trội nhất với **R² đạt 97,79%**, theo sát là **Random Forest với 94,24%**. Điều này hoàn toàn trùng khớp với lý thuyết thống kê mô tả ban đầu: dữ liệu Rossmann có phân phối lệch phải mạnh và chứa nhiều tương tác phi tuyến tính, nên các thuật toán dạng cây (tree-based) xử lý hiệu quả hơn hẳn so với **Hồi quy tuyến tính baseline (86,78%)**.
  > *   Ngược lại, các mô hình chuỗi thời gian thuần túy như **ARIMA (31.2%)** và **ETS (28.7%)** đạt hiệu suất rất thấp. Lý do kinh điển là chúng chỉ dự báo dựa trên lịch sử trễ của chính doanh số mà không thể tích hợp trực tiếp các biến ngoại sinh quan trọng như lịch khuyến mãi hay ngày lễ.
  > 
  > Sự kết hợp hài hòa giữa thống kê học cổ điển và học máy hiện đại đã giúp nhóm xây dựng được một giải pháp dự báo doanh số Rossmann có độ chính xác cực kỳ cao và có ý nghĩa thực tiễn sâu sắc. 
  > 
  > Nhóm chúng em xin chân thành cảm ơn thầy/cô và các bạn đã chú ý lắng nghe!"
* **Lưu ý cho người thuyết trình:**
  * *Cúi đầu chào và hướng tầm mắt về phía hội đồng để nhận câu hỏi phản biện.*
  * *Nhấn mạnh sự liên kết giữa lý thuyết thống kê ban đầu (lệch chuẩn, phi tuyến) với việc giải thích tại sao XGBoost lại có hiệu suất cao vượt trội.*

---
