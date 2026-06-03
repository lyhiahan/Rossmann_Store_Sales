# =============================================================================
# QUỐC ANH — KIỂM ĐỊNH THỐNG KÊ (STATISTICAL TESTING)
# File: R/statistical_tests.R
# Người phụ trách: Quốc Anh (Nhóm trưởng)
# Mô tả: ANOVA + Kruskal-Wallis, t-test + Wilcoxon, Correlation
#         Kiểm tra giả định phân phối chuẩn TRƯỚC khi chạy kiểm định
# =============================================================================
# CHÚ Ý: Chỉ Quốc Anh được chỉnh sửa file này!
# =============================================================================

library(dplyr)
library(effectsize)
library(here)

train_df <- readRDS(here("data", "processed", "train_data.rds"))

cat("╔══════════════════════════════════════════════════════════╗\n")
cat("║  QUỐC ANH — KIỂM ĐỊNH THỐNG KÊ                        ║\n")
cat("║  (Kiểm tra giả định + Phi tham số đối chứng)           ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n\n")

# =============================================================================
# 0. KIỂM TRA GIẢ ĐỊNH PHÂN PHỐI CHUẨN (NORMALITY CHECK)
# =============================================================================
cat("━━━ 0. KIỂM TRA PHÂN PHỐI CHUẨN ━━━\n\n")

skew_sales <- moments::skewness(train_df$sales)
kurt_sales <- moments::kurtosis(train_df$sales)

cat("Skewness (Sales):", round(skew_sales, 3), "\n")
cat("Kurtosis (Sales):", round(kurt_sales, 3), "\n")

# Shapiro-Wilk trên sample (giới hạn 5000)
shapiro_result <- shapiro.test(sample(train_df$sales, min(5000, nrow(train_df))))
cat("Shapiro-Wilk p-value:", format(shapiro_result$p.value, digits = 4), "\n")

is_normal <- shapiro_result$p.value > 0.05 & abs(skew_sales) < 1

if (!is_normal) {
  cat("\n⚠️ Dữ liệu Sales LỆCH PHẢI (Skewness =", round(skew_sales, 2), ")\n")
  cat("→ ANOVA/t-test truyền thống CÓ THỂ không phù hợp\n")
  cat("→ Bổ sung kiểm định PHI THAM SỐ (Kruskal-Wallis, Wilcoxon) làm đối chứng\n")
  cat("→ Thử Log-transform: log(sales) để giảm skewness\n")
} else {
  cat("✓ Dữ liệu gần phân phối chuẩn — ANOVA/t-test hợp lệ\n")
}

# Log-transform
train_df <- train_df %>% mutate(log_sales = log(sales))
skew_log <- moments::skewness(train_df$log_sales)
cat("\nSkewness sau log-transform:", round(skew_log, 3),
    "(giảm từ", round(skew_sales, 3), ")\n")

# =============================================================================
# 1. ANOVA + KRUSKAL-WALLIS: Sales ~ StoreType
# =============================================================================
cat("\n━━━ 1. KIỂM ĐỊNH ANOVA: sales ~ store_type ━━━\n")
cat("H0: Doanh thu trung bình giống nhau giữa các loại cửa hàng\n")
cat("H1: Ít nhất một loại cửa hàng có doanh thu khác biệt\n\n")

# --- 1a. ANOVA truyền thống ---
cat("--- a) ANOVA (parametric) ---\n")
anova_fit     <- aov(sales ~ store_type, data = train_df)
anova_summary <- summary(anova_fit)
print(anova_summary)

p_anova <- anova_summary[[1]][["Pr(>F)"]][1]
cat("\np-value (ANOVA):", format(p_anova, digits = 4), "\n")

# Post-hoc Tukey
tukey_result <- NULL
if (p_anova < 0.05) {
  cat("→ Có sự khác biệt có ý nghĩa thống kê (p < 0.05)\n")
  tukey_result <- TukeyHSD(anova_fit)
  print(tukey_result)
}

# --- 1b. ANOVA trên log(sales) ---
cat("\n--- b) ANOVA trên log(sales) (giảm skewness) ---\n")
anova_log     <- aov(log_sales ~ store_type, data = train_df)
anova_log_sum <- summary(anova_log)
p_anova_log   <- anova_log_sum[[1]][["Pr(>F)"]][1]
cat("p-value (ANOVA log):", format(p_anova_log, digits = 4), "\n")

# --- 1c. Kruskal-Wallis (phi tham số — đối chứng) ---
cat("\n--- c) Kruskal-Wallis (non-parametric — đối chứng) ---\n")
kw_result <- kruskal.test(sales ~ store_type, data = train_df)
print(kw_result)
cat("→ Kruskal-Wallis p-value:", format(kw_result$p.value, digits = 4), "\n")

if (p_anova < 0.05 & kw_result$p.value < 0.05) {
  cat("→ ✓ Cả ANOVA và Kruskal-Wallis đều xác nhận sự khác biệt → KẾT QUẢ ĐÁNG TIN CẬY\n")
}

# =============================================================================
# 2. WELCH t-test + WILCOXON: Sales ~ Promo
# =============================================================================
cat("\n━━━ 2. KIỂM ĐỊNH t-test: sales ~ promo ━━━\n")
cat("H0: Khuyến mãi không ảnh hưởng đến doanh thu\n")
cat("H1: Khuyến mãi có ảnh hưởng đến doanh thu\n\n")

# --- 2a. Welch t-test ---
cat("--- a) Welch t-test (parametric) ---\n")
ttest_promo <- t.test(sales ~ promo, data = train_df)
print(ttest_promo)

promo_yes <- train_df %>% filter(promo == 1) %>% pull(sales)
promo_no  <- train_df %>% filter(promo == 0) %>% pull(sales)

cat("\nMean Sales (Promo=1):", round(mean(promo_yes), 0), "EUR\n")
cat("Mean Sales (Promo=0):", round(mean(promo_no), 0), "EUR\n")
cat("Chênh lệch:", round(mean(promo_yes) - mean(promo_no), 0), "EUR",
    "(+", round((mean(promo_yes)/mean(promo_no) - 1) * 100, 1), "%)\n")

# --- 2b. Cohen's d chuẩn xác cho Welch t-test ---
# Dùng package effectsize (Welch-corrected, không phải pooled variance)
cat("\n--- b) Effect size (Welch-corrected Cohen's d) ---\n")
cohen_result <- effectsize::cohens_d(sales ~ promo, data = train_df, pooled_sd = FALSE)
cohen_d      <- cohen_result$Cohens_d
print(cohen_result)
cat("→ Cohen's d (Welch-corrected):", round(cohen_d, 3), "\n")

interpret_d <- effectsize::interpret_cohens_d(abs(cohen_d))
cat("→ Interpretation:", as.character(interpret_d), "\n")

# --- 2c. Wilcoxon Rank Sum (phi tham số — đối chứng) ---
cat("\n--- c) Wilcoxon Rank Sum / Mann-Whitney U (non-parametric) ---\n")
wilcox_result <- wilcox.test(sales ~ promo, data = train_df)
print(wilcox_result)
cat("→ Wilcoxon p-value:", format(wilcox_result$p.value, digits = 4), "\n")

# --- 2d. t-test trên log(sales) ---
cat("\n--- d) t-test trên log(sales) ---\n")
ttest_log <- t.test(log_sales ~ promo, data = train_df)
cat("p-value (log t-test):", format(ttest_log$p.value, digits = 4), "\n")

if (ttest_promo$p.value < 0.05 & wilcox_result$p.value < 0.05) {
  cat("→ ✓ Cả t-test và Wilcoxon đều xác nhận → KẾT QUẢ ĐÁNG TIN CẬY\n")
}

# =============================================================================
# 3. SPEARMAN CORRELATION: Sales vs CompetitionDistance
# =============================================================================
cat("\n━━━ 3. TƯƠNG QUAN: sales ~ competition_distance ━━━\n")
cat("H0: Không có tương quan giữa khoảng cách đối thủ và doanh thu\n\n")

# --- 3a. Tính hệ số tương quan trước (nhanh, không cần p-value) ---
rho_spearman <- cor(train_df$sales, train_df$competition_distance,
                     method = "spearman", use = "complete.obs")
rho_pearson  <- cor(train_df$sales, train_df$competition_distance,
                     method = "pearson", use = "complete.obs")

cat("Spearman rho:", round(rho_spearman, 4), "\n")
cat("Pearson r:   ", round(rho_pearson, 4), "\n")

# --- 3b. cor.test với suppressWarnings (xử lý ties) ---
suppressWarnings({
  cor_result <- cor.test(train_df$sales, train_df$competition_distance,
                          method = "spearman", exact = FALSE)
})
cat("p-value:     ", format(cor_result$p.value, digits = 4), "\n")

if (cor_result$p.value < 0.05) {
  cat("→ Tương quan có ý nghĩa thống kê nhưng RẤT YẾU (|rho| =",
      round(abs(rho_spearman), 4), ")\n")
  cat("→ Ý nghĩa thống kê ≠ ý nghĩa thực tiễn (do n lớn, p dễ nhỏ)\n")
} else {
  cat("→ Tương quan không có ý nghĩa thống kê\n")
}

# =============================================================================
# LƯU KẾT QUẢ
# =============================================================================
stat_tests_results <- list(
  # Normality check
  skewness_sales     = skew_sales,
  skewness_log_sales = skew_log,
  shapiro_result     = shapiro_result,
  is_normal          = is_normal,
  # ANOVA + Kruskal-Wallis
  anova_storetype    = anova_summary,
  anova_log_summary  = anova_log_sum,
  tukey_storetype    = tukey_result,
  kruskal_wallis     = kw_result,
  # t-test + Wilcoxon
  ttest_promo        = ttest_promo,
  ttest_log_promo    = ttest_log,
  cohen_d_promo      = cohen_result,
  wilcoxon_promo     = wilcox_result,
  # Correlation
  spearman_rho       = rho_spearman,
  pearson_r          = rho_pearson,
  cor_test_result    = cor_result
)
saveRDS(stat_tests_results, here("output", "tables", "stat_tests.rds"))

cat("\n[Quốc Anh] ✅ Kiểm định thống kê hoàn tất!\n")
cat("[Quốc Anh] ✅ Bao gồm: Normality check + Parametric + Non-parametric đối chứng\n")
cat("[Quốc Anh] ✅ Cohen's d: Welch-corrected (effectsize package)\n")
cat("[Quốc Anh] ✅ Đã lưu: output/tables/stat_tests.rds\n")
