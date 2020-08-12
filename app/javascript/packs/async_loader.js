class AsyncLoader {
  constructor(url, selector) {
    this.url = url;
    this.selector = selector;
  }

  load() {
    var selector = this.selector;
    var url = this.url;

    $.get(url).done(function (data) {
      $(selector).html(data.html);
    }).fail(function (xhr) {
      console.warn(url, xhr.responseText);
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

          $.get(url).done(function (data) {
            $wrapper.html(data.html);
          }).fail(function (xhr) {
            console.warn(url, xhr.responseText);
          });
        });
  }
}

window.AsyncLoader = AsyncLoader;
