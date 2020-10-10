class AsyncLoader {
  constructor(url, selector, callback) {
    this.url = url;
    this.selector = selector;
    this.callback = callback;
    this.retry = 0;
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
    var self = this;
    var url = this.url;

    if (this.retry > 3) {
      console.warn('Retry exhausted', url);
      return;
    }

    console.log('fetch', url);

    $.get(url).done(function (res) {
      if (res.retry) {
        self.retry++;
        console.log('Retry', url);
        setTimeout(function () {
          self.fetch();
        }, 2000);
      } else {
        self.update(res);
      }

    }).fail(function (xhr) {
      console.warn(url, xhr.responseText);
    });
  }

  update(res) {
    if (res.html) {
      $(this.selector).html(res.html);
    }

    if (this.callback) {
      this.callback(res);
    }
  }
}

window.AsyncLoader = AsyncLoader;
