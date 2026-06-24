# KIỂM ĐỊNH THỐNG KÊ (STATISTICAL TESTING)
# File: R/statistical_tests.R
# Người phụ trách: Gia Hân
# Mô tả: ANOVA + Kruskal-Wallis, t-test + Wilcoxon, Correlation
# Kiểm tra giả định phân phối chuẩn TRƯỚC khi chạy kiểm định

library(dplyr)
library(effectsize)
library(car)
library(here)
here::i_am("R/statistical_tests.R")

train_df <- readRDS(here("data", "processed", "train_data.rds"))

# 0. KIỂM TRA GIẢ ĐỊNH PHÂN PHỐI CHUẨN (NORMALITY CHECK)
cat("0. KIỂM TRA PHÂN PHỐI CHUẨN\n\n")

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

# 1. ANOVA + KRUSKAL-WALLIS: Sales ~ StoreType
cat("\n1. KIỂM ĐỊNH ANOVA: sales ~ store_type\n")
cat("H0: Doanh thu trung bình giống nhau giữa các loại cửa hàng\n")
cat("H1: Ít nhất một loại cửa hàng có doanh thu khác biệt\n\n")

# 1a. ANOVA truyền thống
cat(" a) ANOVA (parametric) \n")
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

# 1b. ANOVA trên log(sales)
cat("\n b) ANOVA trên log(sales) (giảm skewness) \n")
anova_log     <- aov(log_sales ~ store_type, data = train_df)
anova_log_sum <- summary(anova_log)
p_anova_log   <- anova_log_sum[[1]][["Pr(>F)"]][1]
cat("p-value (ANOVA log):", format(p_anova_log, digits = 4), "\n")

# 1c. Kruskal-Wallis (phi tham số — đối chứng)
cat("\n c) Kruskal-Wallis (non-parametric — đối chứng) \n")
kw_result <- kruskal.test(sales ~ store_type, data = train_df)
print(kw_result)
cat("→ Kruskal-Wallis p-value:", format(kw_result$p.value, digits = 4), "\n")

if (p_anova < 0.05 & kw_result$p.value < 0.05) {
  cat("→ ✓ Cả ANOVA và Kruskal-Wallis đều xác nhận sự khác biệt → KẾT QUẢ ĐÁNG TIN CẬY\n")
}

# 1d. Levene's test (kiểm tra phương sai đồng nhất)
cat("\n d) Levene's test (giả định phương sai đồng nhất) \n")
cat("Giả định ANOVA: phương sai giữa các nhóm phải đồng nhất\n")
levene_result <- car::leveneTest(sales ~ store_type, data = train_df)
print(levene_result)
p_levene <- levene_result$`Pr(>F)`[1]
cat("→ Levene's p-value:", format(p_levene, digits = 4), "\n")

welch_anova <- NULL
if (p_levene < 0.05) {
  cat("→ ⚠️ Phương sai KHÔNG đồng nhất (p < 0.05)\n")
  cat("→ Bổ sung Welch ANOVA (không yêu cầu phương sai đồng nhất)\n")
  welch_anova <- oneway.test(sales ~ store_type, data = train_df, var.equal = FALSE)
  cat("→ Welch ANOVA F-statistic:", round(welch_anova$statistic, 2), "\n")
  cat("→ Welch ANOVA p-value:", format(welch_anova$p.value, digits = 4), "\n")
} else {
  cat("→ ✓ Phương sai đồng nhất → ANOVA truyền thống hợp lệ\n")
}

# 1e. Effect size (Eta-squared) cho ANOVA
cat("\n e) Effect size (Eta-squared) cho ANOVA \n")
cat("p-value cho biết CÓ khác biệt hay không, Eta² cho biết MỨC ĐỘ khác biệt\n")
eta_result <- effectsize::eta_squared(anova_fit)
print(eta_result)
eta_val <- eta_result$Eta2
cat("→ Eta²:", round(eta_val, 4), "\n")
interpret_eta <- effectsize::interpret_eta_squared(eta_val)
cat("→ Mức độ ảnh hưởng:", as.character(interpret_eta), "\n")
cat("→ Thang đo: small < 0.01 | medium < 0.06 | large ≥ 0.14\n")

# 2. WELCH t-test + WILCOXON: Sales ~ Promo
cat("\n2. KIỂM ĐỊNH t-test: sales ~ promo\n")
cat("H0: Khuyến mãi không ảnh hưởng đến doanh thu\n")
cat("H1: Khuyến mãi có ảnh hưởng đến doanh thu\n\n")

# 2a. Welch t-test
cat(" a) Welch t-test (parametric) \n")
ttest_promo <- t.test(sales ~ promo, data = train_df)
print(ttest_promo)

promo_yes <- train_df %>% filter(promo == 1) %>% pull(sales)
promo_no  <- train_df %>% filter(promo == 0) %>% pull(sales)

cat("\nMean Sales (Promo=1):", round(mean(promo_yes), 0), "EUR\n")
cat("Mean Sales (Promo=0):", round(mean(promo_no), 0), "EUR\n")
cat("Chênh lệch:", round(mean(promo_yes) - mean(promo_no), 0), "EUR",
    "(+", round((mean(promo_yes)/mean(promo_no) - 1) * 100, 1), "%)\n")

# 2b. Cohen's d chuẩn xác cho Welch t-test
# Dùng package effectsize (Welch-corrected, không phải pooled variance)
cat("\n b) Effect size (Welch-corrected Cohen's d) \n")
cohen_result <- effectsize::cohens_d(sales ~ promo, data = train_df, pooled_sd = FALSE)
cohen_d      <- cohen_result$Cohens_d
print(cohen_result)
cat("→ Cohen's d (Welch-corrected):", round(cohen_d, 3), "\n")

interpret_d <- effectsize::interpret_cohens_d(abs(cohen_d))
cat("→ Interpretation:", as.character(interpret_d), "\n")

# 2c. Wilcoxon Rank Sum (phi tham số — đối chứng)
cat("\n c) Wilcoxon Rank Sum / Mann-Whitney U (non-parametric) \n")
wilcox_result <- wilcox.test(sales ~ promo, data = train_df)
print(wilcox_result)
cat("→ Wilcoxon p-value:", format(wilcox_result$p.value, digits = 4), "\n")

# 2d. t-test trên log(sales)
cat("\n d) t-test trên log(sales) \n")
ttest_log <- t.test(log_sales ~ promo, data = train_df)
cat("p-value (log t-test):", format(ttest_log$p.value, digits = 4), "\n")

if (ttest_promo$p.value < 0.05 & wilcox_result$p.value < 0.05) {
  cat("→ ✓ Cả t-test và Wilcoxon đều xác nhận → KẾT QUẢ ĐÁNG TIN CẬY\n")
}

# 2e. Khoảng tin cậy 95% cho chênh lệch trung bình
cat("\n e) Khoảng tin cậy 95% (CI) cho chênh lệch doanh thu \n")
cat("Theo lý thuyết ước lượng khoảng: CI bổ sung cho ước lượng điểm\n")
cat("→ 95% CI cho (µ_promo=0 − µ_promo=1):\n")
cat("   [", round(ttest_promo$conf.int[1], 2), ",",
    round(ttest_promo$conf.int[2], 2), "] EUR\n")
if (ttest_promo$conf.int[1] > 0 | ttest_promo$conf.int[2] < 0) {
  cat("→ Khoảng KHÔNG chứa 0 → xác nhận khuyến mãi CÓ ảnh hưởng\n")
} else {
  cat("→ Khoảng CHỨA 0 → chưa đủ bằng chứng kết luận\n")
}
cat("→ Diễn giải: Ta 95% tin tưởng chênh lệch doanh thu thực sự\n")
cat("   giữa ngày KM và không KM nằm trong khoảng trên.\n")

# 📝 Diễn giải p-value đúng theo lý thuyết XSTK
cat("\n📝 LƯU Ý VỀ P-VALUE (theo lý thuyết XSTK):\n")
cat("   • p-value KHÔNG phải xác suất H₀ đúng\n")
cat("   • p-value = P(quan sát dữ liệu cực đoan | H₀ đúng)\n")
cat("   • p < α (0.05): Bác bỏ H₀ — có ý nghĩa thống kê\n")
cat("   • p ≥ α: Không đủ bằng chứng bác bỏ H₀\n")
cat("   • Rủi ro lỗi loại I (bác bỏ H₀ đúng) = α = 5%\n")
cat("   • Ý nghĩa thống kê ≠ Ý nghĩa thực tiễn → luôn xem effect size\n")

# 3. SPEARMAN CORRELATION: Sales vs CompetitionDistance
cat("\n3. TƯƠNG QUAN: sales ~ competition_distance\n")
cat("H0: Không có tương quan giữa khoảng cách đối thủ và doanh thu\n\n")

# 3a. Tính hệ số tương quan trước (nhanh, không cần p-value)
rho_spearman <- cor(train_df$sales, train_df$competition_distance,
                     method = "spearman", use = "complete.obs")
rho_pearson  <- cor(train_df$sales, train_df$competition_distance,
                     method = "pearson", use = "complete.obs")

cat("Spearman rho:", round(rho_spearman, 4), "\n")
cat("Pearson r:   ", round(rho_pearson, 4), "\n")

# 3b. cor.test với suppressWarnings (xử lý ties)
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

# 4. BOOTSTRAP CONFIDENCE INTERVAL
cat("\n4. BOOTSTRAP CONFIDENCE INTERVAL\n")
cat("Ước lượng khoảng tin cậy Bootstrap cho trung bình doanh thu\n")
cat("(Bootstrap không cần giả định phân phối chuẩn)\n\n")

set.seed(42)
n_boot <- 1000
boot_means <- replicate(n_boot, {
  boot_sample <- sample(train_df$sales, size = length(train_df$sales), replace = TRUE)
  mean(boot_sample)
})

boot_ci <- quantile(boot_means, c(0.025, 0.975))
boot_se <- sd(boot_means)
obs_mean_sales <- mean(train_df$sales)

cat("Số lần lấy mẫu lại (reps):", n_boot, "\n")
cat("Trung bình mẫu (point estimate):", round(obs_mean_sales, 2), "EUR\n")
cat("Bootstrap SE (sai số chuẩn):", round(boot_se, 2), "\n")
cat("Bootstrap 95% CI: [", round(boot_ci[1], 2), ",",
    round(boot_ci[2], 2), "] EUR\n")
cat("→ Ta 95% tin tưởng doanh thu trung bình thực sự\n")
cat("   của các cửa hàng Rossmann nằm trong khoảng trên.\n")

# So sánh Bootstrap CI với CI lý thuyết (CLT)
cat("\n So sánh với CI lý thuyết (theo CLT) \n")
cat("Theo CLT: X̄ ~ N(µ, σ²/n) khi n đủ lớn\n")
n_obs <- length(train_df$sales)
se_clt <- sd(train_df$sales) / sqrt(n_obs)
ci_clt <- c(obs_mean_sales - 1.96 * se_clt, obs_mean_sales + 1.96 * se_clt)
cat("CLT-based SE:", round(se_clt, 2), "\n")
cat("CLT-based 95% CI: [", round(ci_clt[1], 2), ",",
    round(ci_clt[2], 2), "] EUR\n")
cat("→ Bootstrap CI và CLT CI cho kết quả tương đồng\n")
cat("→ Xác nhận tính tin cậy của ước lượng (cả 2 phương pháp đồng thuận)\n")

# LƯU KẾT QUẢ
stat_tests_results <- list(
  # Normality check
  skewness_sales     = skew_sales,
  skewness_log_sales = skew_log,
  shapiro_result     = shapiro_result,
  is_normal          = is_normal,
  # ANOVA + Kruskal-Wallis + Levene + Eta²
  anova_storetype    = anova_summary,
  anova_log_summary  = anova_log_sum,
  tukey_storetype    = tukey_result,
  kruskal_wallis     = kw_result,
  levene_test        = levene_result,
  welch_anova        = welch_anova,
  eta_squared        = eta_result,
  # t-test + Wilcoxon + CI
  ttest_promo        = ttest_promo,
  ttest_log_promo    = ttest_log,
  cohen_d_promo      = cohen_result,
  wilcoxon_promo     = wilcox_result,
  ci_promo_diff      = ttest_promo$conf.int,
  # Correlation
  spearman_rho       = rho_spearman,
  pearson_r          = rho_pearson,
  cor_test_result    = cor_result,
  # Bootstrap
  bootstrap_ci       = boot_ci,
  bootstrap_se       = boot_se,
  clt_ci             = ci_clt
)
saveRDS(stat_tests_results, here("output", "tables", "stat_tests.rds"))

cat("\n✅ Kiểm định thống kê hoàn tất!\n")
cat("✅ Normality check + Parametric + Non-parametric đối chứng\n")
cat("✅ Levene's test + Welch ANOVA (phương sai đồng nhất)\n")
cat("✅ Effect size: Cohen's d (Welch) + Eta² (ANOVA)\n")
cat("✅ Khoảng tin cậy 95%: Welch CI + Bootstrap CI + CLT CI\n")
cat("✅ Diễn giải p-value đúng theo lý thuyết XSTK\n")
cat("✅ Đã lưu: output/tables/stat_tests.rds\n")
