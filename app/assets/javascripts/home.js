'use strict';

var Home = {};

Home.setPublicTweets = function (url, selector) {
  new AsyncLoader(url, selector).load();
};


Home.setSearchCount = function (url) {
  $.getJSON(url, function (res) {
    var $elem = $('.search-count-wrapper');
    $elem.find('.search-count').text(res.count);
    $elem.css({'visibility': 'visible', 'opacity': 0}).animate({opacity: 1}, 1000);
  })
};
