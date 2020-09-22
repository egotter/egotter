class ProfileLoader {
  constructor(url, selector, errorMessage) {
    this.url = url;
    this.selector = selector;
    this.errorMessage = errorMessage;
    this.retryCount = 3;
    this.load();
  }

  load() {
    var url = this.url;
    var errorMessage = this.errorMessage;
    var container = $(this.selector);
    var self = this;

    $.getJSON(url).done(function (res) {
      console.log('profile', 'loaded');
      container.empty().html(res.html);
    }).fail(function (xhr) {
      console.warn('profile', self.retryCount, xhr.responseText);
      if (xhr.status === 404 && (self.retryCount--) > 0) {
        setTimeout(function () {
          self.load();
        }, 2000);
      } else {
        container.empty().html(errorMessage);
      }
    });
  }
}

window.ProfileLoader = ProfileLoader;
