# =============================================================================
# TV1 — STATISTICAL TESTS
# File: R/tv1_statistical_tests.R
# Người phụ trách: Thành viên 1 (Nhóm trưởng)
# Mô tả: Các kiểm định thống kê: ANOVA, t-test, cor.test
# =============================================================================
# CHÚ Ý: Chỉ TV1 được chỉnh sửa file này!
# =============================================================================

library(dplyr)
library(here)

# --- Đọc dữ liệu đã xử lý ---
df <- readRDS(here("output", "data", "df_clean.rds"))

# --- 1. ANOVA: Sales ~ StoreType ---
# H0: Doanh thu trung bình giống nhau giữa các loại cửa hàng
# H1: Ít nhất một loại cửa hàng có doanh thu khác biệt
cat("\n========== ANOVA: sales ~ store_type ==========\n")
anova_storetype <- aov(sales ~ store_type, data = df)
anova_summary   <- summary(anova_storetype)
print(anova_summary)

# Post-hoc Tukey nếu ANOVA có ý nghĩa
if (anova_summary[[1]][["Pr(>F)"]][1] < 0.05) {
  cat("\n--- Post-hoc Tukey HSD ---\n")
  tukey_result <- TukeyHSD(anova_storetype)
  print(tukey_result)
}

# --- 2. Welch t-test: Sales ~ Promo ---
# H0: Khuyến mãi không ảnh hưởng đến doanh thu
# H1: Khuyến mãi có ảnh hưởng đến doanh thu
cat("\n========== Welch t-test: sales ~ promo ==========\n")
ttest_promo <- t.test(sales ~ promo, data = df)
print(ttest_promo)

# Tính effect size (Cohen's d ước lượng)
promo_yes <- df %>% filter(promo == 1) %>% pull(sales)
promo_no  <- df %>% filter(promo == 0) %>% pull(sales)
cohen_d <- (mean(promo_yes) - mean(promo_no)) /
           sqrt((var(promo_yes) + var(promo_no)) / 2)
cat("Cohen's d (Promo effect size):", round(cohen_d, 3), "\n")

# --- 3. Correlation test: Sales vs CompetitionDistance ---
# H0: Không có tương quan giữa khoảng cách đối thủ và doanh thu
cat("\n========== Correlation: sales ~ competition_distance ==========\n")
cor_result <- cor.test(df$sales, df$competition_distance, method = "spearman")
print(cor_result)

# --- Lưu kết quả kiểm định ---
stat_tests_results <- list(
  anova_storetype = anova_summary,
  tukey_storetype = if (exists("tukey_result")) tukey_result else NULL,
  ttest_promo     = ttest_promo,
  cohen_d_promo   = cohen_d,
  cor_competition = cor_result
)
saveRDS(stat_tests_results, here("output", "data", "stat_tests.rds"))
cat("\n[TV1] ✅ Đã lưu kết quả kiểm định: stat_tests.rds\n")
