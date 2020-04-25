class AsyncLoader {
  constructor(url, selector) {
    this.url = url;
    this.selector = selector;
  }

  load() {
    var selector = this.selector;
    $.getJSON(this.url, function (data) {
      $(selector).html(data.html);
    });
  }

  lazyload() {
    var url = this.url;
    var selector = this.selector;
    var $wrapper = $(this.selector);
    $wrapper
        .lazyload()
        .one('appear', function () {
          console.log('appear', selector);
          $.getJSON(url, function (data) {
            $wrapper.html(data.html);
          });
        });
  }
}

window.AsyncLoader = AsyncLoader;
