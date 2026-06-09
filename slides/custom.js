/* =============================================================================
   STATISTICAL THEORY PRESENTATION — INTERACTION & CHARTS (LIGHT THEME)
   File: slides/custom.js
   ============================================================================= */



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



function morphBackgroundOrb(idx) {
  let color = '#3b82f6';
  if      (idx <= 6)  color = '#3b82f6';  /* blue  */
  else if (idx <= 10) color = '#f97316';  /* coral */
  else                color = '#ef4444';  /* rose  */
  document.documentElement.style.setProperty('--orb-color', color);
}

function handleBackgroundTheme(idx) {
  if (idx === 0) {
    document.body.classList.add('cover-active');
  } else {
    document.body.classList.remove('cover-active');
  }
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
      morphBackgroundOrb(idx);
      handleBackgroundTheme(idx);
      handleSlideCharts(idx);
      if (event.currentSlide)  handleSlideEntryAnimations(event.currentSlide);
      if (event.previousSlide) handleSlideExitAnimations(event.previousSlide);
    });

    Reveal.on('ready', event => {
      const idx   = event.indexh;
      const total = Reveal.getTotalSlides();
      updateProgress(idx, total);
      updateNavPill(idx);
      morphBackgroundOrb(idx);
      handleBackgroundTheme(idx);
      handleSlideCharts(idx);
      if (event.currentSlide) handleSlideEntryAnimations(event.currentSlide);
    });

    const prev = document.getElementById('nav-prev');
    const next = document.getElementById('nav-next');
    if (prev) prev.addEventListener('click', () => Reveal.prev());
    if (next) next.addEventListener('click', () => Reveal.next());
  }



  /* Keyboard shortcuts */
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
      e.preventDefault();
      window.location.href = '../presentation.html';
    }
  });
});
