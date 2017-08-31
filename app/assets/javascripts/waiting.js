'use strict';

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