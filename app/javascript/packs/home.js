class PublicTweets {
  constructor(url, id, callback) {
    new AsyncLoader(url, '#' + id, function (res) {
      // Loaded in shared/twitter
      window.twttr.ready(function () {
        window.twttr.widgets.load(document.getElementById(id));
      });
      callback(res);
    }).lazyload();
  }
}

window.PublicTweets = PublicTweets;

class SearchCount {
  constructor(url) {
    $.getJSON(url).done(function (res) {
      var $elem = $('.search-count-wrapper');
      var str = res.count.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
      $elem.find('.search-count').text(str);
      $elem.css({'visibility': 'visible', 'opacity': 0}).animate({opacity: 1}, 1000);
    }).fail(function (xhr) {
      logger.warn('failed', url, xhr.responseText);
    });
  }
}

window.SearchCount = SearchCount;
