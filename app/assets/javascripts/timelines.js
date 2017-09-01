'use strict';

function loadSummary (apiEndpoint, summaryBox, progressMessages) {
  $.getJSON(apiEndpoint, function(data) {
    console.log(data);

    if (!data || !data.users || data.users.length <= 0) {
      summaryBox.link(false);
      summaryBox.messageBox().html(progressMessages.empty).show();
      summaryBox.reloadBtn().show();
      summaryBox.show();
      return;
    }

    var template = $('#user-template').html();

    $.each(data.users, function () {
      var user = this;
      user.menu_name = summaryBox.menuName;
      var rendered = Mustache.render(template, user);
      summaryBox.appendUser(rendered);
    });
    summaryBox.viewMoreBtn(data.count).show();

    var graphOption = $.extend(true, {}, window.common_pie_chart_options);
    graphOption.series[0].data = data.chart;

    summaryBox.show();
    summaryBox.graph(graphOption);
  });
}

function checkForUpdates (path, options, successCallback, stopCallback, failedCallback) {
  var retryCount = options['retryCount'] || 0;
  var interval = options['interval'] || 5000;
  var startedAt = options['startedAt'] || Date.now() / 1000;

  $.get(path, {interval: interval, retry_count: retryCount, started_at: startedAt})
    .done(function (res, textStatus, xhr) {
      console.log('checkForUpdates', res);

      if (xhr.status === 200) {
        successCallback(res);
      } else {
        if (retryCount < 2) {
          setTimeout(function () {
            var options = {interval: interval, retryCount: ++retryCount, startedAt: startedAt};
            checkForUpdates(path, options, successCallback, stopCallback, failedCallback);
          }, interval);
        } else {
          stopCallback(res);
        }
      }
    })
    .fail(function (xhr) {
      failedCallback(xhr);
    });
}

window.SummaryBox = function (menuName) {
  this.menuName = menuName;
  this.$summaryBox = $('.menu-items.' + menuName);
};

SummaryBox.prototype.show = function () {
  $("div[data-replaced-by='" + this.menuName + "']").remove();
  this.$summaryBox.show();
};

SummaryBox.prototype.messageBox = function () {
  return this.$summaryBox.find('.progress-msg');
};

SummaryBox.prototype.reloadBtn = function () {
  return this.$summaryBox.find('.reload-btn');
};

SummaryBox.prototype.viewMoreBtn = function (count) {
  return this.$summaryBox.find('.btn-view-more').find('span').text(count).end();
};

SummaryBox.prototype.signInBtn = function () {
  return this.$summaryBox.find('.sign-in-btn');
};

SummaryBox.prototype.link = function (enable) {
  if (!enable) {
    this.$summaryBox.find('.result-link').attr('href', '#').attr('onclick', 'return false;');
  }
};

SummaryBox.prototype.graph = function (options) {
  return this.$summaryBox.find('.media-right').show().end().find('.common-chart').highcharts(options);
};

SummaryBox.prototype.appendUser = function (user) {
  this.$summaryBox.find('.media-body').append(user);
};

SummaryBox.prototype.lazyload = function (callback) {
  var menuName = this.menuName;
  $('.placeholder-wrapper.' + this.menuName)
    .lazyload()
    .one('appear', function () {
      console.log('appear', menuName);
      callback();
    });
};

window.Adsense = function (url, selector) {
  this.url = url;
  this.selector = selector;
};

Adsense.prototype.lazyload = function () {
  var url = this.url;
  var selector = this.selector;
  var $wrapper = $(this.selector);
  $wrapper
    .lazyload()
    .one('appear', function () {
      console.log('appear', selector);
      $.getJSON(url, function (data) { $wrapper.html(data.html); });
    });
};

window.PublicTweets = function (url, selector) {
  this.url = url;
  this.selector = selector;
};

PublicTweets.prototype.load = function () {
  var url = this.url;
  var $wrapper = $(this.selector);
  $.getJSON(url, function (data) { $wrapper.html(data.html); });
};