'use strict';

var Home = {};

Home.setPublicTweets = function (url, selector) {
  new AsyncLoader(url, selector).load();
};


Home.setSearchCount = function (url) {
  $.getJSON(url, function (res) {
    var $elem = $('.search-count-wrapper');
    var str = res.count.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    $elem.find('.search-count').text(str);
    $elem.css({'visibility': 'visible', 'opacity': 0}).animate({opacity: 1}, 1000);
  })
};
