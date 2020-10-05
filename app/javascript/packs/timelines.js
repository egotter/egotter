class FeedItem {
  constructor(url, feedName, boxSelector, placeholderSelector) {
    var self = this;

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
          var rendered = $(Mustache.render(template, user));

          if (user.profile_image_url) {
            rendered.find('img').on('error', function () {
              self.drawText($(this));
              return true;
            }).attr('src', user.profile_image_url);
          } else {
            self.drawText(rendered.find('img'));
          }

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

  drawText(img) {
    var parent = img.parent();
    var style = 'font-size: x-small; width: 48px; height: 48px; overflow: hidden;';
    var div = $('<div/>', {text: img.attr('alt'), class: 'rounded shadow p-1', style: style});
    parent.append(div);
    img.remove();
  }
}

window.FeedItem = FeedItem;
