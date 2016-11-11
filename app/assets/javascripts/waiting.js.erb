'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function waiting(checkLogPath, resultPath, scope) {
  var ProgressBar = function () {
    function ProgressBar() {
      _classCallCheck(this, ProgressBar);

      this.$progressBar = $('.bar');
      this.$bar = this.$progressBar.find('.progress-bar');
    }

    _createClass(ProgressBar, [{
      key: 'set',
      value: function set(value) {
        this.$bar.css('width', value + '%').attr('aria-valuenow', value);
        this.$bar.find('.sr-only').text(value + '% Complete');
      }
    }, {
      key: 'advance',
      value: function advance() {
        var value = parseInt(this.$bar.attr('aria-valuenow'));
        value += value > 50 ? this.random(5, 10) : this.random(10, 20);
        if (value > 90) value = 90;
        this.set(value);
      }
    }, {
      key: 'hide',
      value: function hide() {
        this.$progressBar.hide();
      }
    }, {
      key: 'random',
      value: function random(min, max) {
        return Math.random() * (max - min) + min;
      }
    }]);

    return ProgressBar;
  }();

  var Interval = function () {
    function Interval() {
      _classCallCheck(this, Interval);

      this.value = 2000;
      this.max = 5000;
    }

    _createClass(Interval, [{
      key: 'current',
      value: function current() {
        return this.value;
      }
    }, {
      key: 'next',
      value: function next() {
        this.value += 2000;
        if (this.value > this.max) this.value = this.max;
        return this.value;
      }
    }]);

    return Interval;
  }();

  var Retry = function () {
    function Retry() {
      _classCallCheck(this, Retry);

      this.count = 0;
      this.max = 10;
    }

    _createClass(Retry, [{
      key: 'current',
      value: function current() {
        return this.count;
      }
    }, {
      key: 'next',
      value: function next() {
        this.count += 1;
        return this.count < this.max;
      }
    }]);

    return Retry;
  }();

  var $waitingMessage = $('.waiting-msg');
  var progressBar = new ProgressBar();
  var interval = new Interval();
  var retry = new Retry();

  function failed(xhr) {
    if (xhr.status === 502) {
      Rollbar.scope(scope).warning("Timeout while attempting fetching.");
      return;
    }
    console.log(xhr.responseText);

    var res = $.parseJSON(xhr.responseText || null);
    progressBar.hide();
    $waitingMessage.hide();

    if (res && egotter.errors[res.reason]) {
      egotter.errors[res.reason].showMessage();
    } else {
      egotter.errors['SomethingIsWrong'].showMessage();
    }
  }

  function done(res, text_status, xhr) {
    console.log(res, text_status, xhr.status, interval.current(), retry.current());

    if (xhr.status === 200) {
      progressBar.set(95);
      $waitingMessage.hide();
      $('.finished-msg').show();
      window.location.replace(resultPath);
      return;
    }

    if (!retry.next()) {
      progressBar.hide();
      $waitingMessage.hide();
      egotter.errors['Timeout'].showMessage();
      Rollbar.scope(scope).warning("Retries exhausted while attempting fetching.");
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