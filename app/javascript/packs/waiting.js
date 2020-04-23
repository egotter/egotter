'use strict';

class Waiting {
  constructor(path, options, done, keepOn, stopped, failed) {
    this.path = path;
    this.options = options;
    this.retryCount = options['retryCount'] || 0;
    this.interval = options['interval'] || 3000;
    this.maxRetryCount = options['maxRetryCount'] || 10;
    this.done = done;
    this.keepOn = keepOn;
    this.stopped = stopped;
    this.failed = failed;
  }

  start() {
    var self = this;
    $.get(this.path, this.options).done(function (res) {
      if (res.created_at) {
        self.done(res);
      } else {
        if (self.retryCount < self.maxRetryCount - 1) {
          var options = self.nextOptions();
          self.keepOn(res, options);

          setTimeout(function () {
            new Waiting(self.path, options, self.done, self.keepOn, self.stopped, self.failed).start();
          }, self.interval);
        } else {
          self.stopped(res);
        }
      }
    }).fail(function (xhr) {
      self.failed(xhr);
    });
  }

  nextOptions() {
    return {interval: this.interval, retryCount: this.retryCount + 1, maxRetryCount: this.maxRetryCount};
  }
}

window.Waiting = Waiting;

class ProgressBar {
  constructor() {
    this.$bar = $('.progress-bar');
  }

  set(value) {
    this.$bar.css('width', value + '%').attr('aria-valuenow', value);
  }

  advance() {
    var value = parseInt(this.$bar.attr('aria-valuenow'));
    value += value > 50 ? this.random(5, 10) : this.random(10, 20);
    if (value > 90) value = 90;
    this.set(value);
  }

  hide() {
    this.$bar.parents('.progress').hide();
  }

  random(min, max) {
    return Math.random() * (max - min) + min;
  }
}

class AlertBox {
  constructor() {
    this.bar = new ProgressBar();

    this.waitingMessage = $('#waiting-msg');
    this.finishedMessage = $('#finished-msg');
    this.errorMessage = $('#error-msg');
  }

  keepOn() {
    this.bar.advance();
  }

  finished() {
    this.bar.set(95);
    this.waitingMessage.hide();
    this.finishedMessage.show();
  }

  failed() {
    this.bar.hide();
    this.waitingMessage.hide();
    this.finishedMessage.hide();
    $('.buttons').show();
    this.errorMessage.show();
  }

  setErrorMessage(message) {
    this.errorMessage.html(message);
  }
}

window.AlertBox = AlertBox;
