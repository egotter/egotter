class FeedItem {
  constructor(url, feedName, boxSelector, placeholderSelector) {
    $.get(url).done(function (res) {
      console.log(feedName, res);
      $(placeholderSelector).hide();
      var box = $(boxSelector);

      if (!res || !res.users || res.users.length <= 0) {
        box.find('.result-not-found').show();
      } else {
        var template = window.templates['user'];

        res.users.forEach(function (user) {
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
}

window.FeedItem = FeedItem;
