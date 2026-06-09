/* =============================================================================
   STATISTICAL THEORY PRESENTATION — INTERACTION & CHARTS (LIGHT THEME)
   File: slides/custom.js
   ============================================================================= */

const speakerNotes = [
  "Xin chào thầy/cô và các bạn. Hôm nay nhóm chúng em trình bày phần cơ sở lý thuyết thống kê được vận dụng trong đồ án phân tích dữ liệu Rossmann, bao gồm ba mảng chính: thống kê mô tả, thống kê suy diễn và hồi quy Logistic. Đây là nền tảng toán học đứng sau toàn bộ các phân tích mà nhóm đã thực hiện.",
  "Thống kê được chia thành hai nhánh lớn. Thống kê mô tả giúp ta tóm tắt và hiểu dữ liệu đang có — doanh số trung bình là bao nhiêu, biến động ra sao. Thống kê suy diễn đi xa hơn: cho phép ta rút ra kết luận vượt ra ngoài mẫu quan sát — chẳng hạn, liệu khuyến mãi có thực sự làm tăng doanh số, hay chỉ là dao động ngẫu nhiên?",
  "Trung bình cộng là đại lượng quen thuộc nhất: cộng tất cả giá trị rồi chia cho số quan sát. Trong đồ án, doanh số trung bình xấp xỉ 6.840 EUR mỗi ngày. Tuy nhiên, mean có nhược điểm: chỉ cần vài ngày Giáng sinh với doanh số đột biến là đủ kéo mean lên cao hơn giá trị điển hình thực sự.",
  "Trung vị là giá trị nằm ở vị trí chính giữa khi sắp xếp dữ liệu từ nhỏ đến lớn. Median doanh số là 6.450 EUR — thấp hơn mean 390 EUR. Khoảng cách này là dấu hiệu của phân phối lệch phải. Đây cũng là lý do nhóm chọn median khi điền giá trị khuyết cho biến competition_distance.",
  "Phương sai đo mức độ phân tán bằng cách tính trung bình bình phương khoảng cách từ mỗi điểm đến giá trị trung bình. Khi tính phương sai mẫu, ta chia cho n-1 — đây là hiệu chỉnh Bessel, giúp ước lượng không bị chệch. Tuy nhiên, phương sai có đơn vị EUR² nên rất khó diễn giải.",
  "Độ lệch chuẩn đơn giản là căn bậc hai của phương sai. Ưu điểm: nó cùng đơn vị với dữ liệu gốc, nên ta có thể nói 'doanh số dao động ±2.632 EUR quanh mức trung bình.' Hệ số biến thiên CV khoảng 38%, cho thấy doanh số biến động khá mạnh giữa các cửa hàng và ngày trong tuần.",
  "Slide này tổng hợp bốn đại lượng mô tả chính. Bài học thực tiễn: trong bất kỳ báo cáo nào, ta nên trình bày đồng thời cả mean, median và SD. Nếu mean và median chênh nhau nhiều, đó là tín hiệu cần kiểm tra kỹ phân phối và xử lý outlier trước khi mô hình hóa.",
  "Bây giờ chúng ta chuyển sang thống kê suy diễn. Ta chỉ quan sát được 50 cửa hàng trong 12 tháng, nhưng muốn rút ra kết luận cho toàn bộ hơn 3.000 cửa hàng của Rossmann. Kiểm định giả thuyết sẽ giúp ta trả lời câu hỏi này một cách có căn cứ thống kê.",
  "Kiểm định giả thuyết tuân theo quy trình năm bước nhất quán. Điểm quan trọng nhất: p-value là xác suất quan sát được kết quả cực đoan như hiện tại, giả thiết H0 đúng. Nếu p < 0,05, ta bác bỏ H0. Lưu ý: 'không bác bỏ H0' không có nghĩa là H0 đúng.",
  "Điểm đặc trưng trong đồ án là mỗi giả thuyết đều được kiểm tra song song bằng cả phương pháp tham số lẫn phi tham số. Lý do: biến Sales có skewness ≈ 0,94 — vi phạm giả định phân phối chuẩn. Nếu cả hai nhóm phương pháp đều bác bỏ H0, kết luận có độ vững rất cao.",
  "Hồi quy tuyến tính giả định biến mục tiêu là tổ hợp tuyến tính của các biến đầu vào. Phương pháp OLS tìm bộ hệ số beta sao cho tổng bình phương sai số là nhỏ nhất. Trong đồ án, mô hình đạt R² khoảng 0,87 — 87% sự biến động của doanh số được giải thích bởi các biến đầu vào.",
  "Khi biến phụ thuộc là nhị phân — 'doanh số có vượt ngưỡng median không?' — hồi quy tuyến tính không phù hợp. Nếu cố ép dùng, mô hình có thể dự đoán ra xác suất âm hoặc lớn hơn 1, điều này hoàn toàn vô nghĩa về mặt xác suất.",
  "Hàm sigmoid nhận đầu vào là tổ hợp tuyến tính z và biến đổi nó thành xác suất trong khoảng 0 đến 1. Hàm logit là chiều ngược lại: chuyển xác suất thành log-odds. Trên thang log-odds, mối quan hệ với X trở thành tuyến tính.",
  "Hồi quy Logistic dùng MLE — tìm bộ hệ số beta sao cho xác suất sinh ra đúng tập dữ liệu quan sát được là lớn nhất. Để diễn giải kết quả, ta tính Odds Ratio bằng e mũ beta. Ví dụ: OR = 2.0 nghĩa là có khuyến mãi tăng gấp đôi tỷ lệ cược đạt doanh số cao.",
  "Slide cuối tổng hợp toàn bộ hành trình lý thuyết. Từ bốn đại lượng mô tả cơ bản, đến kiểm định giả thuyết, đến hồi quy Logistic. Điểm thú vị: Linear và Logistic Regression đều là GLM — chúng chỉ khác nhau ở hàm liên kết. Nhóm xin chân thành cảm ơn thầy/cô và các bạn!"
];

const activeCharts = {};

/* =============================================================================
   1. CHART.JS GLOBAL DEFAULTS — LIGHT THEME
   ============================================================================= */

function setChartDefaults() {
  if (typeof Chart === 'undefined') return;

  Chart.defaults.font.family   = "'JetBrains Mono', monospace";
  Chart.defaults.font.size     = 11;
  Chart.defaults.color         = '#3f3f46';          /* text-secondary on white */
  Chart.defaults.borderColor   = 'rgba(0,0,0,0.06)';

  /* Light glass tooltip */
  Chart.defaults.plugins.tooltip.backgroundColor = 'rgba(255,255,255,0.96)';
  Chart.defaults.plugins.tooltip.borderColor     = 'rgba(0,0,0,0.10)';
  Chart.defaults.plugins.tooltip.borderWidth     = 1;
  Chart.defaults.plugins.tooltip.padding         = 10;
  Chart.defaults.plugins.tooltip.cornerRadius    = 8;
  Chart.defaults.plugins.tooltip.titleColor      = '#18181b';
  Chart.defaults.plugins.tooltip.bodyColor       = '#3f3f46';
  Chart.defaults.plugins.tooltip.titleFont       = { weight: 'bold' };
  Chart.defaults.plugins.tooltip.boxShadow       = '0 4px 16px rgba(0,0,0,0.12)';
}

/* =============================================================================
   2. CHART INITIALIZERS
   ============================================================================= */

/* Slide 4 — Skewed sales distribution histogram */
function initSalesDistChart() {
  const ctx = document.getElementById('salesDistChart');
  if (!ctx || activeCharts['salesDistChart']) return;

  activeCharts['salesDistChart'] = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['1k','3k','5k','7k','9k','11k','13k','15k','17k','19k+'],
      datasets: [{
        label: 'Tần suất',
        data: [120, 940, 2850, 4950, 3100, 1420, 540, 210, 60, 26],
        backgroundColor: 'rgba(15,118,110,0.18)',
        borderColor:     '#0f766e',
        borderWidth: 1.5,
        borderRadius: 4,
        barPercentage: 0.85,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 900, easing: 'easeOutQuart' },
      plugins: { legend: { display: false } },
      scales: {
        y: {
          grid:  { color: 'rgba(0,0,0,0.04)' },
          ticks: { color: '#a1a1aa' }
        },
        x: {
          grid:  { display: false },
          ticks: { color: '#a1a1aa' }
        }
      }
    }
  });
}

/* Slide 10 — Promo vs no-promo comparison */
function initPromoCompareChart() {
  const ctx = document.getElementById('promoCompareChart');
  if (!ctx || activeCharts['promoCompareChart']) return;

  activeCharts['promoCompareChart'] = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['Không KM (Promo=0)', 'Có KM (Promo=1)'],
      datasets: [{
        label: 'Doanh số TB (EUR/ngày)',
        data: [5739, 8091],
        backgroundColor: ['rgba(161,161,170,0.25)', 'rgba(180,83,9,0.22)'],
        borderColor:     ['#a1a1aa', '#b45309'],
        borderWidth: 1.5,
        borderRadius: 8,
        barThickness: 52,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 1000, easing: 'easeOutQuart' },
      plugins: { legend: { display: false } },
      scales: {
        y: {
          min: 0, max: 10000,
          grid:  { color: 'rgba(0,0,0,0.04)' },
          ticks: { color: '#a1a1aa' }
        },
        x: {
          grid:  { display: false },
          ticks: { color: '#3f3f46', font: { size: 10 } }
        }
      }
    }
  });
}

/* Slide 13 — Sigmoid curve */
function initSigmoidChart() {
  const ctx = document.getElementById('sigmoidChart');
  if (!ctx || activeCharts['sigmoidChart']) return;

  const zVals = [], pVals = [];
  for (let z = -6; z <= 6; z += 0.15) {
    zVals.push(z.toFixed(2));
    pVals.push(+(1 / (1 + Math.exp(-z))).toFixed(4));
  }

  activeCharts['sigmoidChart'] = new Chart(ctx, {
    type: 'line',
    data: {
      labels: zVals,
      datasets: [{
        label: 'P(Y=1|z)',
        data: pVals,
        borderColor:     '#be123c',
        backgroundColor: 'rgba(190,18,60,0.07)',
        fill: true,
        tension: 0.35,
        pointRadius: 0,
        pointHitRadius: 12,
        borderWidth: 2.5,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 1400, easing: 'easeOutCubic' },
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            title: ctx => `z = ${ctx[0].label}`,
            label: ctx => `P(Y=1) = ${ctx.parsed.y.toFixed(4)}`
          }
        }
      },
      scales: {
        y: {
          min: 0, max: 1,
          grid:  { color: 'rgba(0,0,0,0.04)' },
          ticks: { color: '#a1a1aa', stepSize: 0.2 }
        },
        x: {
          grid:  { color: 'rgba(0,0,0,0.03)' },
          ticks: {
            color: '#a1a1aa',
            callback: (val, i) => {
              const v = parseFloat(zVals[i]);
              return Number.isInteger(v) && v % 2 === 0 ? v : '';
            }
          }
        }
      }
    }
  });
}

/* Slide 15 — Horizontal model comparison */
function initModelCompareChart() {
  const ctx = document.getElementById('modelCompareChart');
  if (!ctx || activeCharts['modelCompareChart']) return;

  activeCharts['modelCompareChart'] = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['XGBoost','Random Forest','Linear Reg.','ARIMA','ETS'],
      datasets: [{
        label: 'R² Score',
        data: [0.9779, 0.9424, 0.8678, 0.312, 0.287],
        backgroundColor: [
          'rgba(15,118,110,0.55)',
          'rgba(15,118,110,0.38)',
          'rgba(15,118,110,0.22)',
          'rgba(0,0,0,0.07)',
          'rgba(0,0,0,0.05)',
        ],
        borderColor: [
          '#0f766e',
          'rgba(15,118,110,0.6)',
          'rgba(15,118,110,0.4)',
          'rgba(0,0,0,0.15)',
          'rgba(0,0,0,0.10)',
        ],
        borderWidth: 1.2,
        borderRadius: 6,
        barThickness: 22,
      }]
    },
    options: {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 1200, easing: 'easeOutQuart' },
      plugins: { legend: { display: false } },
      scales: {
        x: {
          min: 0, max: 1.0,
          grid:  { color: 'rgba(0,0,0,0.04)' },
          ticks: { color: '#a1a1aa', stepSize: 0.2 }
        },
        y: {
          grid:  { display: false },
          ticks: { color: '#3f3f46', font: { size: 11 } }
        }
      }
    }
  });
}

function handleSlideCharts(index) {
  if      (index === 3)  setTimeout(initSalesDistChart,     380);
  else if (index === 9)  setTimeout(initPromoCompareChart,  380);
  else if (index === 12) setTimeout(initSigmoidChart,       380);
  else if (index === 14) setTimeout(initModelCompareChart,  380);
}

/* =============================================================================
   3. SLIDE TRANSITION HANDLERS
   ============================================================================= */

function updateProgress(idx, total) {
  const fill = document.getElementById('viewport-progress-fill');
  if (fill) fill.style.width = `${total > 1 ? (idx / (total - 1)) * 100 : 0}%`;
}

function updateNavPill(idx) {
  const el = document.getElementById('nav-current-num');
  if (el) el.textContent = String(idx + 1).padStart(2, '0');
}

function updateSpeakerNotesContent(idx) {
  const body = document.getElementById('speaker-notes-body');
  if (body && speakerNotes[idx] !== undefined) body.innerHTML = speakerNotes[idx];
}

function morphBackgroundOrb(idx) {
  let color = '#0d9488';
  if      (idx <= 6)  color = '#0d9488';  /* teal  */
  else if (idx <= 10) color = '#b45309';  /* amber */
  else                color = '#be123c';  /* rose  */
  document.documentElement.style.setProperty('--orb-color', color);
}

function toggleSpeakerNotes() {
  const panel = document.getElementById('speaker-notes-panel');
  if (panel) panel.classList.toggle('expanded');
}

function handleSlideEntryAnimations(slideEl) {
  /* Animate progress bars */
  slideEl.querySelectorAll('.progress-fill').forEach(fill => {
    const val = parseFloat(fill.dataset.value || 0);
    const max = parseFloat(fill.dataset.max   || 1);
    fill.style.width = `${(val / max) * 100}%`;
  });

  /* Cascade step rows */
  slideEl.querySelectorAll('.step-row').forEach((row, i) => {
    setTimeout(() => row.classList.add('active'), i * 180 + 350);
  });

  /* Stagger children */
  slideEl.querySelectorAll('.stagger-children').forEach(el => {
    el.classList.add('is-visible-stagger');
  });
}

function handleSlideExitAnimations(slideEl) {
  slideEl.querySelectorAll('.progress-fill').forEach(f => { f.style.width = '0%'; });
  slideEl.querySelectorAll('.step-row').forEach(r => r.classList.remove('active'));
  slideEl.querySelectorAll('.stagger-children').forEach(el => {
    el.classList.remove('is-visible-stagger');
  });
}

/* =============================================================================
   4. BOOT
   ============================================================================= */

document.addEventListener('DOMContentLoaded', () => {
  setChartDefaults();

  if (typeof Reveal !== 'undefined') {
    Reveal.on('slidechanged', event => {
      const idx   = event.indexh;
      const total = Reveal.getTotalSlides();
      updateProgress(idx, total);
      updateNavPill(idx);
      updateSpeakerNotesContent(idx);
      morphBackgroundOrb(idx);
      handleSlideCharts(idx);
      if (event.currentSlide)  handleSlideEntryAnimations(event.currentSlide);
      if (event.previousSlide) handleSlideExitAnimations(event.previousSlide);
    });

    Reveal.on('ready', event => {
      const idx   = event.indexh;
      const total = Reveal.getTotalSlides();
      updateProgress(idx, total);
      updateNavPill(idx);
      updateSpeakerNotesContent(idx);
      morphBackgroundOrb(idx);
      handleSlideCharts(idx);
      if (event.currentSlide) handleSlideEntryAnimations(event.currentSlide);
    });

    const prev = document.getElementById('nav-prev');
    const next = document.getElementById('nav-next');
    if (prev) prev.addEventListener('click', () => Reveal.prev());
    if (next) next.addEventListener('click', () => Reveal.next());
  }

  /* Speaker notes toggle */
  ['speaker-notes-header', 'notes-trigger-btn'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('click', toggleSpeakerNotes);
  });

  /* Keyboard shortcuts */
  document.addEventListener('keydown', e => {
    if (e.key.toLowerCase() === 's') {
      e.preventDefault();
      toggleSpeakerNotes();
    }
  });
});
