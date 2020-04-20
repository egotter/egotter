'use strict';

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
