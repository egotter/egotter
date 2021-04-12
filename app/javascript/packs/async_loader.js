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
    logger.log('appear', this.selector);
    this.fetch();
  }

  fetch() {
    var self = this;
    var url = this.url;

    if (this.retry > 3) {
      logger.warn('Retry exhausted', url);
      return;
    }

    logger.log('fetch', url);

    $.get(url).done(function (res) {
      if (res.retry) {
        self.retry++;
        logger.log('Retry', url);
        setTimeout(function () {
          self.fetch();
        }, 2000);
      } else {
        self.update(res);
      }

    }).fail(showErrorMessage);
  }

  update(res) {
    if (res.html) {
      $(this.selector).empty().html(res.html);
    }

    if (this.callback) {
      this.callback(res);
    }
  }
}

window.AsyncLoader = AsyncLoader;
