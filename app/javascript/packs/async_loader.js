class AsyncLoader {
  constructor(url, selector, callback) {
    this.url = url;
    this.selector = selector;
    this.callback = callback;
  }

  load() {
    this.fetch();
  }

  lazyload() {
    var self = this;

    $(this.selector)
        .lazyload()
        .one('appear', function () {
          self.appear();
        });
  }

  appear() {
    console.log('appear', this.selector);
    this.fetch();
  }

  fetch() {
    var url = this.url;
    var selector = this.selector;
    var callback = this.callback;

    $.get(url).done(function (res) {
      console.log('fetch', selector);
      if (callback) {
        callback(res);
      } else {
        $(selector).html(res.html);
      }
    }).fail(function (xhr) {
      console.warn(url, xhr.responseText);
    });
  }
}

window.AsyncLoader = AsyncLoader;
