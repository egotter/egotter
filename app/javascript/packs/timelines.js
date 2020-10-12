class FeedItem {
  constructor(url, callback) {
    this.url = url;
    this.callback = callback;
    this.fetch();
  }

  fetch() {
    var url = this.url;
    var callback = this.callback;

    $.get(url).done(function (res) {
      console.log(url, res);
      callback(res);
    }).fail(function (xhr) {
      console.warn(url, xhr.responseText);
    });
  }
}

window.FeedItem = FeedItem;
