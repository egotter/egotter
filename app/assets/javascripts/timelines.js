'use strict';

var Timelines = {};

function loadFeedItem(url, feedName) {
  var box = $('.' + feedName + '.feed-item');
  var placeholder = $('.' + feedName + '.placeholder-wrapper');

  $.get(url).done(function (res) {
    console.log(feedName, res);
    placeholder.hide();

    if (!res || !res.users || res.users.length <= 0) {
      box.find('.result-not-found').show();
    } else {
      var template = window.templates['user'];

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
