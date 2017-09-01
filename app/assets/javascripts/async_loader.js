window.AsyncLoader = function (url, selector) {
  this.url = url;
  this.selector = selector;
};

AsyncLoader.prototype.load = function () {
  var url = this.url;
  var $wrapper = $(this.selector);
  $.getJSON(url, function (data) { $wrapper.html(data.html); });
};

AsyncLoader.prototype.lazyload = function () {
  var url = this.url;
  var selector = this.selector;
  var $wrapper = $(this.selector);
  $wrapper
      .lazyload()
      .one('appear', function () {
        console.log('appear', selector);
        $.getJSON(url, function (data) { $wrapper.html(data.html); });
      });
};