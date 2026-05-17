(function () {
  function showToast(message) {
    var toast = document.getElementById('toast');
    var toastMessage = document.getElementById('toastMsg');

    if (!toast || !toastMessage) {
      return;
    }

    toastMessage.textContent = message;
    toast.classList.add('show');
    window.clearTimeout(window.PulseLocalToastTimer);
    window.PulseLocalToastTimer = window.setTimeout(function () {
      toast.classList.remove('show');
    }, 2500);
  }

  function renderRiskChart() {
    var chart = document.getElementById('riskChart');
    var data = (window.PulseLocalDashboard && window.PulseLocalDashboard.chartBars) || [];
    var colors = {
      low: '#1a7a2e',
      mid: '#415a77',
      high: '#c0392b'
    };

    if (!chart) {
      return;
    }

    chart.innerHTML = data.map(function (bar) {
      var height = Number(bar.height || 0);
      var color = colors[bar.type] || colors.mid;

      return '<div class="bar-col">' +
        '<div class="bar-rect" style="height:' + height + '%;background:' + color + ';max-height:' + height + '%"></div>' +
        '<div class="bar-day">' + bar.day + '</div>' +
        '</div>';
    }).join('');
  }

  function setupNotifications() {
    var tray = document.getElementById('notifTray');
    var button = document.getElementById('notifButton');
    var clearButton = document.getElementById('clearNotifications');
    var dot = document.getElementById('notifDot');

    if (button && tray) {
      button.addEventListener('click', function () {
        tray.classList.toggle('open');
      });
    }

    if (clearButton && tray) {
      clearButton.addEventListener('click', function () {
        tray.classList.remove('open');
        if (dot) {
          dot.style.display = 'none';
        }
        showToast('All notifications cleared');
      });
    }

    document.addEventListener('click', function (event) {
      if (!tray || !tray.classList.contains('open')) {
        return;
      }

      if (!tray.contains(event.target) && !event.target.closest('#notifButton')) {
        tray.classList.remove('open');
      }
    });
  }

  function setupToastButtons() {
    document.querySelectorAll('[data-toast]').forEach(function (button) {
      button.addEventListener('click', function () {
        if (!button.disabled) {
          showToast(button.getAttribute('data-toast') || 'Action saved');
        }
      });
    });
  }

  function setupSettingsControls() {
    var fallbackToggle = document.getElementById('fallbackToggle');
    var fallbackLabel = document.getElementById('fallbackLabel');
    var riskSlider = document.getElementById('riskSlider');
    var riskValue = document.getElementById('riskVal');
    var codSlider = document.getElementById('codSlider');
    var codValue = document.getElementById('codVal');

    if (riskSlider && riskValue) {
      riskSlider.addEventListener('input', function () {
        riskValue.textContent = Number(riskSlider.value).toFixed(2);
      });
    }

    if (codSlider && codValue) {
      codSlider.addEventListener('input', function () {
        codValue.textContent = '+' + Number(codSlider.value).toFixed(2);
      });
    }

    if (fallbackToggle && fallbackLabel) {
      fallbackToggle.addEventListener('click', function () {
        if (fallbackToggle.disabled) {
          return;
        }

        fallbackToggle.classList.toggle('on');
        var active = fallbackToggle.classList.contains('on');
        fallbackLabel.textContent = active ? 'Active (on)' : 'Ready (off)';
        fallbackLabel.style.color = active ? 'var(--tangerine)' : 'var(--prussian)';
      });
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    renderRiskChart();
    setupNotifications();
    setupToastButtons();
    setupSettingsControls();
  });
})();
