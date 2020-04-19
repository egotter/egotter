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

    var graphOption = $.extend(true, {}, window.pieChartOptions);
    graphOption.series[0].data = data.chart;

    summaryBox.show();
    summaryBox.graph(graphOption);
  });
}

function checkForUpdates (path, options, done, stopped, failed) {
  var retryCount = options['retry_count'] || 0;
  var interval = options['interval'] || 5000;
  var maxRetryCount = options['max_retry_count'] || 5;

  var request_options = {interval: interval, retry_count: retryCount, max_retry_count: maxRetryCount};

  $.get(path, request_options)
    .done(function (res) {
      console.log('checkForUpdates', res, request_options);

      if (!done(res)) {
        if (retryCount < maxRetryCount - 1) {
          setTimeout(function () {
            request_options['retry_count']++;
            checkForUpdates(path, request_options, done, stopped, failed);
          }, interval);
        } else {
          stopped(res, 'Retry exhausted');
        }
      }
    })
    .fail(function (xhr) {
      failed(xhr);
    });
}

var Timelines = {};

Timelines.checkLatestTwitterUser = checkForUpdates;

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

function loadFeedItem(url, feedName) {
  var box = $('.' + feedName + '.feed-item');
  var placeholder = $('.' + feedName + '.placeholder-wrapper');

  $.get(url).done(function (res) {
    console.log(feedName, res);
    placeholder.hide();

    if (!res || !res.users || res.users.length <= 0) {
      box.find('.result-not-found').show();
    } else {
      var template = $('#user-template').html();

      $.each(res.users, function () {
        var user = this;
        user.menu_name = feedName;
        var rendered = Mustache.render(template, user);
        box.find('.users').append(rendered);
      });
      box.find('.btn-view-more .count').text(res.count);
      box.find('.btn-view-more').show();
      box.find('.show-result').show();
    }
  }).fail(function (xhr) {
    console.warn(feedName, xhr.responseText);
  });
}

Timelines.loadFeedItemm = loadFeedItem;
