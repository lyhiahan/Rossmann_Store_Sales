## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  echo = TRUE,
  message = FALSE,
  warning = FALSE,
  fig.align = "center",
  fig.width = 10,
  fig.height = 5
)


## ----load-env-----------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(tidyverse)
library(ggcorrplot)
library(plotly)
library(scales)
library(gridExtra)
library(lubridate)
library(ggridges)
library(here)

DuLieu <- readRDS(here("data", "processed", "df_clean.rds"))

GiaoDienRossmann <- theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11.5, hjust = 0.5, color = "#263238", face = "italic"),
    legend.position = "right",
    panel.grid.minor = element_blank()
  )

MauCuaHang <- c("a" = "#2196F3", "b" = "#E53935", "c" = "#4CAF50", "d" = "#FF9800")
MauKhuyenMai <- c("0" = "#90A4AE", "1" = "#E53935")


## ----plot-1-------------------------------------------------------------------
DoanhThuTBTheoThang <- DuLieu %>%
  mutate(Thang = floor_date(date, "month")) %>%
  group_by(Thang) %>%
  summarise(DoanhThuTrungBinh = mean(sales), .groups = "drop")

BieuDo1 <- ggplot(DoanhThuTBTheoThang, aes(x = Thang, y = DoanhThuTrungBinh)) +
  geom_line(color = "#2196F3", linewidth = 1) +
  geom_point(color = "#E53935", size = 3) +
  geom_text(aes(label = comma(round(DoanhThuTrungBinh))), vjust = -1, size = 3.5, fontface = "bold") +
  labs(
    title    = "Xu hướng doanh số trung bình theo tháng",
    subtitle = "Store 1–50 | 08/2014 – 07/2015",
    x = "Tháng", y = "Doanh số trung bình (EUR)"
  ) +
  scale_x_date(date_labels = "%m/%Y", date_breaks = "1 month") +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0.1, 0.15))) +
  GiaoDienRossmann

print(BieuDo1)
ggsave(here("output", "figures", "p1_monthly_trend.png"), BieuDo1,
       width = 10, height = 5, dpi = 150)


## ----plot-2-------------------------------------------------------------------
DuLieuNgayLe <- DuLieu %>%
  mutate(LoaiNgay = case_when(
      state_holiday != "none" ~ "Ngày lễ quốc gia (State Holiday)",
      school_holiday == "1"   ~ "Kỳ nghỉ học (School Holiday)",
      TRUE                    ~ "Ngày thường (Normal Day)")
  )

BieuDo2_gg <- ggplot(DuLieuNgayLe, aes(x = LoaiNgay, y = sales, fill = LoaiNgay,
    text = paste0("<b>Loại ngày:</b> ", LoaiNgay, "<br>",
                  "<b>Doanh số:</b> ", comma(round(sales)), " EUR")
  )) +
  geom_boxplot(outlier.colour = "#e74c3c", outlier.shape = 1, outlier.alpha = 0.1, lwd = 0.5) +
  scale_fill_manual(values = c(
    "Ngày lễ quốc gia (State Holiday)" = "#E53935",
    "Kỳ nghỉ học (School Holiday)" = "#FF9800",
    "Ngày thường (Normal Day)" = "#90A4AE"
  )) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Tác động của Ngày lễ và Kỳ nghỉ học đến Doanh số",
    x = "Loại hình ngày", 
    y = "Doanh số bán hàng ngày (EUR)"
  ) +
  GiaoDienRossmann +
  theme(legend.position = "none")

BieuDo2 <- ggplotly(BieuDo2_gg, tooltip = "text") %>% 
  layout(showlegend = FALSE)

BieuDo2


## ----plot-3-------------------------------------------------------------------
DuLieuSo <- DuLieu %>%
  select(sales, customers, competition_distance, sales_per_customer,
         month, week_of_year, is_weekend) %>%
  mutate(across(everything(), as.numeric)) %>%
  rename(
    "Doanh số" = sales,
    "Khách hàng" = customers,
    "Khoảng cách đối thủ" = competition_distance,
    "Doanh số/Khách" = sales_per_customer,
    "Tháng" = month,
    "Tuần trong năm" = week_of_year,
    "Cuối tuần" = is_weekend
  )

MaTranTuongQuan <- cor(DuLieuSo, use = "complete.obs")

BieuDo3 <- ggcorrplot(MaTranTuongQuan,
                  type   = "lower",
                  lab    = TRUE,
                  lab_size = 3.5,
                  colors = c("#E53935", "white", "#1E88E5"),
                  title  = "Ma trận tương quan") +
  GiaoDienRossmann +
  theme(
    axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10)
  )

print(BieuDo3)
ggsave(here("output", "figures", "p3_correlation.png"), BieuDo3,
       width = 10, height = 5, dpi = 150)


## ----plot-4, fig.width=11, fig.height=6---------------------------------------
DuLieuKhongKM <- DuLieu %>%
  filter(day_of_week != 7) %>%
  filter(promo == 0) %>%
  group_by(day_of_week) %>%
  summarise(KhongKM = mean(sales), .groups = "drop")

DuLieuCoKM <- DuLieu %>%
  filter(day_of_week != 7) %>%
  filter(promo == 1) %>%
  group_by(day_of_week) %>%
  summarise(CoKM = mean(sales), .groups = "drop")

DoanhThuTheoNgayKhuyenMai <- inner_join(DuLieuKhongKM, DuLieuCoKM, by = "day_of_week")

DoanhThuTheoNgayKhuyenMai <- DoanhThuTheoNgayKhuyenMai %>%
  mutate(
    NhanNgay = factor(day_of_week, levels = 6:1,
                      labels = c("Thứ 7", "Thứ 6", "Thứ 5", "Thứ 4", "Thứ 3", "Thứ 2"))
  )

BieuDo4 <- ggplot(DoanhThuTheoNgayKhuyenMai) +
  geom_segment(aes(x = KhongKM, xend = CoKM, y = NhanNgay, yend = NhanNgay),
               color = "#CFD8DC", linewidth = 1.2) +
  geom_point(aes(x = KhongKM, y = NhanNgay, color = "Không khuyến mãi"), size = 4) +
  geom_point(aes(x = CoKM, y = NhanNgay, color = "Có khuyến mãi"), size = 4) +
  scale_x_continuous(labels = comma) +
  scale_color_manual(
    values = c("Không khuyến mãi" = "#78909C", "Có khuyến mãi" = "#E53935"),
    name = "Chiến dịch"
  ) +
  labs(
    title    = "Hiệu quả Khuyến mãi theo Ngày trong tuần",
    subtitle = "Khoảng cách biểu diễn chênh lệch doanh số trung bình giữa ngày thường và ngày khuyến mãi",
    x = "Doanh số trung bình hàng ngày (EUR)", y = NULL
  ) +
  GiaoDienRossmann

print(BieuDo4)
ggsave(here("output", "figures", "p4_dumbbell.png"), BieuDo4,
       width = 11, height = 6, dpi = 150)


## ----plot-5, fig.width=11, fig.height=7---------------------------------------
DuLieuChiTieu <- DuLieu %>%
  mutate(
    NhanCoCau = ifelse(assortment == "a", "Basic\n(Cơ bản)", "Extended\n(Mở rộng)"),
    NhanLoaiCuaHang = case_when(
      store_type == "a" ~ "Type A (Phổ thông)",
      store_type == "c" ~ "Type C (Nhỏ ngoại ô)",
      store_type == "d" ~ "Type D (Flagship)",
      TRUE ~ as.character(store_type)
    )
  )

BieuDo5 <- ggplot(DuLieuChiTieu, aes(x = NhanCoCau, y = sales_per_customer, fill = NhanCoCau)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.08, outlier.size = 0.5, lwd = 0.5) +
  facet_wrap(~NhanLoaiCuaHang) +
  scale_fill_manual(values = c("Basic\n(Cơ bản)" = "#1E88E5", "Extended\n(Mở rộng)" = "#E53935")) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Chi tiêu Trung bình mỗi Khách hàng theo Cơ cấu Sản phẩm",
    subtitle = "Phân phối chi tiêu trung bình trên mỗi khách hàng theo Loại hình Cửa hàng",
    x = "Cơ cấu sản phẩm (Assortment)", y = "Chi tiêu TB / Khách (EUR)",
    fill = "Cơ cấu sản phẩm"
  ) +
  GiaoDienRossmann +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 11)
  )

print(BieuDo5)
ggsave(here("output", "figures", "p5_spc_boxplot.png"), BieuDo5,
       width = 11, height = 7, dpi = 150)


## ----plot-6, fig.width=11, fig.height=6---------------------------------------
DuLieuCanhTranh <- DuLieu %>%
  mutate(
    NhomCanhTranh = case_when(
      has_competition == 0 ~ "Không có đối thủ",
      competition_open_months <= 12 ~ "≤ 1 năm",
      competition_open_months <= 36 ~ "1–3 năm",
      competition_open_months <= 60 ~ "3–5 năm",
      competition_open_months <= 120 ~ "5–10 năm",
      TRUE ~ "> 10 năm"
    ),
    NhomCanhTranh = factor(NhomCanhTranh, levels = c(
      "Không có đối thủ", "≤ 1 năm", "1–3 năm", "3–5 năm", "5–10 năm", "> 10 năm"
    ))
  )

ThongKeCanhTranh <- DuLieuCanhTranh %>%
  group_by(NhomCanhTranh) %>%
  summarise(
    DoanhThuTB = mean(sales),
    SaiSoChuan = sd(sales) / sqrt(n()),
    SoLuong    = n(),
    .groups = "drop"
  )

MauCanhTranh <- c("Không có đối thủ" = "#4CAF50",
                   "≤ 1 năm" = "#FFC107", "1–3 năm" = "#FF9800",
                   "3–5 năm" = "#F44336", "5–10 năm" = "#9C27B0", "> 10 năm" = "#3F51B5")

BieuDo6 <- ggplot(ThongKeCanhTranh, aes(x = NhomCanhTranh, y = DoanhThuTB, fill = NhomCanhTranh)) +
  geom_col(alpha = 0.85, width = 0.65) +
  geom_text(aes(label = comma(round(DoanhThuTB))), vjust = -0.5, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = MauCanhTranh) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
  labs(
    title    = "Ảnh hưởng của Thời gian Đối thủ Cạnh tranh đến Doanh số",
    subtitle = "Doanh số trung bình theo thời gian hoạt động của đối thủ cạnh tranh",
    x = "Thời gian đối thủ đã hoạt động", 
    y = "Doanh số trung bình (EUR/ngày)",
    fill = NULL
  ) +
  GiaoDienRossmann +
  theme(legend.position = "none")

print(BieuDo6)
ggsave(here("output", "figures", "p6_competition_duration.png"), BieuDo6, width = 11, height = 6, dpi = 150)


## ----plot-7, fig.width=11, fig.height=6---------------------------------------
DuLieuKhuyenMai <- DuLieu %>%
  mutate(
    TrangThaiKM = case_when(
      promo == 0 & promo2 == 0 ~ "Không KM",
      promo == 0 & promo2 == 1 ~ "Chỉ Promo2 (Dài hạn)",
      promo == 1 & promo2 == 0 ~ "Chỉ Promo (Ngắn hạn)",
      promo == 1 & promo2 == 1 ~ "Cộng hưởng cả hai",
      TRUE ~ "Khác"
    ),
    TrangThaiKM = factor(TrangThaiKM, levels = c(
      "Không KM", "Chỉ Promo2 (Dài hạn)", "Chỉ Promo (Ngắn hạn)", "Cộng hưởng cả hai"
    ))
  )

ThongKeKhuyenMai <- DuLieuKhuyenMai %>%
  group_by(TrangThaiKM, store_type) %>%
  summarise(
    DoanhThuTB = mean(sales),
    DoLechChuan = sd(sales),
    SoLuong = n(),
    SaiSoChuan = DoLechChuan / sqrt(SoLuong),
    .groups = "drop"
  ) %>%
  mutate(
    NhanLoaiCuaHang = case_when(
      store_type == "a" ~ "Type A (Phổ thông)",
      store_type == "c" ~ "Type C (Nhỏ ngoại ô)",
      store_type == "d" ~ "Type D (Flagship)",
      TRUE ~ as.character(store_type)
    )
  )

BieuDo7 <- ggplot(ThongKeKhuyenMai, aes(x = TrangThaiKM, y = DoanhThuTB, fill = TrangThaiKM)) +
  geom_col(alpha = 0.85, width = 0.65) +
  geom_errorbar(aes(ymin = DoanhThuTB - SaiSoChuan, ymax = DoanhThuTB + SaiSoChuan),
                width = 0.2, linewidth = 0.5, color = "grey30") +
  facet_wrap(~NhanLoaiCuaHang, scales = "free_y") +
  scale_fill_manual(values = c(
    "Không KM" = "#90A4AE",
    "Chỉ Promo2 (Dài hạn)" = "#FF9800",
    "Chỉ Promo (Ngắn hạn)" = "#2196F3",
    "Cộng hưởng cả hai" = "#E53935"
  )) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Hiệu ứng Cộng hưởng giữa Khuyến mãi Định kỳ và Khuyến mãi Dài hạn",
    subtitle = "Doanh số trung bình hàng ngày (±1 SE) theo loại hình cửa hàng",
    x = "Trạng thái chiến dịch khuyến mãi",
    y = "Doanh số trung bình hàng ngày (EUR)",
    fill = "Chiến dịch"
  ) +
  GiaoDienRossmann +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 30, vjust = 1, hjust = 1, size = 9),
    strip.text = element_text(face = "bold", size = 11)
  )

print(BieuDo7)
ggsave(here("output", "figures", "p7_promo_interaction.png"), BieuDo7,
       width = 11, height = 6, dpi = 150)


## ----plot-8a------------------------------------------------------------------
DuLieuGanNhanNgoaiLe <- DuLieu %>%
  mutate(NhanNgoaiLe = ifelse(is_outlier, "Ngoại lệ (Outlier)", "Bình thường (Normal)"))

BieuDo8A <- ggplot(DuLieuGanNhanNgoaiLe, aes(x = store_type, y = sales, fill = NhanNgoaiLe)) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.5, outlier.alpha = 0.3) +
  scale_fill_manual(values = c("Bình thường (Normal)" = "#1E88E5", "Ngoại lệ (Outlier)" = "#E53935")) +
  scale_x_discrete(labels = c("a" = "Type A", "b" = "Type B", "c" = "Type C", "d" = "Type D")) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Biểu đồ 8A: Phân phối Doanh số: Bình thường vs Ngoại lệ",
    subtitle = "Outlier flag được tính bằng IQR theo từng cửa hàng (tập Train)",
    x = "Loại cửa hàng", y = "Doanh số (EUR)", fill = NULL
  ) +
  GiaoDienRossmann +
  theme(legend.position = "right")

print(BieuDo8A)
ggsave(here("output", "figures", "p8a_outlier_distribution.png"), BieuDo8A,
       width = 10, height = 5, dpi = 150)


## ----plot-8b------------------------------------------------------------------
TyLeNgoaiLeTheoThang <- DuLieu %>%
  group_by(month) %>%
  summarise(
    TongSoLuong   = n(),
    SoLuongNgoaiLe = sum(is_outlier, na.rm = TRUE),
    PhanTramNgoaiLe       = round(SoLuongNgoaiLe / TongSoLuong * 100, 1),
    .groups   = "drop"
  ) %>%
  mutate(
    NhanThang = factor(month, levels = 1:12,
                       labels = c("T1","T2","T3","T4","T5","T6","T7","T8","T9","T10","T11","T12")),
    TrenTrungBinh = PhanTramNgoaiLe > mean(PhanTramNgoaiLe)
  )

BieuDo8B <- ggplot(TyLeNgoaiLeTheoThang, aes(x = NhanThang, y = PhanTramNgoaiLe, fill = TrenTrungBinh)) +
  geom_col(alpha = 0.85, width = 0.7) +
  scale_fill_manual(values = c("FALSE" = "#64B5F6", "TRUE" = "#E53935"),
                    labels = c("Dưới TB", "Trên TB"), name = "So với trung bình") +
  labs(
    title    = "Biểu đồ 8B: Tỷ lệ Outlier theo Tháng",
    subtitle = "Tỷ lệ ngày có doanh số ngoại lệ theo từng tháng trong năm",
    x = "Tháng", y = "% Outlier"
  ) +
  GiaoDienRossmann

print(BieuDo8B)
ggsave(here("output", "figures", "p8b_outlier_month.png"), BieuDo8B,
       width = 10, height = 5, dpi = 150)


## ----plot-9, fig.width=12, fig.height=7---------------------------------------
HoSoCuaHang <- DuLieu %>%
  group_by(store, store_type, assortment) %>%
  summarise(
    DoanhThuTB   = mean(sales),
    KhachHangTB  = mean(customers),
    ChiTieuTB    = mean(sales_per_customer),
    KhoangCachDoiThu = mean(competition_distance),
    .groups = "drop"
  ) %>%
  mutate(
    NhanLoaiCuaHang = case_when(
      store_type == "a" ~ "Type A (Phổ thông)",
      store_type == "c" ~ "Type C (Nhỏ ngoại ô)",
      store_type == "d" ~ "Type D (Flagship)",
      TRUE ~ as.character(store_type)
    ),
    NhanCoCau = ifelse(assortment == "a", "Basic (Cơ bản)", "Extended (Mở rộng)")
  )

BieuDo9 <- ggplot(HoSoCuaHang, aes(x = KhoangCachDoiThu, y = DoanhThuTB)) +
  geom_point(aes(size = KhachHangTB, fill = NhanCoCau),
             shape = 21, alpha = 0.75, color = "white", stroke = 0.8) +
  facet_wrap(~NhanLoaiCuaHang, scales = "free_x") +
  scale_size_continuous(
    range = c(4, 18),
    labels = comma,
    name = "Lượng khách TB/ngày"
  ) +
  scale_fill_manual(
    values = c("Basic (Cơ bản)" = "#1E88E5", "Extended (Mở rộng)" = "#E53935"),
    name = "Cơ cấu sản phẩm"
  ) +
  scale_x_continuous(labels = comma) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Toàn cảnh Hiệu suất 50 Cửa hàng Rossmann",
    subtitle = "Kích thước = Lượng khách trung bình | Màu = Cơ cấu sản phẩm",
    x = "Khoảng cách đến đối thủ gần nhất (m)",
    y = "Doanh số trung bình hàng ngày (EUR)"
  ) +
  GiaoDienRossmann +
  theme(
    legend.position = "right",
    strip.text = element_text(face = "bold", size = 11)
  ) +
  guides(size = guide_legend(order = 1), fill = guide_legend(order = 2, override.aes = list(size = 6)))

print(BieuDo9)
ggsave(here("output", "figures", "p9_bubble_store_performance.png"), BieuDo9,
       width = 12, height = 7, dpi = 150)


## ----plot-11, fig.width=11, fig.height=10-------------------------------------
HieuSuatCuaHang <- DuLieu %>%
  group_by(store, store_type) %>%
  summarise(DoanhThuTB = mean(sales), .groups = "drop") %>%
  mutate(
    TrungBinhHeThong = mean(DoanhThuTB),
    ChenhLech = DoanhThuTB - TrungBinhHeThong,
    ViTri     = ifelse(ChenhLech >= 0, "Trên trung bình", "Dưới trung bình")
  )

BieuDo11 <- ggplot(HieuSuatCuaHang, aes(x = reorder(factor(store), ChenhLech), y = ChenhLech)) +
  geom_segment(aes(xend = factor(store), y = 0, yend = ChenhLech, color = ViTri), linewidth = 0.5) +
  geom_point(aes(color = ViTri), size = 2) +
  coord_flip() +
  scale_color_manual(values = c("Trên trung bình" = "#4CAF50", "Dưới trung bình" = "#E53935"), name = "Hiệu suất") +
  labs(
    title    = "Lollipop Chart: Xếp hạng 50 Cửa hàng theo Chênh lệch Doanh số",
    subtitle = "So với trung bình hệ thống | Màu = Hiệu suất",
    x = "Mã cửa hàng (Store ID)", y = "Chênh lệch so với trung bình (EUR)"
  ) +
  GiaoDienRossmann +
  theme(
    axis.text.y = element_text(size = 6),
    legend.position = "right"
  )

print(BieuDo11)
ggsave(here("output", "figures", "p11_lollipop_ranking.png"), BieuDo11,
       width = 11, height = 10, dpi = 150)

