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

  function setModelMetadataState(state, message) {
    var loading = document.getElementById('modelMetadataLoading');
    var error = document.getElementById('modelMetadataError');
    var empty = document.getElementById('modelMetadataEmpty');
    var content = document.getElementById('modelMetadataContent');
    var status = document.getElementById('modelMetadataStatus');

    [loading, error, empty, content].forEach(function (element) {
      if (element) {
        element.hidden = true;
      }
    });

    if (state === 'loading' && loading) {
      loading.hidden = false;
    }

    if (state === 'error' && error) {
      error.textContent = message || 'Model metadata is temporarily unavailable.';
      error.hidden = false;
    }

    if (state === 'empty' && empty) {
      empty.hidden = false;
    }

    if (state === 'ready' && content) {
      content.hidden = false;
    }

    if (status) {
      status.className = 'pill model-status ' + state;
      status.textContent = {
        loading: 'Loading',
        error: 'Unavailable',
        empty: 'No metadata',
        ready: 'Available'
      }[state] || 'Unknown';
    }
  }

  function formatDecimal(value) {
    var number = Number(value);

    if (!Number.isFinite(number)) {
      return 'Not available';
    }

    return number.toFixed(2);
  }

  function formatMetric(value) {
    var number = Number(value);

    if (!Number.isFinite(number)) {
      return 'Not available';
    }

    return number.toFixed(4).replace(/0+$/, '').replace(/\.$/, '');
  }

  function renderFeatureList(elementId, features) {
    var list = document.getElementById(elementId);

    if (!list) {
      return;
    }

    list.innerHTML = '';
    (features || []).forEach(function (feature) {
      var item = document.createElement('li');
      item.textContent = feature;
      list.appendChild(item);
    });
  }

  function renderThresholds(thresholds) {
    var grid = document.getElementById('riskThresholds');
    var config = [
      ['low', 'Low'],
      ['medium', 'Medium'],
      ['high', 'High']
    ];

    if (!grid) {
      return;
    }

    grid.innerHTML = '';
    config.forEach(function (entry) {
      var key = entry[0];
      var label = entry[1];
      var threshold = thresholds && thresholds[key] ? thresholds[key] : {};
      var card = document.createElement('div');
      var badge = document.createElement('span');
      var range = document.createElement('strong');

      card.className = 'threshold-card ' + key;
      badge.className = 'badge ' + key;
      badge.textContent = label;
      range.textContent = formatDecimal(threshold.min) + ' - ' + formatDecimal(threshold.max);
      card.appendChild(badge);
      card.appendChild(range);
      grid.appendChild(card);
    });
  }

  function renderTestMetrics(metrics) {
    var grid = document.getElementById('testMetrics');
    var config = [
      ['accuracy', 'Accuracy'],
      ['precision', 'Precision'],
      ['recall', 'Recall'],
      ['f1_score', 'F1 Score'],
      ['roc_auc', 'ROC AUC']
    ];

    if (!grid) {
      return;
    }

    grid.innerHTML = '';
    config.forEach(function (entry) {
      var key = entry[0];
      var label = entry[1];
      var card = document.createElement('div');
      var cardLabel = document.createElement('span');
      var value = document.createElement('strong');

      card.className = 'metadata-metric-card';
      cardLabel.textContent = label;
      value.textContent = formatMetric(metrics && metrics[key]);
      card.appendChild(cardLabel);
      card.appendChild(value);
      grid.appendChild(card);
    });
  }

  function renderFoldScores(scores) {
    var container = document.getElementById('cvScores');

    if (!container) {
      return;
    }

    container.innerHTML = '';
    (scores || []).forEach(function (score, index) {
      var item = document.createElement('span');
      item.className = 'fold-score';
      item.textContent = 'Fold ' + (index + 1) + ': ' + formatMetric(score);
      container.appendChild(item);
    });
  }

  function renderModelMetadata(metadata) {
    if (!metadata || !metadata.model_name) {
      setModelMetadataState('empty');
      return;
    }

    document.getElementById('modelName').textContent = metadata.model_name;
    document.getElementById('modelType').textContent = metadata.model_type || 'Not available';
    document.getElementById('targetColumn').textContent = metadata.target_column || 'Not available';
    document.getElementById('featureCount').textContent = String((metadata.features || []).length);
    renderFeatureList('numericFeatures', metadata.numeric_features || []);
    renderFeatureList('categoricalFeatures', metadata.categorical_features || []);
    renderThresholds(metadata.risk_thresholds || {});
    renderTestMetrics(metadata.test_metrics || {});

    var crossValidation = metadata.cross_validation || {};
    document.getElementById('cvMethod').textContent = crossValidation.method || 'Not available';
    document.getElementById('cvSplits').textContent = String(crossValidation.n_splits || 'Not available');
    document.getElementById('cvMean').textContent = formatMetric(crossValidation.mean_roc_auc);
    document.getElementById('cvStd').textContent = formatMetric(crossValidation.std_roc_auc);
    renderFoldScores(crossValidation.scores || []);
    setModelMetadataState('ready');
  }

  function errorMessageForStatus(status, payload) {
    if (status === 401) {
      return 'Model metadata requires an active admin session.';
    }

    if (status === 403) {
      return 'Model metadata requires Admin or Super Admin access.';
    }

    return (payload && payload.message) || 'Model metadata is temporarily unavailable.';
  }

  function fetchModelMetadata() {
    var endpoint = window.PulseLocalDashboard && window.PulseLocalDashboard.metadataEndpoint;
    var refreshButton = document.getElementById('modelMetadataRefresh');

    if (!endpoint) {
      setModelMetadataState('empty');
      return;
    }

    setModelMetadataState('loading');

    if (refreshButton) {
      refreshButton.disabled = true;
    }

    window.fetch(endpoint, {
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
      .then(function (response) {
        return response.json()
          .catch(function () {
            return {};
          })
          .then(function (payload) {
            if (!response.ok) {
              throw new Error(errorMessageForStatus(response.status, payload));
            }

            return payload.data || payload;
          });
      })
      .then(renderModelMetadata)
      .catch(function (error) {
        setModelMetadataState('error', error.message);
      })
      .finally(function () {
        if (refreshButton) {
          refreshButton.disabled = false;
        }
      });
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

  function setupModelMetadata() {
    var refreshButton = document.getElementById('modelMetadataRefresh');

    if (refreshButton) {
      refreshButton.addEventListener('click', fetchModelMetadata);
    }

    fetchModelMetadata();
  }

  document.addEventListener('DOMContentLoaded', function () {
    renderRiskChart();
    setupModelMetadata();
    setupNotifications();
    setupToastButtons();
    setupSettingsControls();
  });
})();
