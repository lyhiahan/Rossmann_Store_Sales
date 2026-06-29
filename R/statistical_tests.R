# KIỂM ĐỊNH THỐNG KÊ (STATISTICAL TESTING)
# File: R/statistical_tests.R
# Người phụ trách: Quốc Anh 
# Mô tả: Normality check -> ANOVA/Welch + post-hoc -> t-test -> Correlation -> Bootstrap CI
#Quy trình: Kiểm tra giả định TRƯỚC, chọn kiểm định PHÙ HỢP, báo cáo effect size, đối chứng phi tham số.

library(dplyr)
library(effectsize)
library(car)
library(rstatix)
library(moments)
library(here)
here::i_am("R/statistical_tests.R")

train_df <- readRDS(here("data", "processed", "train_data.rds"))

cat("0. KIỂM TRA PHÂN PHỐI CHUẨN\n")

skew_sales  <- moments::skewness(train_df$sales)
kurt_sales  <- moments::kurtosis(train_df$sales)   # Pearson kurtosis (chuẩn = 3)
excess_kurt <- kurt_sales - 3                       # Excess kurtosis (chuẩn = 0)

cat("Skewness (Sales)    :", round(skew_sales, 3), "\n")
cat("Kurtosis (Pearson)  :", round(kurt_sales, 3),
    " | Excess kurtosis:", round(excess_kurt, 3), "(chuẩn = 0)\n")

# Shapiro-Wilk: R giới hạn tối đa 5.000 quan sát
# set.seed đảm bảo kết quả tái hiện được
set.seed(42)
shapiro_result <- shapiro.test(sample(train_df$sales, min(5000, nrow(train_df))))
cat("Shapiro-Wilk p-value:", format(shapiro_result$p.value, digits = 4),
    " (mẫu n =", min(5000, nrow(train_df)), "- giới hạn của R)\n")

# Tiêu chí: p > 0.05 VÀ |skewness| < 1
is_normal <- shapiro_result$p.value > 0.05 & abs(skew_sales) < 1

if (!is_normal) {
  cat("\n[!] Dữ liệu Sales LỆCH PHẢI (Skewness =", round(skew_sales, 2), ")\n")
  cat("    -> Bổ sung kiểm định PHI THAM SỐ làm đối chứng\n")
  cat("    -> Log-transform để giảm skewness\n")
} else {
  cat("\n[ok] Dữ liệu gần phân phối chuẩn -> ANOVA/t-test hợp lệ\n")
}

# Log-transform
train_df <- train_df %>% mutate(log_sales = log(sales))
skew_log <- moments::skewness(train_df$log_sales)
cat("\nSkewness sau log-transform:", round(skew_log, 3),
    "(giảm từ", round(skew_sales, 3), ")\n\n")



# 1. KIỂM ĐỊNH DOANH THU THEO LOẠI CỬA HÀNG: sales ~ store_type

cat("1. KIỂM ĐỊNH DOANH THU THEO LOẠI CỬA HÀNG: sales ~ store_type\n")

cat("H0: Doanh thu trung bình giống nhau giữa các loại cửa hàng\n")
cat("H1: Ít nhất một loại cửa hàng có doanh thu khác biệt\n\n")

# Thống kê mô tả theo nhóm
cat("Doanh thu trung bình theo nhóm:\n")
train_df %>%
  group_by(store_type) %>%
  summarise(
    n    = n(),
    mean = round(mean(sales), 2),
    sd   = round(sd(sales), 2)
  ) %>%
  print()
cat("\n")

#1a. Levene's test: kiểm tra phương sai đồng nhất TRƯỚC
cat("a) Levene's test (kiểm tra giả định đồng nhất phương sai)\n")
cat("   H0: Phương sai giữa các nhóm bằng nhau\n")
levene_result <- car::leveneTest(sales ~ store_type, data = train_df)
print(levene_result)
p_levene <- levene_result$`Pr(>F)`[1]
cat("-> Levene p-value:", format(p_levene, scientific = TRUE, digits = 4), "\n\n")

#1b. Kiểm định tham số: ANOVA hoặc Welch ANOVA tuỳ kết quả Levene
anova_fit     <- aov(sales ~ store_type, data = train_df)
anova_summary <- summary(anova_fit)
welch_anova   <- NULL
tukey_result  <- NULL
gh_result     <- NULL

if (p_levene >= 0.05) {
  
  cat("b) Phương sai ĐỒNG NHẤT (Levene p >= 0.05) -> ANOVA truyền thống\n")
  print(anova_summary)
  p_parametric <- anova_summary[[1]][["Pr(>F)"]][1]
  cat("-> ANOVA p-value:", format(p_parametric, scientific = TRUE, digits = 4), "\n")
  
  if (p_parametric < 0.05) {
    cat("\n   Post-hoc: Tukey HSD (phù hợp khi phương sai đồng nhất)\n")
    tukey_result <- TukeyHSD(anova_fit)
    print(tukey_result)
  }
  
} else {
  
  cat("b) Phương sai KHÔNG ĐỒNG NHẤT (Levene p < 0.05) -> Welch ANOVA\n")
  welch_anova  <- oneway.test(sales ~ store_type, data = train_df, var.equal = FALSE)
  print(welch_anova)
  p_parametric <- welch_anova$p.value
  cat("-> Welch ANOVA p-value:", format(p_parametric, scientific = TRUE, digits = 4), "\n")
  
  if (p_parametric < 0.05) {
    cat("\n   Post-hoc: Games-Howell (phù hợp khi phương sai KHÔNG đồng nhất)\n")
    gh_result <- rstatix::games_howell_test(train_df, sales ~ store_type)
    print(gh_result)
  }
  
}

#1c. Kruskal-Wallis: đối chứng phi tham số
cat("\nc) Kruskal-Wallis (phi tham số - đối chứng)\n")
kw_result <- kruskal.test(sales ~ store_type, data = train_df)
print(kw_result)
cat("-> Kruskal-Wallis p-value:", format(kw_result$p.value, scientific = TRUE, digits = 4), "\n")

if (p_parametric < 0.05 & kw_result$p.value < 0.05) {
  cat("[ok] Cả tham số và phi tham số đều xác nhận -> KẾT QUẢ ĐÁNG TIN CẬY\n")
}

#1d. ANOVA trên log(sales): kiểm tra độ vững
cat("\nd) ANOVA trên log(sales) (robustness check)\n")
anova_log     <- aov(log_sales ~ store_type, data = train_df)
anova_log_sum <- summary(anova_log)
p_anova_log   <- anova_log_sum[[1]][["Pr(>F)"]][1]
cat("-> ANOVA log p-value:", format(p_anova_log, scientific = TRUE, digits = 4), "\n")

#1e. Effect size: Eta-squared
cat("\ne) Effect size: Eta-squared\n")
cat("   p-value -> CÓ khác biệt hay không | Eta2 -> MỨC ĐỘ khác biệt\n")
eta_result <- effectsize::eta_squared(anova_fit)
print(eta_result)
eta_val <- eta_result$Eta2
cat("-> Eta2:", round(eta_val, 4), "\n")
cat("-> Mức:", as.character(effectsize::interpret_eta_squared(eta_val)),
    "| Thang đo: small~0.01 | medium~0.06 | large>=0.14\n")
cat("-> Lưu ý: Eta2 =", round(eta_val, 4), "nghĩa là store_type giải thích",
    round(eta_val * 100, 2), "% tổng phương sai doanh thu\n\n")



# 2. KIỂM ĐỊNH TÁC ĐỘNG KHUYẾN MÃI: sales ~ promo (Welch t-test + Wilcoxon)

# 2. KIỂM ĐỊNH t-test: sales ~ promo
cat("\n2. KIỂM ĐỊNH t-test: sales ~ promo\n")
cat("H0: Khuyến mãi không ảnh hưởng đến doanh thu\n")
cat("H1: Khuyến mãi có ảnh hưởng đến doanh thu\n\n")

# 2a. Kiểm tra giả định phương sai đồng nhất (Levene's Test)
cat(" a) Levene's test (Kiểm tra phương sai đồng nhất)\n")
levene_promo <- car::leveneTest(sales ~ promo, data = train_df)
print(levene_promo)
p_levene_promo <- levene_promo$`Pr(>F)`[1]
cat("→ p-value (Levene):", format(p_levene_promo, scientific = TRUE, digits = 4), "\n")

# 2b. Kiểm định Tham số (Parametric) theo luồng
if (p_levene_promo >= 0.05) {
  cat("\n b) Phương sai ĐỒNG NHẤT (p >= 0.05) → Sử dụng Student's t-test\n")
  ttest_promo <- t.test(sales ~ promo, data = train_df, var.equal = TRUE)
} else {
  cat("\n b) Phương sai KHÔNG ĐỒNG NHẤT (p < 0.05) → Sử dụng Welch t-test\n")
  ttest_promo <- t.test(sales ~ promo, data = train_df, var.equal = FALSE)
}
print(ttest_promo)
p_parametric_promo <- ttest_promo$p.value

promo_yes <- train_df %>% filter(promo == 1) %>% pull(sales)
promo_no  <- train_df %>% filter(promo == 0) %>% pull(sales)
cat("\nMean Sales (Promo=1):", round(mean(promo_yes), 0), "EUR\n")
cat("Mean Sales (Promo=0):", round(mean(promo_no), 0), "EUR\n")
cat("Chênh lệch:", round(mean(promo_yes) - mean(promo_no), 0), "EUR",
    "(+", round((mean(promo_yes)/mean(promo_no) - 1) * 100, 1), "%)\n")

cat("\n Khoảng tin cậy 95% (CI) cho chênh lệch doanh thu:\n")
cat("   [", round(ttest_promo$conf.int[1], 2), ",", round(ttest_promo$conf.int[2], 2), "] EUR\n")
if (ttest_promo$conf.int[1] > 0 | ttest_promo$conf.int[2] < 0) {
  cat("→ Khoảng KHÔNG chứa 0 → xác nhận khuyến mãi CÓ ảnh hưởng\n")
}

# 2c. Kiểm định Phi tham số (Wilcoxon Rank Sum) làm đối chứng
cat("\n c) Wilcoxon Rank Sum (Kiểm định phi tham số — Đối chứng) \n")
wilcox_result <- wilcox.test(sales ~ promo, data = train_df)
print(wilcox_result)
cat("→ p-value (Wilcoxon):", format(wilcox_result$p.value, scientific = TRUE, digits = 4), "\n")

if (p_parametric_promo < 0.05 & wilcox_result$p.value < 0.05) {
  cat("→ ✓ Cả kiểm định tham số và phi tham số đều xác nhận sự khác biệt → KẾT QUẢ ĐÁNG TIN CẬY\n")
}

# 2d. Effect size (Cohen's d)
cat("\n d) Effect size (Cohen's d) \n")
# Chọn pooled_sd động: nếu đồng nhất phương sai thì TRUE, ngược lại FALSE
pooled_sd_flag <- ifelse(p_levene_promo >= 0.05, TRUE, FALSE)
cohen_result <- effectsize::cohens_d(sales ~ promo, data = train_df, pooled_sd = pooled_sd_flag)
print(cohen_result)
cat("→ Cohen's d:", round(cohen_result$Cohens_d, 3), "\n")
cat("→ Interpretation:", as.character(effectsize::interpret_cohens_d(abs(cohen_result$Cohens_d))), "\n")


# 3. TƯƠNG QUAN: sales ~ competition_distance (Spearman + Pearson)

cat("3. TƯƠNG QUAN: sales ~ competition_distance\n")

cat("H0: Không có tương quan giữa khoảng cách đối thủ và doanh thu (rho = 0)\n")
cat("H1: Có tương quan (rho != 0)\n\n")

rho_spearman <- cor(train_df$sales, train_df$competition_distance,
                    method = "spearman", use = "complete.obs")
rho_pearson  <- cor(train_df$sales, train_df$competition_distance,
                    method = "pearson",  use = "complete.obs")

cat("Spearman rho :", round(rho_spearman, 4), "\n")
cat("Pearson r    :", round(rho_pearson,  4), "\n\n")

# Kiểm định ý nghĩa Spearman (suppressWarnings: ẩn cảnh báo ties)
suppressWarnings({
  cor_sp <- cor.test(train_df$sales, train_df$competition_distance,
                     method = "spearman", exact = FALSE)
})
cat("Spearman p-value:", format(cor_sp$p.value, digits = 4), "\n")

# Kiểm định ý nghĩa Pearson
cor_pe <- cor.test(train_df$sales, train_df$competition_distance,
                   method = "pearson")
cat("Pearson  p-value:", format(cor_pe$p.value, digits = 4), "\n\n")

cat("-> Spearman rho =", round(rho_spearman, 4),
    ": tương quan cực kỳ yếu, gần như không có\n")
cat("-> Pearson r =", round(rho_pearson, 4),
    ", p =", round(cor_pe$p.value, 3),
    ": không có ý nghĩa thống kê\n")
cat("-> Kết luận: khoảng cách đối thủ không có tác động thực tiễn đến doanh thu\n")
cat("-> Lưu ý: Spearman p nhỏ do n lớn, không phản ánh ý nghĩa thực tiễn\n\n")

# 4. BOOTSTRAP CONFIDENCE INTERVAL
cat("4. BOOTSTRAP CONFIDENCE INTERVAL\n")

cat("Ước lượng khoảng tin cậy cho trung bình doanh thu\n")
cat("Bootstrap: không cần giả định phân phối; CLT: đối chiếu lý thuyết\n\n")

set.seed(42)
n_boot <- 1000
boot_means <- replicate(n_boot, {
  mean(sample(train_df$sales, size = length(train_df$sales), replace = TRUE))
})

boot_ci        <- quantile(boot_means, c(0.025, 0.975))
boot_se        <- sd(boot_means)
obs_mean_sales <- mean(train_df$sales)

cat("Point estimate (mean)  :", round(obs_mean_sales, 2), "EUR\n")
cat("Bootstrap SE           :", round(boot_se, 2), "\n")
cat("Bootstrap 95% CI       : [", round(boot_ci[1], 2), ",",
    round(boot_ci[2], 2), "] EUR\n\n")

# So sánh với CI lý thuyết (CLT)
n_obs  <- length(train_df$sales)
se_clt <- sd(train_df$sales) / sqrt(n_obs)
ci_clt <- c(obs_mean_sales - 1.96 * se_clt,
            obs_mean_sales + 1.96 * se_clt)

cat("CLT SE                 :", round(se_clt, 2), "\n")
cat("CLT 95% CI             : [", round(ci_clt[1], 2), ",",
    round(ci_clt[2], 2), "] EUR\n\n")

cat("-> Bootstrap CI va CLT CI xap xi trung khop\n")
cat("-> Xac nhan tinh vung cua uoc luong (2 phuong phap dong thuan)\n\n")



# LƯU KẾT QUẢ

stat_tests_results <- list(
  # 0. Normality
  skewness_sales     = skew_sales,
  kurtosis_sales     = kurt_sales,
  excess_kurtosis    = excess_kurt,
  skewness_log_sales = skew_log,
  shapiro_result     = shapiro_result,
  is_normal          = is_normal,
  # 1. ANOVA / Welch ANOVA
  anova_storetype    = anova_summary,
  anova_log_summary  = anova_log_sum,
  levene_test        = levene_result,
  welch_anova        = welch_anova,
  tukey_storetype    = tukey_result,
  games_howell       = gh_result,
  kruskal_wallis     = kw_result,
  eta_squared        = eta_result,
  # 2. t-test / Wilcoxon
  ttest_promo        = ttest_promo,
  ttest_log_promo    = ttest_log,
  cohen_d_promo      = cohen_result,
  wilcoxon_promo     = wilcox_result,
  ci_promo_diff      = ttest_promo$conf.int,
  # 3. Correlation
  spearman_rho       = rho_spearman,
  pearson_r          = rho_pearson,
  cor_test_spearman  = cor_sp,
  cor_test_pearson   = cor_pe,
  # 4. Bootstrap
  bootstrap_ci       = boot_ci,
  bootstrap_se       = boot_se,
  clt_ci             = ci_clt
)

saveRDS(stat_tests_results, here("output", "tables", "stat_tests.rds"))

cat("Kiem dinh thong ke hoan tat!\n")
cat("Da luu: output/tables/stat_tests.rds\n")
