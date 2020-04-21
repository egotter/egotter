'use strict';

var Waiting = {};

window.ProgressBar = function () {
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

Waiting.AlertBox = function (signedIn, timeoutMessage) {
  if (this === undefined) {
    throw new TypeError();
  }

  this._progressBar = new ProgressBar();

  this._waitingMessage = $('#waiting-msg');
  this._finishedMessage = $('#finished-msg');
  this._errorMessage = $('#error-msg');

  this._signedIn = signedIn;
  this._errorMessage.html(timeoutMessage);
};

Waiting.AlertBox.prototype = {
  constructor: Waiting.AlertBox,
  keepOn: function () {
    this._progressBar.advance();
  },
  finished: function () {
    this._progressBar.set(95);
    this._waitingMessage.hide();
    this._finishedMessage.show();
  },
  failed: function () {
    this._progressBar.hide();
    this._waitingMessage.hide();
    this._finishedMessage.hide();
    $('.buttons').show();
    this._errorMessage.show();
  },
  setErrorMessage: function (message) {
    this._errorMessage.html(message);
  }
};

Waiting.poll = function (path, options, done, keep_on, stopped, failed) {
  var retryCount = options['retryCount'] || 0;
  var interval = options['interval'] || 3000;
  var maxRetryCount = options['maxRetryCount'] || 10;

  $.get(path, options).done(function (res) {
    if (res.created_at) {
      done(res);
    } else {
      if (retryCount < maxRetryCount - 1) {
        var options = {interval: interval, retryCount: ++retryCount, maxRetryCount: maxRetryCount};
        keep_on(res, options);
        setTimeout(function () {
          Waiting.poll(path, options, done, keep_on, stopped, failed);
        }, interval);
      } else {
        stopped(res);
      }
    }
  }).fail(function (xhr) {
    failed(xhr);
  });
};
