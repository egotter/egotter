class PublicTweets {
  constructor(url, selector) {
    new AsyncLoader(url, selector).load();
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
