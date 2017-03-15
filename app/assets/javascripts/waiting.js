'use strict';

function waiting(checkLogPath, resultPath, pollingLogsPath, action, scope) {
  var ProgressBar = function () {
    this.$progressBar = $('.bar');
    this.$bar = this.$progressBar.find('.progress-bar');
  };

  ProgressBar.prototype.set = function (value) {
    this.$bar.css('width', value + '%').attr('aria-valuenow', value);
    this.$bar.find('.sr-only').text(value + '% Complete');
  };

  ProgressBar.prototype.advance = function () {
    var value = parseInt(this.$bar.attr('aria-valuenow'));
    value += value > 50 ? this.random(5, 10) : this.random(10, 20);
    if (value > 90) value = 90;
    this.set(value);
  };

  ProgressBar.prototype.hide = function () {
    this.$progressBar.hide();
  };

  ProgressBar.prototype.random = function (min, max) {
    return Math.random() * (max - min) + min;
  };

  var Interval = function () {
    this.value = 2000;
    this.max = 5000;
  };

  Interval.prototype.current = function () {
    return this.value;
  };

  Interval.prototype.next = function () {
    this.value += 2000;
    if (this.value > this.max) this.value = this.max;
    return this.value;
  };

  var Retry = function () {
    this.count = 0;
    this.max = 10;
  };

  Retry.prototype.current = function () {
    return this.count;
  };

  Retry.prototype.next = function () {
    this.count += 1;
    return this.count < this.max;
  };

  var $waitingMessage = $('.waiting-msg');
  var progressBar = new ProgressBar();
  var interval = new Interval();
  var retry = new Retry();
  var pollingStart = performance.now();

  function failed(xhr) {
    console.log('Server failed.');
    $.post(pollingLogsPath, {_action: action, status: false, time: performance.now() - pollingStart, retry_count: retry.current()});
    if (xhr.status === 502) {
      Rollbar.scope(scope).warning("Timeout while attempting fetching.");
    }
    console.log(xhr.responseText);

    var res = $.parseJSON(xhr.responseText || null);
    progressBar.hide();
    $waitingMessage.hide();

    if (res && egotter.errors[res.reason]) {
      egotter.errors[res.reason].showMessage();
    } else {
      egotter.errors['SomethingError'].showMessage();
    }
  }

  function done(res, text_status, xhr) {
    console.log(res, text_status, xhr.status, interval.current(), retry.current());

    if (xhr.status === 200) {
      $.post(pollingLogsPath, {_action: action, status: true, time: performance.now() - pollingStart, retry_count: retry.current()});
      progressBar.set(95);
      $waitingMessage.hide();
      $('.finished-msg').show();
      window.location.replace(resultPath);
      return;
    }

    if (!retry.next()) {
      console.log('Stop waiting.');
      $.post(pollingLogsPath, {_action: action, status: false, time: performance.now() - pollingStart, retry_count: retry.current()});
      progressBar.hide();
      $waitingMessage.hide();
      egotter.errors['Timeout'].showMessage();
      // Rollbar.scope(scope).warning("Retries exhausted while attempting fetching.");
      return;
    }

    progressBar.advance();
    setTimeout(tic, interval.next());
  }

  function tic() {
    $.get(checkLogPath).done(done).fail(failed);
  }

  tic();
}

function relationshipsWaiting(checkLogPath, resultPath, pollingLogsPath, scope) {
  waiting(checkLogPath, resultPath, pollingLogsPath, 'relationships/waiting', scope)
}

function searchesWaiting(checkLogPath, resultPath, pollingLogsPath, scope) {
  waiting(checkLogPath, resultPath, pollingLogsPath, 'searches/waiting', scope)
}
