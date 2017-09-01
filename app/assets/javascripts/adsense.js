window.Adsense = function (url, selector) {
  this.url = url;
  this.selector = selector;
};

Adsense.prototype.lazyload = function () {
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