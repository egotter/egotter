class PublicTweets {
  constructor(url, selector, callback) {
    new AsyncLoader(url, selector, function (res) {
      window.twttr.widgets.load(
          document.getElementById(selector)
      );
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
      console.warn('failed', url, xhr.responseText);
    });
  }
}

window.SearchCount = SearchCount;
